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
    @State private var selectedService: String? = nil
    @State private var sortByPrice = false
    @State private var sortByRating = false

    // Dynamic ratings
    @State private var ratingsMap: [String: Double] = [:]

    private let professionals: [Professional] = [
        .init(id: "pro_001", name: "Maria Rodriguez", role: "Nail Artist", rating: 4.8, priceFrom: 45),
        .init(id: "pro_002", name: "Alex Morgan", role: "Hair Stylist", rating: 4.9, priceFrom: 60),
        .init(id: "pro_003", name: "Sophia Martinez", role: "Makeup Artist", rating: 4.7, priceFrom: 50),
        .init(id: "pro_004", name: "Daniel Kim", role: "Barber", rating: 4.6, priceFrom: 35),
        .init(id: "pro_005", name: "Emily Chen", role: "Esthetician", rating: 4.8, priceFrom: 55)
    ]

    private var filteredProfessionals: [Professional] {
        var result = professionals

        // 🔍 SEARCH
        let trimmed = searchText.lowercased()
        if !trimmed.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(trimmed) ||
                $0.role.lowercased().contains(trimmed)
            }
        }

        // 🎯 SERVICE FILTER
        if let selectedService {
            result = result.filter { $0.role == selectedService }
        }

        // ⭐ SORTING
        if sortByRating {
            result.sort {
                (ratingsMap[$0.id] ?? $0.rating) >
                (ratingsMap[$1.id] ?? $1.rating)
            }
        }

        if sortByPrice {
            result.sort { $0.priceFrom < $1.priceFrom }
        }

        return result
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {

                    Text("Explore")
                        .font(.title)
                        .fontWeight(.bold)

                    // 🔍 SEARCH BAR
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search services or professionals...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // 🎯 FILTERS
                    FiltersRow(
                        selectedService: $selectedService,
                        sortByPrice: $sortByPrice,
                        sortByRating: $sortByRating
                    )

                    // MAP
                    Map(position: $cameraPosition)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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


// MARK: FILTER ROW
struct FiltersRow: View {
    @Binding var selectedService: String?
    @Binding var sortByPrice: Bool
    @Binding var sortByRating: Bool

    private let services = [
        "Nail Artist",
        "Hair Stylist",
        "Makeup Artist",
        "Barber",
        "Esthetician"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {

                // PRICE SORT
                FilterChip(title: "Price") {
                    sortByPrice.toggle()
                    sortByRating = false
                }

                // RATING SORT
                FilterChip(title: "Rating") {
                    sortByRating.toggle()
                    sortByPrice = false
                }

                // SERVICE FILTERS
                ForEach(services, id: \.self) { service in
                    FilterChip(title: service) {
                        selectedService = selectedService == service ? nil : service
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: CHIP
struct FilterChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(.pink)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.pink.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

// MARK: CARD
struct ProCardRow: View {
    let name: String
    let role: String
    let rating: Double
    let priceFrom: Double

    var body: some View {
        HStack {
            Circle()
                .fill(Color.pink.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.title)
                        .foregroundColor(.pink)
                )

            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(role).foregroundColor(.secondary)
                Text("★ \(rating, specifier: "%.1f")")
            }

            Spacer()

            Text("From $\(Int(priceFrom))")
                .foregroundColor(.pink)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
