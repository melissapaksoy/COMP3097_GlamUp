// Melissa - Made the beauty pro dashboard functional with Firestore profile, quick action navigation, and logout.
// Updated with Firestore booking request backend

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BeautyProDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var proName: String = ""
    @State private var proUID: String = ""
    @State private var profileImageBase64: String? = nil
    @State private var requests: [Request] = []
    @State private var isLoadingRequests = false

    private struct Request: Identifiable {
        let id: String
        let name: String
        let service: String
        let time: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Spacer(minLength: 0)

                // MARK: Profile header
                HStack(spacing: 16) {
                    profileAvatar
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(proName.isEmpty ? "Beauty Pro" : proName)
                            .font(.title3)
                            .bold()
                        Text("Welcome back!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.pink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.pink.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)

                // MARK: Quick Actions
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink {
                        ManageServicesView(proUID: proUID)
                    } label: {
                        QuickActionCardContent(title: "Manage Services", systemImage: "pencil.and.list.clipboard")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SetAvailabilityView(proUID: proUID)
                    } label: {
                        QuickActionCardContent(title: "Set Availability", systemImage: "calendar.badge.clock")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PortfolioView()
                    } label: {
                        QuickActionCardContent(title: "Portfolio", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        RatingsReviewsView(proName: proName, proUserID: proUID)
                    } label: {
                        QuickActionCardContent(title: "Ratings & Reviews", systemImage: "star.bubble")
                    }
                    .buttonStyle(.plain)
                }

                // MARK: New Requests
                Text("New Requests")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    if isLoadingRequests {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    } else if requests.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundStyle(.pink.opacity(0.4))
                            Text("No pending requests")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(requests) { r in
                            RequestRow(
                                name: r.name,
                                service: r.service,
                                time: r.time,
                                accept: { updateRequestStatus(r, to: "approved") },
                                decline: { updateRequestStatus(r, to: "declined") }
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Logout") { authVM.signOut() }
                    .foregroundStyle(.pink)
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .onAppear {
            fetchProInfo()
        }
    }

    // MARK: - Profile avatar

    @ViewBuilder
    private var profileAvatar: some View {
        if let base64 = profileImageBase64,
           let data = Data(base64Encoded: base64),
           let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.pink.opacity(0.12))
                .overlay(
                    Text(proName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                )
        }
    }

    // MARK: - Helpers

    private func fetchProInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        proUID = uid

        Firestore.firestore()
            .collection("beautyProfessionals")
            .document(uid)
            .getDocument { doc, _ in
                guard let data = doc?.data() else { return }

                proName = data["fullName"] as? String ?? data["email"] as? String ?? "Beauty Pro"
                profileImageBase64 = data["profileImageBase64"] as? String

                fetchRequests()
            }
    }

    private func fetchRequests() {
        guard !proUID.isEmpty else { return }

        isLoadingRequests = true

        Firestore.firestore()
            .collection("bookings")
            .whereField("proUserID", isEqualTo: proUID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                isLoadingRequests = false

                if let error = error {
                    print("Error fetching requests: \(error.localizedDescription)")
                    requests = []
                    return
                }

                let docs = snapshot?.documents ?? []

                let fetched: [Request] = docs.compactMap { doc in
                    let data = doc.data()

                    let clientName = data["clientName"] as? String ?? "Client"
                    let service = data["service"] as? String ?? "Service"
                    let timeString = buildTimeText(from: data)

                    return Request(
                        id: doc.documentID,
                        name: clientName,
                        service: service,
                        time: timeString
                    )
                }

                withAnimation {
                    requests = fetched
                }
            }
    }

    private func buildTimeText(from data: [String: Any]) -> String {
        let time = data["time"] as? String ?? ""

        if let timestamp = data["date"] as? Timestamp {
            let date = timestamp.dateValue()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateText = formatter.string(from: date)

            if time.isEmpty {
                return dateText
            } else {
                return "\(dateText) • \(time)"
            }
        }

        return time.isEmpty ? "Requested time" : time
    }

    private func updateRequestStatus(_ request: Request, to status: String) {
        Firestore.firestore()
            .collection("bookings")
            .document(request.id)
            .updateData([
                "status": status,
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error updating request status: \(error.localizedDescription)")
                    return
                }

                withAnimation {
                    requests.removeAll { $0.id == request.id }
                }
            }
    }
}

// MARK: - Subviews

private struct QuickActionCardContent: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.pink)
                .font(.title3)
                .frame(width: 32, height: 32)

            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RequestRow: View {
    let name: String
    let service: String
    let time: String
    let accept: () -> Void
    let decline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name).font(.headline)
                Spacer()
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            Text(service).font(.subheadline).foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button(action: accept) {
                    Text("ACCEPT")
                        .font(.subheadline).bold().foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                }
                .buttonStyle(.plain)

                Button(action: decline) {
                    Text("DECLINE")
                        .font(.subheadline).bold().foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        BeautyProDashboardView()
            .environmentObject(AuthViewModel())
    }
}
