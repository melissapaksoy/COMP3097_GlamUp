// BookingView.swift — built by Kashfi

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
    @State private var selectedDate = Date()
    @State private var selectedTime: String? = nil
    @State private var goToConfirm = false

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

                // Confirm
                Button {
                    goToConfirm = true
                } label: {
                    PrimaryButton(title: "Confirm Booking")
                }
                .disabled(selectedTime == nil)
                .opacity(selectedTime == nil ? 0.6 : 1.0)

                Spacer(minLength: 12)
            }
            .padding(20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationDestination(isPresented: $goToConfirm) {
            BookingConfirmationViewSwiftUI(
                service: selectedService,
                date: selectedDate,
                time: selectedTime ?? "—"
            )
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
        VStack(spacing: 20) {
            HStack {
                BackPillButton {
                    dismiss()
                }
                Spacer()
            }

            Spacer().frame(height: 10)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.pink)

            Text("Booking Confirmed!")
                .font(.title2)
                .bold()

            Text("Your Glam Session Awaits ✨")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                confirmationRow(title: "Service", value: service)
                confirmationRow(title: "Date", value: dateText)
                confirmationRow(title: "Time", value: time)
            }
            .padding(18)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer()

            Button {
                dismiss()
            } label: {
                PrimaryButton(title: "BACK")
            }
        }
        .padding(20)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }

    @ViewBuilder
    private func confirmationRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(.pink)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
