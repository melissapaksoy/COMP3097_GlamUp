import SwiftUI

struct BookingAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    let proName: String
    let proUserID: String
    let isBeautyPro: Bool

    private let services = [
        "💅 Gel Manicure - $35",
        "✨ Nail Art Add-on - $15",
        "💖 Full Set Acrylic - $50"
    ]

    @State private var selectedService = "💅 Gel Manicure - $35"

    // ✅ blocks past dates
    @State private var selectedDate = Date()

    private let slots = ["10:00 AM", "1:00 PM", "3:00 PM", "5:00 PM"]
    @State private var selectedTime: String? = nil

    @State private var goToConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    HStack {
                        BackPillButton { dismiss() }
                        Spacer()
                    }

                    Text("Book an Appointment")
                        .font(.title2).bold()
                        .foregroundStyle(.pink)

                    Text("With \(proName)")
                        .foregroundStyle(.secondary)

                    // Service
                    Text("Select Service").font(.headline).foregroundStyle(.pink)
                    Picker("Select Service", selection: $selectedService) {
                        ForEach(services, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Date
                    Text("Select Date").font(.headline).foregroundStyle(.pink)
                    DatePicker(
                        "Choose Date",
                        selection: $selectedDate,
                        in: Date()..., // ✅ cannot choose previous dates
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Time slots
                    Text("Select Time").font(.headline).foregroundStyle(.pink)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                        ForEach(slots, id: \.self) { slot in
                            Button {
                                selectedTime = slot
                            } label: {
                                Text(slot)
                                    .font(.subheadline).bold()
                                    .foregroundStyle(selectedTime == slot ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(selectedTime == slot ? Color.pink : Color(.systemGray6))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Confirm (nav only)
                    Button {
                        goToConfirm = true
                    } label: {
                        PrimaryButton(title: "Confirm Booking")
                    }
                    .disabled(selectedTime == nil)
                    .opacity(selectedTime == nil ? 0.6 : 1.0)

                    NavigationLink(
                        destination: BookingConfirmationViewSwiftUI(
                            service: selectedService,
                            date: selectedDate,
                            time: selectedTime ?? "—"
                        ),
                        isActive: $goToConfirm
                    ) { EmptyView() }
                }
                .padding(20)
            }
            .navigationBarHidden(true)
            .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        }
    }
}

struct BookingConfirmationViewSwiftUI: View {
    @Environment(\.dismiss) private var dismiss
    let service: String
    let date: Date
    let time: String

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                BackPillButton {
                    dismiss()
                }
                Spacer()
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.pink)

            Text("Booking Confirmed!")
                .font(.title2).bold()

            Text("Service: \(service)\nDate: \(dateText)\nTime: \(time)")
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.top, 12)

            VStack(spacing: 20) {
                NavigationLink(destination: HomeView()) {
                    PrimaryButton(title: "BACK TO HOME")
                        .frame(maxWidth: 260)
                }
            }

            Spacer()
        }
        .padding(20)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }
}

