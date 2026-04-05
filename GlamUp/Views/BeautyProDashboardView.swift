//
//  BeautyProDashboardView.swift
//  GlamUp
//
//  Created by Meriç Yassine on 2026-02-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BeautyProDashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var proName: String = ""
    @State private var proUID: String = ""

    private struct Request: Identifiable {
        let id = UUID()
        let name: String
        let service: String
        let time: String
    }

    @State private var requests: [Request] = [
        .init(name: "Lisa Chen", service: "Gel Manicure", time: "Today • 3:00 PM"),
        .init(name: "Rachel Adams", service: "Hair Styling", time: "Tomorrow • 11:30 AM"),
        .init(name: "Amira Patel", service: "Bridal Makeup", time: "Fri • 2:15 PM")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Spacer(minLength: 0)

                Text("Dashboard")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.pink)

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

                Text("New Requests")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    if requests.isEmpty {
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
                                accept: { removeRequest(r) },
                                decline: { removeRequest(r) }
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
                Button("Logout") {
                    authVM.signOut()
                }
                .foregroundStyle(.pink)
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .onAppear { fetchProInfo() }
    }

    private func fetchProInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        proUID = uid

        Firestore.firestore().collection("users").document(uid).getDocument { doc, _ in
            guard let data = doc?.data() else { return }
            proName = (data["fullName"] as? String)
                ?? (data["email"] as? String)
                ?? "Beauty Pro"
        }
    }

    private func removeRequest(_ request: Request) {
        withAnimation {
            requests.removeAll { $0.id == request.id }
        }
    }
}

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
                Text(name)
                    .font(.headline)

                Spacer()

                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(service)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button(action: accept) {
                    Text("ACCEPT")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(.plain)

                Button(action: decline) {
                    Text("DECLINE")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red)
                        )
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
