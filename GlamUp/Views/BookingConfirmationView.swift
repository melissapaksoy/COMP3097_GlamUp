// Kashfi - Created the template file with dummy buttons and navigation
// Kashfi - Updated the UI
// Kashfi - Replaced the "Back" button with "Back to Home"
import SwiftUI

struct BookingConfirmationView: View {
    let service: String
    let date: Date
    let time: String

    @State private var goHome = false

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 20)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            Text("Booking Confirmed!")
                .font(.title2)
                .bold()

            Text("Your Glam Session Awaits ✨")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                detailRow(title: "Service", value: service)
                detailRow(title: "Date", value: dateText)
                detailRow(title: "Time", value: time)
                detailRow(title: "Status", value: "Pending Approval")
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

            Button {
                goHome = true
            } label: {
                Text("Back to Home")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding(24)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            HomeView()
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
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
