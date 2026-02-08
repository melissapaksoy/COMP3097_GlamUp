//
//  BeautyProDashboardView.swift
//  GlamUp
//
//  Created by Meriç Yassine on 2026-02-08.
//

import SwiftUI

struct BeautyProDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private struct Request: Identifiable {
        let id = UUID()
        let name: String
        let service: String
        let time: String
    }

    private let requests: [Request] = [
        .init(name: "Lisa Chen", service: "Gel Manicure", time: "Today • 3:00 PM"),
        .init(name: "Rachel Adams", service: "Hair Styling", time: "Tomorrow • 11:30 AM"),
        .init(name: "Amira Patel", service: "Bridal Makeup", time: "Fri • 2:15 PM")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Back button
                HStack {
                    BackPillButton { dismiss() }
                    Spacer()
                }

                // Title
                Text("Dashboard")
                    .font(.title2).bold()
                    .foregroundStyle(.pink)

                // Quick action cards
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickActionCard(title: "Manage Services", systemImage: "pencil.and.list.clipboard") {
                        toast("Manage Services (UI only)")
                    }
                    QuickActionCard(title: "Set Availability", systemImage: "calendar.badge.clock") {
                        toast("Set Availability (UI only)")
                    }
                    QuickActionCard(title: "Portfolio", systemImage: "photo.on.rectangle.angled") {
                        toast("Portfolio Management (UI only)")
                    }
                    NavigationLink {
                        RatingsReviewsView()
                    } label: {
                        QuickActionCardContent(title: "Client Reviews", systemImage: "star.bubble")
                    }
                    .buttonStyle(.plain)
                }

                // New Requests
                Text("New Requests")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(requests) { r in
                        RequestRow(
                            name: r.name,
                            service: r.service,
                            time: r.time,
                            accept: { toast("Accepted \(r.name) (demo only)") },
                            decline: { toast("Declined \(r.name) (demo only)") }
                        )
                    }
                }
            }
            .padding(20)
        }
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func toast(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

private struct QuickActionCard: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionCardContent(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
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
                .font(.subheadline).bold()
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
            }
            Text(service)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button(action: accept) {
                    Text("ACCEPT")
                        .font(.subheadline).bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                }
                .buttonStyle(.plain)

                Button(action: decline) {
                    Text("DECLINE")
                        .font(.subheadline).bold()
                        .foregroundStyle(.white)
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
    NavigationStack { BeautyProDashboardView() }
}

