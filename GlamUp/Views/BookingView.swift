// Kashfi - Created the template file with dummy buttons and navigation
// Kashfi - Updated the UI
// Kashfi - Updated with Firestore backend booking save flow

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    @State private var selectedDate = Date()
    @State private var selectedTime: String? = nil
    @State private var goToConfirm = false
    @State private var goBackHome = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    private let slots = ["10:00 AM", "1:00 PM", "3:00 PM", "5:00 PM"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                HStack {
                    BackPillButton { dismiss() }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Book an Appointment")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.pink)

                    Text("With \(proName)")
                        .foregroundStyle(.secondary)
                }

                // Service
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Service")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    Picker("Select Service", selection: $selectedService) {
                        ForEach(services, id: \.self) { service in
                            Text(service).tag(service)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Date")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    DatePicker(
                        "Choose Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Time slots
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Time")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                        ForEach(slots, id: \.self) { slot in
                            Button {
                                selectedTime = slot
                            } label: {
                                Text(slot)
                                    .font(.subheadline)
                                    .bold()
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
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                // Confirm
                Button {
                    saveBooking()
                } label: {
                    ZStack {
                        PrimaryButton(title: isSaving ? "Saving..." : "Confirm Booking")
                            .opacity(isSaving ? 0.75 : 1.0)

                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
                .disabled(selectedTime == nil || isSaving)
                .opacity((selectedTime == nil || isSaving) ? 0.6 : 1.0)

                Spacer(minLength: 12)
            }
            .padding(20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationDestination(isPresented: $goToConfirm) {
            BookingConfirmationView(
                service: selectedService,
                date: selectedDate,
                time: selectedTime ?? "—"
            )
        }
    }

    private func saveBooking() {
        guard !isSaving else { return }

        guard let clientID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in to make a booking."
            return
        }

        guard let time = selectedTime else {
            errorMessage = "Please select a time."
            return
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()

        db.collection("users").document(clientID).getDocument { snapshot, error in
            if let error = error {
                isSaving = false
                errorMessage = "Failed to load your profile: \(error.localizedDescription)"
                return
            }

            let data = snapshot?.data() ?? [:]
            let rawName = (data["fullName"] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let clientName = rawName.isEmpty ? "Client" : rawName

            let clientEmail = data["email"] as? String ?? (Auth.auth().currentUser?.email ?? "")

            let bookingData: [String: Any] = [
                "clientID": clientID,
                "clientName": clientName,
                "clientEmail": clientEmail,
                "proUserID": proUserID,
                "proName": proName,
                "service": selectedService,
                "date": Timestamp(date: selectedDate),
                "time": time,
                "status": "pending",
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            db.collection("bookings").addDocument(data: bookingData) { error in
                isSaving = false

                if let error = error {
                    errorMessage = "Failed to save booking: \(error.localizedDescription)"
                    return
                }

                goToConfirm = true
            }
        }
    }
}

//struct BookingConfirmationViewSwiftUI: View {
//    @Environment(\.dismiss) private var dismiss
//
//    let service: String
//    let date: Date
//    let time: String
//
//    private var dateText: String {
//        let f = DateFormatter()
//        f.dateStyle = .medium
//        return f.string(from: date)
//    }
//
//    var body: some View {
//        VStack(spacing: 20) {
//            HStack {
//                BackPillButton {
//                    dismiss()
//                }
//                Spacer()
//            }
//
//            Spacer().frame(height: 10)
//
//            Image(systemName: "checkmark.circle.fill")
//                .font(.system(size: 72))
//                .foregroundStyle(.pink)
//
//            Text("Booking Confirmed!")
//                .font(.title2)
//                .bold()
//
//            Text("Your Glam Session Awaits ✨")
//                .font(.subheadline)
//                .foregroundStyle(.secondary)
//
//            VStack(alignment: .leading, spacing: 14) {
//                confirmationRow(title: "Service", value: service)
//                confirmationRow(title: "Date", value: dateText)
//                confirmationRow(title: "Time", value: time)
//                confirmationRow(title: "Status", value: "Pending Approval")
//            }
//            .padding(18)
//            .background(Color(.systemGray6))
//            .clipShape(RoundedRectangle(cornerRadius: 18))
//
//            Spacer()
//
//            Button {
//                dismiss()
//            } label: {
//                PrimaryButton(title: "BACK")
//            }
//        }
//        .padding(20)
//        .navigationBarBackButtonHidden(true)
//        .navigationBarHidden(true)
//        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
//    }
//
//    @ViewBuilder
//    private func confirmationRow(title: String, value: String) -> some View {
//        HStack {
//            Text(title)
//                .fontWeight(.semibold)
//                .foregroundStyle(.pink)
//
//            Spacer()
//
//            Text(value)
//                .multilineTextAlignment(.trailing)
//        }
//    }
//}
