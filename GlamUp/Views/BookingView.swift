//Kashfi - Booking page template file, updated UI, updated services and timing to reflect firestore

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BookingAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    let proName: String
    let proUserID: String
    let isBeautyPro: Bool
    var dismissToRoot: (() -> Void)? = nil

    @State private var services: [String] = []
    @State private var selectedService = ""

    @State private var selectedDate = Date()
    @State private var selectedTime: String? = nil

    @State private var showConfirmation = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var availability: [String: DayAvailability] = [:]
    @State private var loadingAvailability = false
    @State private var showCalendar = false

    @State private var currentMonth = Date()

    private let days = [
        "Sunday","Monday","Tuesday","Wednesday",
        "Thursday","Friday","Saturday"
    ]

    // MARK: Slots
    private var dynamicSlots: [String] {
        let weekday = weekdayName(from: selectedDate)

        guard let day = availability[weekday], day.isOn else { return [] }

        var hours = Array(day.startHour..<day.endHour)

        if Calendar.current.isDateInToday(selectedDate) {
            let now = Calendar.current.component(.hour, from: Date())
            hours = hours.filter { $0 > now }
        }

        return hours.map { String(format: "%02d:00", $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                HStack {
                    BackPillButton { dismiss() }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Book an Appointment")
                        .font(.title2.bold())
                        .foregroundStyle(.pink)

                    Text("With \(proName)")
                        .foregroundStyle(.secondary)
                }

                // MARK: Services
                sectionTitle("Select Service")

                if services.isEmpty {
                    card {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Picker("Service", selection: $selectedService) {
                        ForEach(services, id: \.self) { service in
                            Text(service).tag(service)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // MARK: Date
                sectionTitle("Select Date")

                Button {
                    showCalendar.toggle()
                } label: {
                    HStack {
                        Text(formattedDate(selectedDate))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "calendar")
                            .foregroundStyle(.pink)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if showCalendar {
                    customCalendar
                }

                // MARK: Time
                sectionTitle("Select Time")

                if loadingAvailability {
                    card { ProgressView() }

                } else if dynamicSlots.isEmpty {
                    card {
                        Text("No available slots.")
                            .foregroundStyle(.secondary)
                    }

                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 95), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(dynamicSlots, id: \.self) { slot in
                            Button {
                                selectedTime = slot
                            } label: {
                                Text(slot)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(
                                        selectedTime == slot
                                        ? .white : .primary
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(
                                                selectedTime == slot
                                                ? Color.pink : .white
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                Color.pink.opacity(
                                                    selectedTime == slot ? 0 : 0.18
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button {
                    saveBooking()
                } label: {
                    PrimaryButton(
                        title: isSaving ? "Saving..." : "Confirm Booking"
                    )
                }
                .disabled(
                    selectedService.isEmpty ||
                    selectedTime == nil ||
                    isSaving
                )
                .opacity(
                    (selectedService.isEmpty ||
                     selectedTime == nil ||
                     isSaving) ? 0.6 : 1
                )

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color(red: 1, green: 0.97, blue: 0.99))
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            fetchServices()
            fetchAvailability()
        }
        .navigationDestination(isPresented: $showConfirmation) {
            BookingConfirmationView(
                service: selectedService,
                date: selectedDate,
                time: selectedTime ?? "—",
                dismissToRoot: dismissToRoot
            )
        }
    }

    // MARK: Custom Calendar

    private var customCalendar: some View {
        VStack(spacing: 12) {

            HStack {
                Button {
                    currentMonth = Calendar.current.date(
                        byAdding: .month,
                        value: -1,
                        to: currentMonth
                    )!
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.pink)
                }

                Spacer()

                Text(monthTitle(currentMonth))
                    .font(.headline)

                Spacer()

                Button {
                    currentMonth = Calendar.current.date(
                        byAdding: .month,
                        value: 1,
                        to: currentMonth
                    )!
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.pink)
                }
            }

            let cols = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: cols, spacing: 10) {

                ForEach(["S","M","T","W","T","F","S"], id: \.self) {
                    Text($0)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                ForEach(daysInMonth(), id: \.self) { date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func dayCell(_ date: Date) -> some View {
        let selectable = isDateAvailable(date) && !isPast(date)
        let selected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

        return Button {
            if selectable {
                selectedDate = date
                selectedTime = nil
                showCalendar = false
            }
        } label: {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline.bold())
                .frame(width: 36, height: 36)
                .background(
                    selected ? Color.pink :
                    selectable ? Color.white :
                    Color.gray.opacity(0.12)
                )
                .foregroundStyle(
                    selected ? .white :
                    selectable ? .primary :
                    .gray
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
    }

    // MARK: Firestore

    private func fetchServices() {
        Firestore.firestore()
            .collection("proServices")
            .whereField("proUserID", isEqualTo: proUserID)
            .getDocuments { snapshot, _ in

                let docs = snapshot?.documents ?? []

                let loaded = docs.compactMap { doc -> String? in
                    let data = doc.data()

                    let name =
                        data["name"] as? String ??
                        data["serviceName"] as? String ??
                        "Service"

                    let priceText: String

                    if let i = data["price"] as? Int {
                        priceText = "\(i)"
                    } else if let d = data["price"] as? Double {
                        priceText = "\(Int(d))"
                    } else if let s = data["price"] as? String {
                        priceText = s
                    } else {
                        priceText = ""
                    }

                    return priceText.isEmpty
                        ? name
                        : "\(name) - $\(priceText)"
                }

                services = loaded
                selectedService = loaded.first ?? ""
            }
    }

    private func fetchAvailability() {
        loadingAvailability = true

        Firestore.firestore()
            .collection("availability")
            .document(proUserID)
            .getDocument { doc, _ in

                loadingAvailability = false

                guard let data = doc?.data() else { return }

                var loaded: [String: DayAvailability] = [:]

                for day in days {
                    if let d = data[day] as? [String: Any] {
                        loaded[day] = DayAvailability(
                            isOn: d["isOn"] as? Bool ?? false,
                            startHour: d["startHour"] as? Int ?? 9,
                            endHour: d["endHour"] as? Int ?? 17
                        )
                    }
                }

                availability = loaded
                moveToNextAvailableDate()
            }
    }

    private func saveBooking() {
        guard let clientID = Auth.auth().currentUser?.uid,
              let time = selectedTime else { return }

        isSaving = true

        Firestore.firestore()
            .collection("users")
            .document(clientID)
            .getDocument { snap, _ in

                let data = snap?.data() ?? [:]
                let full = data["fullName"] as? String ?? ""
                let clientName = full.isEmpty ? "Client" : full

                let booking: [String: Any] = [
                    "clientID": clientID,
                    "clientName": clientName,
                    "proUserID": proUserID,
                    "proName": proName,
                    "service": selectedService,
                    "date": Timestamp(date: selectedDate),
                    "time": time,
                    "status": "pending",
                    "createdAt": Timestamp(date: Date()),
                    "updatedAt": Timestamp(date: Date())
                ]

                Firestore.firestore()
                    .collection("bookings")
                    .addDocument(data: booking) { _ in
                        isSaving = false
                        showConfirmation = true
                    }
            }
    }

    // MARK: Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.pink)
    }

    private func card<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func weekdayName(from date: Date) -> String {
        let index = Calendar.current.component(.weekday, from: date) - 1
        return days[index]
    }

    private func isDateAvailable(_ date: Date) -> Bool {
        let day = weekdayName(from: date)
        return availability[day]?.isOn == true
    }

    private func isPast(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date)
        < Calendar.current.startOfDay(for: Date())
    }

    private func moveToNextAvailableDate() {
        for offset in 0..<30 {
            if let future = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: Date()
            ),
            isDateAvailable(future) {
                selectedDate = future
                return
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current

        guard let interval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: interval.start).weekday
        else { return [] }

        let daysCount = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0

        var result: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                result.append(date)
            }
        }

        return result
    }
}
