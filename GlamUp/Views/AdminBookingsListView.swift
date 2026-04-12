// Meric — Admin bookings list: live Firestore `bookings` collection via AuthService.

import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
private final class AdminBookingsListViewModel: ObservableObject {
    @Published private(set) var bookings: [AdminBookingListItem] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private var listener: ListenerRegistration?

    func startListening() {
        listener?.remove()
        isLoading = true
        errorMessage = nil

        listener = AuthService.shared.observeAllBookings { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let items):
                self.bookings = items
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

struct AdminBookingsListView: View {
    @StateObject private var viewModel = AdminBookingsListViewModel()

    private let screenBackground = Color(red: 1.0, green: 0.97, blue: 0.99)

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.bookings.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage, viewModel.bookings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange.opacity(0.85))
                    Text(message)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.bookings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.pink.opacity(0.45))
                    Text("No bookings yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.bookings) { booking in
                            AdminBookingRow(item: booking)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(screenBackground)
        .navigationTitle("Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }
}

private struct AdminBookingRow: View {
    let item: AdminBookingListItem

    private var dateText: String {
        guard let date = item.date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private var statusPresentation: (Color, String) {
        switch item.status.lowercased() {
        case "approved":
            return (.green, "Accepted")
        case "declined":
            return (.red, "Declined")
        case "pending":
            return (.orange, "Pending")
        default:
            let label = item.status.isEmpty ? "Unknown" : item.status.capitalized
            return (.secondary, label)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.service.isEmpty ? "Service" : item.service)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(statusPresentation.1)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusPresentation.0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusPresentation.0.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text("\(item.clientName) → \(item.proName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if !dateText.isEmpty {
                    Label(dateText, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !item.time.isEmpty {
                    Label(item.time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.pink)
                }
            }

            Text("ID: \(item.id)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        AdminBookingsListView()
    }
}
