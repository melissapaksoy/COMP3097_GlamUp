import SwiftUI
import MapKit
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var searchText: String = ""
    @State private var selectedProfessional: Professional? = nil
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    )

    // MARK: Filters
    @State private var selectedService: String = "All"
    @State private var selectedPriceSort: String = "None"
    @State private var selectedRatingFilter: String = "All"

    // Dynamic ratings
    @State private var ratingsMap: [String: Double] = [:]

    private let professionals: [Professional] = [
        .init(id: "pro_001", name: "Maria Rodriguez", role: "Nail Artist", rating: 4.8, priceFrom: 45),
        .init(id: "pro_002", name: "Alex Morgan", role: "Hair Stylist", rating: 4.9, priceFrom: 60),
        .init(id: "pro_003", name: "Sophia Martinez", role: "Makeup Artist", rating: 4.7, priceFrom: 50),
        .init(id: "pro_004", name: "Daniel Kim", role: "Barber", rating: 4.6, priceFrom: 35),
        .init(id: "pro_005", name: "Emily Chen", role: "Esthetician", rating: 4.8, priceFrom: 55)
    ]

    private let serviceOptions = [
        "All",
        "Nail Artist",
        "Hair Stylist",
        "Makeup Artist",
        "Barber",
        "Esthetician"
    ]

    private let priceOptions = [
        "None",
        "Low to High",
        "High to Low"
    ]

    private let ratingOptions = [
        "All",
        "4.5+",
        "4.0+",
        "3.5+",
        "3.0+"
    ]

    private var filteredProfessionals: [Professional] {
        var result = professionals

        // 🔍 Search
        let trimmed = searchText.lowercased()
        if !trimmed.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(trimmed) ||
                $0.role.lowercased().contains(trimmed)
            }
        }

        // 🎯 Service filter
        if selectedService != "All" {
            result = result.filter { $0.role == selectedService }
        }

        // ⭐ Rating range filter
        if selectedRatingFilter != "All" {
            let minRating: Double
            switch selectedRatingFilter {
            case "4.5+": minRating = 4.5
            case "4.0+": minRating = 4.0
            case "3.5+": minRating = 3.5
            case "3.0+": minRating = 3.0
            default: minRating = 0
            }

            result = result.filter {
                (ratingsMap[$0.id] ?? $0.rating) >= minRating
            }
        }

        // 💲 Price sort
        if selectedPriceSort == "Low to High" {
            result.sort { $0.priceFrom < $1.priceFrom }
        } else if selectedPriceSort == "High to Low" {
            result.sort { $0.priceFrom > $1.priceFrom }
        }

        return result
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {


                    // 🔍 SEARCH BAR
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search services or professionals...", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                    .padding(.horizontal)

                    // 🎯 FILTER DROPDOWNS
                    HStack(spacing: 10) {
                        Menu {
                            ForEach(priceOptions, id: \.self) { option in
                                Button(option) {
                                    selectedPriceSort = option
                                }
                            }
                        } label: {
                            SlimFilterDropdownButton(
                                title: "Price",
                                isActive: selectedPriceSort != "None"
                            )
                        }
                        .frame(maxWidth: .infinity)

                        Menu {
                            ForEach(serviceOptions, id: \.self) { option in
                                Button(option) {
                                    selectedService = option
                                }
                            }
                        } label: {
                            SlimFilterDropdownButton(
                                title: "Service",
                                isActive: selectedService != "All"
                            )
                        }
                        .frame(maxWidth: .infinity)

                        Menu {
                            ForEach(ratingOptions, id: \.self) { option in
                                Button(option) {
                                    selectedRatingFilter = option
                                }
                            }
                        } label: {
                            SlimFilterDropdownButton(
                                title: "Ratings",
                                isActive: selectedRatingFilter != "All"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)

                    // MAP
                    Map(position: $cameraPosition)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                    // PROFESSIONAL LIST
                    ForEach(filteredProfessionals) { pro in
                        Button {
                            selectedProfessional = pro
                        } label: {
                            ProCardRow(
                                name: pro.name,
                                role: pro.role,
                                rating: ratingsMap[pro.id] ?? pro.rating,
                                priceFrom: pro.priceFrom
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 16)
                }
                .padding()
            }
        }
        .navigationTitle("Explore")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Logout") {
                    authVM.signOut()
                }
                .foregroundStyle(.pink)
            }
        }
        .navigationDestination(item: $selectedProfessional) { pro in
            BeautyProfileView(
                proUserID: pro.id,
                proName: pro.name,
                proRole: pro.role
            )
        }
        .onAppear {
            fetchRatings()
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }

    // MARK: Firestore Ratings
    private func fetchRatings() {
        let db = Firestore.firestore()

        for pro in professionals {
            db.collection("reviews")
                .whereField("proUserID", isEqualTo: pro.id)
                .getDocuments { snapshot, _ in
                    guard let docs = snapshot?.documents else { return }

                    let ratings = docs.compactMap { doc -> Double? in
                        let val = doc["rating"]
                        if let d = val as? Double { return d }
                        if let i = val as? Int { return Double(i) }
                        return nil
                    }

                    if !ratings.isEmpty {
                        ratingsMap[pro.id] = ratings.reduce(0, +) / Double(ratings.count)
                    }
                }
        }
    }
}

struct Professional: Identifiable, Hashable {
    let id: String
    let name: String
    let role: String
    let rating: Double
    let priceFrom: Double
}

// MARK: - SLIM FILTER BUTTON
struct SlimFilterDropdownButton: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(isActive ? .white : .pink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(isActive ? Color.pink : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.pink.opacity(isActive ? 0 : 0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}

// MARK: - PROFESSIONAL CARD
struct ProCardRow: View {
    let name: String
    let role: String
    let rating: Double
    let priceFrom: Double

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.pink.opacity(0.18))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("★ \(rating, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("From $\(Int(priceFrom))")
                .foregroundColor(.pink)
                .fontWeight(.bold)
                .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
