import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Title
                    Text("Beauty Professionals")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)

                    // Professional Card → Profile
                    NavigationLink {
                        BeautyProfileView(
                            proName: "Maria Rodriguez",
                            proRole: "Nail Artist"
                        )
                    } label: {
                        ProCardRow(
                            name: "Maria Rodriguez",
                            role: "Nail Artist",
                            rating: 4.8,
                            priceFrom: "$45"
                        )
                    }
                    .buttonStyle(.plain)

                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

// MARK: - Professional Card
struct ProCardRow: View {
    let name: String
    let role: String
    let rating: Double
    let priceFrom: String

    var body: some View {
        HStack(spacing: 14) {

            // Avatar placeholder
            Circle()
                .fill(Color.pink.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .foregroundColor(.secondary)

                Text("★ \(rating, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("From \(priceFrom)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.pink)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}
