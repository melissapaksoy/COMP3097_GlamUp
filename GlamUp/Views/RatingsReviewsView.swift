import SwiftUI

struct RatingsReviewsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                BackPillButton { dismiss() }
                Spacer()
            }

            Text("Ratings & Reviews")
                .font(.title2).bold()
                .foregroundStyle(.pink)

            VStack(alignment: .leading, spacing: 12) {
                ReviewCard(name: "Anna", rating: "5.0", text: "Super clean work and great attention to detail.")
                ReviewCard(name: "Jessica", rating: "4.5", text: "Loved the design! Affordable and friendly.")
                ReviewCard(name: "Pierre", rating: "5.0", text: "Professional and made me feel comfortable.")
            }

            Spacer()
        }
        .padding(20)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }
}

private func ReviewCard(name: String, rating: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(name).bold()
            Spacer()
            Text("⭐ \(rating)")
        }
        Text(text).foregroundStyle(.secondary)
    }
    .padding(12)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 14))
}
