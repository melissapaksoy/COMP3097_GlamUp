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

    // Dynamic ratings from Firestore
    @State private var ratingsMap: [String: Double] = [:]

    private let professionals: [Professional] = [
        .init(id: "pro_001", name: "Maria Rodriguez", role: "Nail Artist", rating: 4.8, priceFrom: "$45"),
        .init(id: "pro_002", name: "Alex Morgan", role: "Hair Stylist", rating: 4.9, priceFrom: "$60"),
        .init(id: "pro_003", name: "Sophia Martinez", role: "Makeup Artist", rating: 4.7, priceFrom: "$50"),
        .init(id: "pro_004", name: "Daniel Kim", role: "Barber", rating: 4.6, priceFrom: "$35"),
        .init(id: "pro_005", name: "Emily Chen", role: "Esthetician", rating: 4.8, priceFrom: "$55")
    ]

    private var filteredProfessionals: [Professional] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return professionals }

        return professionals.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) ||
            $0.role.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {

                    Text("Explore")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search professionals, services...", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    FiltersRow()

                    Map(position: $cameraPosition)
                        .mapStyle(.standard)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    ForEach(filteredProfessionals) { pro in
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                selectedProfessional = pro
                            }
                        } label: {
                            ProCardRow(
                                name: pro.name,
                                role: pro.role,
                                rating: ratingsMap[pro.id] ?? pro.rating, // ✅ dynamic fallback
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
        .navigationBarBackButtonHidden(true)
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

    // MARK: - Fetch average ratings from Firestore
    private func fetchRatings() {
        let db = Firestore.firestore()

        for pro in professionals {
            db.collection("reviews")
                .whereField("proUserID", isEqualTo: pro.id)
                .getDocuments { snapshot, error in
                    guard error == nil, let documents = snapshot?.documents else {
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

                    if !ratings.isEmpty {
                        let avg = ratings.reduce(0, +) / Double(ratings.count)
                        ratingsMap[pro.id] = avg
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
    let priceFrom: String
}

// MARK: - Filters Row
private struct FiltersRow: View {
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "Price") { toast("Sort: Price") }
                FilterChip(title: "Availability") { toast("Filter: Availability") }
                FilterChip(title: "Service") { toast("Filter: Service") }
                FilterChip(title: "Rating") { toast("Filter: Rating") }
            }
            .padding(.horizontal)
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

private struct FilterChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(title)
                    .font(.subheadline)
                    .bold()
            }
            .foregroundColor(.pink)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.pink.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthViewModel())
    }
}
