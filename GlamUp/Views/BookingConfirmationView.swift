// Kashfi - Created the template file with dummy buttons and navigation
// Kashfi - Updated the UI
// Kashfi - Replaced the "Back" button with "Back to Home"
// Updated: Back to Home now returns to the real existing Home screen



// BookingConfirmationView.swift
// Updated: normal page + Back to Home routes to Home

import SwiftUI

struct BookingConfirmationView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var goHome = false

    let service: String
    let date: Date
    let time: String

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            Text("Booking Confirmed!")
                .font(.title2)
                .bold()

            Text("Your Glam Session Awaits ✨")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                detailRow("Service", service)
                detailRow("Date", dateText)
                detailRow("Time", time)
                detailRow("Status", "Pending Approval")
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                goHome = true
            } label: {
                Text("Back to Home")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
        .background(Color(red: 1, green: 0.97, blue: 0.99))
        .navigationBarBackButtonHidden(true)

        .navigationDestination(isPresented: $goHome) {
            HomeView()
                .environmentObject(authVM)
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .bold()
                .foregroundStyle(.pink)

            Spacer()

            Text(value)
        }
    }
}
