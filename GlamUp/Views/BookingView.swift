// Kashfi - Created the template file with dummy buttons and navigation
// Kashfi - Updated the UI
// Kashfi - Updated with Firestore backend booking save flow
// Updated: Confirmation page handles its own routing to Home
// Updated: Services are fetched from beauty pro backend data


// BookingAppointmentView.swift
// Updated: BookingConfirmation is now a real pushed page (not sheet)

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

                // Services
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Service")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    if services.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
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

                // Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Time")
                        .font(.headline)
                        .foregroundStyle(.pink)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 110), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(slots, id: \.self) { slot in
                            Button {
                                selectedTime = slot
                            } label: {
                                Text(slot)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundStyle(
                                        selectedTime == slot ? .white : .primary
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(
                                                selectedTime == slot
                                                ? Color.pink
                                                : Color(.systemGray6)
                                            )
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
                        PrimaryButton(
                            title: isSaving ? "Saving..." : "Confirm Booking"
                        )

                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
                .disabled(
                    selectedTime == nil ||
                    selectedService.isEmpty ||
                    isSaving
                )
                .opacity(
                    (selectedTime == nil ||
                     selectedService.isEmpty ||
                     isSaving) ? 0.6 : 1.0
                )

                Spacer(minLength: 12)
            }
            .padding(20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .onAppear {
            fetchServices()
        }

        // REAL PAGE (not sheet)
        .navigationDestination(isPresented: $showConfirmation) {
            BookingConfirmationView(
                service: selectedService,
                date: selectedDate,
                time: selectedTime ?? "—",
                dismissToRoot: dismissToRoot
            )
        }
    }

    private func fetchServices() {
        Firestore.firestore()
            .collection("proServices")
            .whereField("proUserID", isEqualTo: proUserID)
            .getDocuments { snapshot, error in

                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                let docs = snapshot?.documents ?? []

                let loaded = docs.compactMap { doc -> String? in
                    let data = doc.data()

                    let name =
                        data["name"] as? String ??
                        data["serviceName"] as? String ??
                        "Service"

                    let priceText: String

                    if let d = data["price"] as? Double {
                        priceText = "$\(Int(d))"
                    } else if let i = data["price"] as? Int {
                        priceText = "$\(i)"
                    } else if let s = data["price"] as? String {
                        priceText = "$\(s)"
                    } else {
                        priceText = ""
                    }

                    return priceText.isEmpty ? name : "\(name) - \(priceText)"
                }

                DispatchQueue.main.async {
                    services = loaded
                    if selectedService.isEmpty {
                        selectedService = loaded.first ?? ""
                    }
                }
            }
    }

    private func saveBooking() {
        guard !isSaving else { return }

        guard let clientID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in."
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
                errorMessage = error.localizedDescription
                return
            }

            let data = snapshot?.data() ?? [:]

            let rawName = (data["fullName"] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let clientName = rawName.isEmpty ? "Client" : rawName

            let bookingData: [String: Any] = [
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

            db.collection("bookings").addDocument(data: bookingData) { error in
                isSaving = false

                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    showConfirmation = true
                }
            }
        }
    }
}
