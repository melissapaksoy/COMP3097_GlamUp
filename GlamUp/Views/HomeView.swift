// Kashfi - Created the template file with dummy buttons and navigation
// Meric - Added Search Bar, Filter and map
// Kashfi - Made Filter and Search Bar functional
// Melissa - Connected client home to Firestore, fetches real pros with live ratings, fixed pros not showing.
// Kashfi - Beauty pro cards show starting price + price filter works

import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

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

    // Filters
    @State private var selectedService: String = "All"
    @State private var selectedPriceSort: String = "None"
    @State private var selectedRatingFilter: String = "All"

    @State private var professionals: [Professional] = []
    @State private var ratingsMap: [String: Double] = [:]
    @State private var isLoading = false

    private let serviceOptions = [
        "All",
        "Nail Artist",
        "Hair Stylist",
        "Makeup Artist",
        "Barber",
        "Esthetician",
        "Lash Technician",
        "Brow Artist"
    ]

    private let priceOptions = ["None", "Low to High", "High to Low"]
    private let ratingOptions = ["All", "4.5+", "4.0+", "3.5+", "3.0+"]

    private var filteredProfessionals: [Professional] {
        var result = professionals

        let trimmed = searchText
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(trimmed) ||
                $0.role.lowercased().contains(trimmed)
            }
        }

        if selectedService != "All" {
            result = result.filter { $0.role == selectedService }
        }

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

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField(
                            "Search services or professionals...",
                            text: $searchText
                        )
                        .font(.subheadline)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                    .padding(.horizontal)

                    // Filters
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

                    // Map
                    Map(position: $cameraPosition)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                    // Cards
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)

                    } else if filteredProfessionals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 36))
                                .foregroundStyle(.pink.opacity(0.4))

                            Text(
                                professionals.isEmpty
                                ? "No professionals yet"
                                : "No results found"
                            )
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)

                    } else {
                        ForEach(filteredProfessionals) { pro in
                            Button {
                                selectedProfessional = pro
                            } label: {
                                ProCardRow(
                                    name: pro.name,
                                    role: pro.role,
                                    rating: ratingsMap[pro.id] ?? pro.rating,
                                    priceFrom: pro.priceFrom,
                                    profileImageBase64: pro.profileImageBase64
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding()
            }
        }
        .navigationTitle("Explore")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    ManageBookingsView(isBeautyPro: false)
                } label: {
                    Label("My Bookings", systemImage: "calendar")
                        .foregroundStyle(.pink)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Logout") {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Logout failed: \(error.localizedDescription)")
                    }
                }
                .foregroundStyle(.pink)
            }
        }
        .navigationDestination(item: $selectedProfessional) { pro in
            BeautyProfileView(
                proUserID: pro.id,
                proName: pro.name,
                proRole: pro.role,
                dismissToRoot: { selectedProfessional = nil }
            )
        }
        .onAppear {
            fetchProfessionals()
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }

    // MARK: Firestore

    private func fetchProfessionals() {
        isLoading = true

        Firestore.firestore()
            .collection("beautyProfessionals")
            .getDocuments { snapshot, _ in

                let docs = snapshot?.documents ?? []
                let group = DispatchGroup()
                var loaded: [Professional] = []

                for doc in docs {
                    let data = doc.data()
                    let proID = doc.documentID

                    let fullName = data["fullName"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let displayName = fullName.isEmpty ? email : fullName

                    guard !displayName.isEmpty else { continue }

                    group.enter()

                    Firestore.firestore()
                        .collection("proServices")
                        .whereField("proUserID", isEqualTo: proID)
                        .getDocuments { serviceSnap, _ in

                            let prices: [Double] =
                                (serviceSnap?.documents ?? []).compactMap { sdoc in
                                    let val = sdoc.data()["price"]

                                    if let d = val as? Double { return d }
                                    if let i = val as? Int { return Double(i) }
                                    if let s = val as? String {
                                        let clean = s.replacingOccurrences(of: "$", with: "")
                                        return Double(clean)
                                    }

                                    return nil
                                }

                            let startPrice = prices.min() ?? 0

                            loaded.append(
                                Professional(
                                    id: proID,
                                    name: displayName,
                                    role: data["specialty"] as? String ?? "Beauty Pro",
                                    rating: 0,
                                    priceFrom: startPrice,
                                    profileImageBase64: data["profileImageBase64"] as? String
                                )
                            )

                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    professionals = loaded
                    isLoading = false
                    fetchRatings()
                }
            }
    }

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
                        ratingsMap[pro.id] =
                            ratings.reduce(0, +) / Double(ratings.count)
                    }
                }
        }
    }
}

// MARK: Models

struct Professional: Identifiable, Hashable {
    let id: String
    let name: String
    let role: String
    let rating: Double
    let priceFrom: Double
    let profileImageBase64: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Professional, rhs: Professional) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Filter Button

struct SlimFilterDropdownButton: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

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
                .stroke(
                    Color.pink.opacity(isActive ? 0 : 0.18),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: Card Row

struct ProCardRow: View {
    let name: String
    let role: String
    let rating: Double
    let priceFrom: Double
    let profileImageBase64: String?

    var body: some View {
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
                        .fill(Color.pink.opacity(0.18))
                        .overlay(
                            Text(String(name.prefix(1)))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.pink)
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if rating > 0 {
                    Text("★ \(rating, specifier: "%.1f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("New")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if priceFrom > 0 {
                Text("From $\(Int(priceFrom))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
