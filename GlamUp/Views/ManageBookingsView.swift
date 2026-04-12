// Melissa - Manage Bookings screen for both clients and beauty pros.
// Shows Upcoming (pending), Accepted, and Declined bookings from Firestore.

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ManageBookingsView: View {
    let isBeautyPro: Bool

    @State private var selectedTab: BookingStatus = .upcoming
    @State private var bookings: [Booking] = []
    @State private var isLoading = false

    enum BookingStatus: String, CaseIterable {
        case upcoming = "pending"
        case accepted = "approved"
        case declined = "declined"

        var label: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .accepted: return "Accepted"
            case .declined: return "Declined"
            }
        }
    }

    struct Booking: Identifiable {
        let id: String
        let clientName: String
        let proName: String
        let service: String
        let date: Date?
        let time: String
        let status: String
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Status", selection: $selectedTab) {
                ForEach(BookingStatus.allCases, id: \.self) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if bookings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.pink.opacity(0.4))
                    Text("No \(selectedTab.label.lowercased()) bookings")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(bookings) { booking in
                            BookingCard(
                                booking: booking,
                                isBeautyPro: isBeautyPro,
                                onAccept: { updateStatus(booking.id, to: "approved") },
                                onDecline: { updateStatus(booking.id, to: "declined") }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .navigationTitle(isBeautyPro ? "Manage Bookings" : "My Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedTab) { _, _ in fetchBookings() }
        .onAppear { fetchBookings() }
    }

    // MARK: - Firestore

    private func fetchBookings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        bookings = []

        let field = isBeautyPro ? "proUserID" : "clientID"

        Firestore.firestore()
            .collection("bookings")
            .whereField(field, isEqualTo: uid)
            .whereField("status", isEqualTo: selectedTab.rawValue)
            .getDocuments { snapshot, _ in
                isLoading = false
                let docs = snapshot?.documents ?? []
                bookings = docs.compactMap { doc in
                    let data = doc.data()
                    return Booking(
                        id: doc.documentID,
                        clientName: data["clientName"] as? String ?? "Client",
                        proName: data["proName"] as? String ?? "Pro",
                        service: data["service"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue(),
                        time: data["time"] as? String ?? "",
                        status: data["status"] as? String ?? ""
                    )
                }.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            }
    }

    private func updateStatus(_ id: String, to status: String) {
        Firestore.firestore()
            .collection("bookings")
            .document(id)
            .updateData(["status": status, "updatedAt": Timestamp(date: Date())]) { _ in
                withAnimation { bookings.removeAll { $0.id == id } }
            }
    }
}

// MARK: - Booking Card

private struct BookingCard: View {
    let booking: ManageBookingsView.Booking
    let isBeautyPro: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    private var dateText: String {
        guard let date = booking.date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isBeautyPro ? booking.clientName : booking.proName)
                    .font(.headline)
                Spacer()
                if !dateText.isEmpty {
                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(booking.service)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !booking.time.isEmpty {
                Label(booking.time, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.pink)
            }

            if isBeautyPro && booking.status == "pending" {
                HStack(spacing: 10) {
                    Button(action: onAccept) {
                        Text("ACCEPT")
                            .font(.subheadline).bold().foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDecline) {
                        Text("DECLINE")
                            .font(.subheadline).bold().foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                statusBadge
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let color: Color
        let label: String
        if booking.status == "approved" {
            color = .green; label = "Accepted"
        } else if booking.status == "declined" {
            color = .red; label = "Declined"
        } else {
            color = .orange; label = "Pending"
        }

        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ManageBookingsView(isBeautyPro: false)
    }
}
