import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var searchText: String = ""
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    )

    private let professionals: [(name: String, role: String, rating: Double, priceFrom: String)] = [
        ("Maria Rodriguez", "Nail Artist", 4.8, "$45"),
        ("Alex Morgan", "Hair Stylist", 4.9, "$60"),
        ("Sophia Martinez", "Makeup Artist", 4.7, "$50"),
        ("Daniel Kim", "Barber", 4.6, "$35"),
        ("Emily Chen", "Esthetician", 4.8, "$55")
    ]

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

                    ForEach(Array(professionals.enumerated()), id: \.offset) { _, pro in
                        NavigationLink {
                            BeautyProfileView(
                                proName: pro.name,
                                proRole: pro.role
                            )
                        } label: {
                            ProCardRow(
                                name: pro.name,
                                role: pro.role,
                                rating: pro.rating,
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
    }
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
