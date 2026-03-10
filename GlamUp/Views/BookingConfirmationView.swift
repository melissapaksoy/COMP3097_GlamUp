import SwiftUI

struct BookingConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    let service: String
    let date: Date
    let time: String

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            Text("Booking Confirmed!")
                .font(.title2).bold()

            Text("Service: \(service)\nDate: \(dateText)\nTime: \(time)")
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                // Go back (to Booking, then back again to Profile if you want)
                dismiss()
            } label: {
                Text("Back")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding(24)
        .navigationBarBackButtonHidden(true)
    }
}

