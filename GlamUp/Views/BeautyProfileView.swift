import SwiftUI
import FirebaseFirestore

struct BeautyProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let proUserID: String
    let proName: String
    let proRole: String

    @State private var selectedSlot: String? = nil
    @State private var averageRating: Double? = nil
    @State private var totalReviews: Int? = nil
    @State private var isLoadingReviews = false

    @State private var canNavigateToBooking = false
    @State private var goToBooking = false

    private let galleryImageNames: [String] = [
        "gallery01", "gallery02", "gallery03",
        "gallery04", "gallery05", "gallery06"
    ]

    private let services: [ServiceRowData] = [
        .init(title: "Gel Manicure", duration: "45 min", price: "$35"),
        .init(title: "Nail Art Add-on", duration: "15 min", price: "$15"),
        .init(title: "Full Set Acrylic", duration: "75 min", price: "$50")
    ]

    private let slots = ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                HStack {
                    BackPillButton { dismiss() }
                    Spacer()
                }

                // Header card
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 72, height: 72)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(.pink)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(proName)
                            .font(.title3)
                            .bold()
                            .foregroundStyle(.white)

                        Text(proRole)
                            .foregroundStyle(Color.white.opacity(0.9))
                            .font(.subheadline)

                        Group {
                            if isLoadingReviews {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                if let avg = averageRating, let total = totalReviews, total > 0 {
                                    Text("⭐ \(String(format: "%.1f", avg)) (\(total) reviews)")
                                        .foregroundStyle(.white)
                                } else {
                                    Text("No reviews yet")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 2)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.pink, Color(red: 0.85, green: 0.1, blue: 0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 4)

                // About
                SectionHeader("About")
                Text("Experienced beauty professional specializing in clean, detailed work and personalized service. Available for studio or mobile appointments depending on location.")
                    .foregroundStyle(.secondary)

                // Services
                SectionHeader("Services & Prices")
                VStack(spacing: 10) {
                    ForEach(services) { s in
                        ServiceRow(s)
                    }
                }

                // Availability
                SectionHeader("Availability")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                    ForEach(slots, id: \.self) { slot in
                        Button {
                            selectedSlot = slot
                        } label: {
                            Text(slot)
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(selectedSlot == slot ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedSlot == slot ? Color.pink : Color(.systemGray6))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Gallery
                SectionHeader("Gallery")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(galleryImageNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .clipped()
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        guard canNavigateToBooking else { return }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            goToBooking = true
                        }
                    } label: {
                        PrimaryButton(title: "BOOK APPOINTMENT")
                            .opacity(canNavigateToBooking ? 1 : 0.7)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        RatingsReviewsView(
                            proName: proName,
                            proUserID: proUserID
                        )
                    } label: {
                        SecondaryButton(title: "Ratings & Reviews")
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 10)
            }
            .padding(20)
            .onAppear {
                fetchReviews()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    canNavigateToBooking = true
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationDestination(isPresented: $goToBooking) {
            BookingAppointmentView(
                proName: proName,
                proUserID: proUserID,
                isBeautyPro: false
            )
        }
    }

    private func fetchReviews() {
        isLoadingReviews = true
        let db = Firestore.firestore()
        let reviewsRef = db.collection("reviews")
            .whereField("proUserID", isEqualTo: proUserID)

        reviewsRef.getDocuments { snapshot, error in
            defer { isLoadingReviews = false }

            guard error == nil, let documents = snapshot?.documents else {
                averageRating = nil
                totalReviews = nil
                return
            }

            let ratings = documents.compactMap { doc -> Double? in
                let ratingValue = doc.data()["rating"]

                if let doubleRating = ratingValue as? Double {
                    return doubleRating
                } else if let intRating = ratingValue as? Int {
                    return Double(intRating)
                } else {
                    return nil
                }
            }

            totalReviews = ratings.count

            if ratings.isEmpty {
                averageRating = nil
            } else {
                let sum = ratings.reduce(0, +)
                averageRating = sum / Double(ratings.count)
            }
        }
    }
}

struct ServiceRowData: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let price: String
}

private func ServiceRow(_ s: ServiceRowData) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text(s.title)
                .font(.headline)

            Text(s.duration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        Spacer()

        Text(s.price)
            .font(.headline)
            .foregroundStyle(.pink)
    }
    .padding(12)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 14))
}

private func SectionHeader(_ text: String) -> some View {
    Text(text)
        .font(.headline)
        .foregroundStyle(.pink)
}

#Preview {
    NavigationStack {
        BeautyProfileView(
            proUserID: "pro_003",
            proName: "Sophia Martinez",
            proRole: "Makeup Artist"
        )
    }
}
