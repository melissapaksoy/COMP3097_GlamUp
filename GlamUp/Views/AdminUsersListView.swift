// Meric — Admin users list: live Firestore `users` collection via AuthService.

import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
private final class AdminUsersListViewModel: ObservableObject {
    @Published private(set) var users: [RegisteredUserListItem] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private var listener: ListenerRegistration?

    func startListening() {
        listener?.remove()
        isLoading = true
        errorMessage = nil

        listener = AuthService.shared.observeRegisteredUsers { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let items):
                self.users = items
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

private extension AppUserRole {
    var adminDisplayTitle: String {
        switch self {
        case .admin: return "Admin"
        case .beautyPro: return "Beauty Pro"
        case .client: return "Client"
        }
    }
}

struct AdminUsersListView: View {
    @StateObject private var viewModel = AdminUsersListViewModel()

    private let screenBackground = Color(red: 1.0, green: 0.97, blue: 0.99)

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage, viewModel.users.isEmpty {
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
            } else if viewModel.users.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.pink.opacity(0.45))
                    Text("No registered users yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.users) { user in
                            AdminUserRow(item: user)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(screenBackground)
        .navigationTitle("Users")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }
}

private struct AdminUserRow: View {
    let item: RegisteredUserListItem

    private var showsEmailOnSecondLine: Bool {
        let trimmed = item.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !trimmed.isEmpty && item.email != "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    if item.isBlocked {
                        Text("Blocked")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text(item.role.adminDisplayTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.pink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.pink.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if showsEmailOnSecondLine {
                Text(item.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
        AdminUsersListView()
    }
}
