// Melissa - Created client-facing pro profile with Firestore data; fixed portfolio grid and added tap-to-expand photos.

import SwiftUI
import FirebaseFirestore

struct BeautyProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let proUserID: String
    let proName: String
    let proRole: String

    // Profile
    @State private var bio: String = ""
    @State private var profileImageBase64: String? = nil

    // Reviews
    @State private var averageRating: Double? = nil
    @State private var totalReviews: Int? = nil
    @State private var isLoadingReviews = false

    // Services
    @State private var services: [ProService] = []
    @State private var isLoadingServices = false

    // Availability
    @State private var availability: [String: DayAvailability] = [:]
    @State private var isLoadingAvailability = false

    // Portfolio
    @State private var portfolioImages: [String] = []
    @State private var isLoadingPortfolio = false
    @State private var expandedImage: UIImage? = nil

    // Booking
    @State private var canNavigateToBooking = false
    @State private var goToBooking = false

    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                HStack { BackPillButton { dismiss() }; Spacer() }

                // MARK: Header card
                HStack(spacing: 14) {
                    Group {
                        if let base64 = profileImageBase64,
                           let data = Data(base64Encoded: base64),
                           let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 54))
                                        .foregroundStyle(.pink)
                                )
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(proName).font(.title3).bold().foregroundStyle(.white)
                        Text(proRole).foregroundStyle(Color.white.opacity(0.9)).font(.subheadline)

                        Group {
                            if isLoadingReviews {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else if let avg = averageRating, let total = totalReviews, total > 0 {
                                Text("⭐ \(String(format: "%.1f", avg)) (\(total) reviews)")
                                    .foregroundStyle(.white)
                            } else {
                                Text("No reviews yet").foregroundStyle(.white.opacity(0.8))
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
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 4)

                // MARK: About
                SectionHeader("About")
                if bio.isEmpty {
                    Text("This professional hasn't added a bio yet.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(bio).foregroundStyle(.secondary)
                }

                // MARK: Services
                SectionHeader("Services & Prices")
                if isLoadingServices {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else if services.isEmpty {
                    Text("No services listed yet.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    VStack(spacing: 10) {
                        ForEach(services) { s in
                            ServiceRow(s)
                        }
                    }
                }

                // MARK: Availability
                SectionHeader("Availability")
                if isLoadingAvailability {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else {
                    let activeDays = days.filter { availability[$0]?.isOn == true }
                    if activeDays.isEmpty {
                        Text("No availability set yet.")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(activeDays, id: \.self) { day in
                                if let a = availability[day] {
                                    HStack {
                                        Text(day).font(.subheadline).fontWeight(.medium)
                                        Spacer()
                                        Text("\(hourLabel(a.startHour)) – \(hourLabel(a.endHour))")
                                            .font(.subheadline)
                                            .foregroundStyle(.pink)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }

                // MARK: Portfolio
                SectionHeader("Portfolio")
                if isLoadingPortfolio {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else if portfolioImages.isEmpty {
                    Text("No portfolio photos yet.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(Array(portfolioImages.enumerated()), id: \.offset) { _, base64 in
                            if let data = Data(base64Encoded: base64),
                               let img = UIImage(data: data) {
                                Button { expandedImage = img } label: {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // MARK: Action buttons
                VStack(spacing: 12) {
                    Button {
                        guard canNavigateToBooking else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { goToBooking = true }
                    } label: {
                        PrimaryButton(title: "BOOK APPOINTMENT")
                            .opacity(canNavigateToBooking ? 1 : 0.7)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        RatingsReviewsView(proName: proName, proUserID: proUserID)
                    } label: {
                        SecondaryButton(title: "Ratings & Reviews")
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 10)
            }
            .padding(20)
            .onAppear {
                fetchProfile()
                fetchReviews()
                fetchServices()
                fetchAvailability()
                fetchPortfolio()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { canNavigateToBooking = true }
            }
        }
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .fullScreenCover(item: Binding(
            get: { expandedImage.map { IdentifiableImage(image: $0) } },
            set: { if $0 == nil { expandedImage = nil } }
        )) { wrapper in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                Image(uiImage: wrapper.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Button { expandedImage = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                .padding()
            }
        }
        .navigationDestination(isPresented: $goToBooking) {
            BookingAppointmentView(proName: proName, proUserID: proUserID, isBeautyPro: false)
        }
    }

    // MARK: - Fetch

    private func fetchProfile() {
        Firestore.firestore().collection("beautyProfessionals").document(proUserID).getDocument { doc, _ in
            guard let data = doc?.data() else { return }
            bio = data["bio"] as? String ?? ""
            profileImageBase64 = data["profileImageBase64"] as? String
        }
    }

    private func fetchReviews() {
        isLoadingReviews = true
        Firestore.firestore().collection("reviews")
            .whereField("proUserID", isEqualTo: proUserID)
            .getDocuments { snapshot, error in
                defer { isLoadingReviews = false }
                guard error == nil, let docs = snapshot?.documents else { return }
                let ratings = docs.compactMap { doc -> Double? in
                    let v = doc.data()["rating"]
                    if let d = v as? Double { return d }
                    if let i = v as? Int { return Double(i) }
                    return nil
                }
                totalReviews = ratings.count
                averageRating = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)
            }
    }

    private func fetchServices() {
        isLoadingServices = true
        Firestore.firestore().collection("proServices")
            .whereField("proUserID", isEqualTo: proUserID)
            .getDocuments { snapshot, _ in
                isLoadingServices = false
                services = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let duration = data["duration"] as? String,
                          let price = data["price"] as? String else { return nil }
                    return ProService(id: doc.documentID, name: name, duration: duration, price: price)
                } ?? []
            }
    }

    private func fetchAvailability() {
        isLoadingAvailability = true
        Firestore.firestore().collection("availability").document(proUserID).getDocument { doc, _ in
            isLoadingAvailability = false
            guard let data = doc?.data() else { return }
            var loaded: [String: DayAvailability] = [:]
            for day in days {
                if let d = data[day] as? [String: Any] {
                    loaded[day] = DayAvailability(
                        isOn: d["isOn"] as? Bool ?? false,
                        startHour: d["startHour"] as? Int ?? 9,
                        endHour: d["endHour"] as? Int ?? 17
                    )
                }
            }
            availability = loaded
        }
    }

    private func fetchPortfolio() {
        isLoadingPortfolio = true
        Firestore.firestore().collection("portfolios").document(proUserID).getDocument { doc, _ in
            isLoadingPortfolio = false
            portfolioImages = doc?.data()?["images"] as? [String] ?? []
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h):00 \(hour >= 12 ? "PM" : "AM")"
    }
}

// MARK: - Reusable subviews

struct ServiceRowData: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let price: String
}

private func ServiceRow(_ s: ProService) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text(s.name).font(.headline)
            Text(s.duration).font(.subheadline).foregroundStyle(.secondary)
        }
        Spacer()
        Text(s.price).font(.headline).foregroundStyle(.pink)
    }
    .padding(12)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 14))
}

private func SectionHeader(_ text: String) -> some View {
    Text(text).font(.headline).foregroundStyle(.pink)
}

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    NavigationStack {
        BeautyProfileView(proUserID: "preview123", proName: "Sophia Martinez", proRole: "Makeup Artist")
    }
}
