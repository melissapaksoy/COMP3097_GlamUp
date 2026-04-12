// Meric — Admin: block or unblock accounts via `users/{uid}.blocked`.

import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
private final class AdminBlockUserViewModel: ObservableObject {
    @Published private(set) var users: [RegisteredUserListItem] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionError: String?
    @Published private(set) var pendingUserId: String?

    private var listener: ListenerRegistration?

    var currentAdminUid: String? {
        Auth.auth().currentUser?.uid
    }

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

    func setBlocked(uid: String, blocked: Bool) async {
        actionError = nil
        pendingUserId = uid
        defer { pendingUserId = nil }

        do {
            try await AuthService.shared.setUserBlocked(uid: uid, blocked: blocked)
        } catch {
            actionError = error.localizedDescription
        }
    }

    func dismissActionError() {
        actionError = nil
    }
}

struct AdminBlockUserView: View {
    @StateObject private var viewModel = AdminBlockUserViewModel()

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
                    Text("No users to manage")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.users) { user in
                            AdminBlockUserRow(
                                item: user,
                                isSelf: user.id == viewModel.currentAdminUid,
                                isBusy: viewModel.pendingUserId == user.id,
                                onBlockToggle: { blocked in
                                    Task { await viewModel.setBlocked(uid: user.id, blocked: blocked) }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(screenBackground)
        .navigationTitle("Block User")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
        .alert("Action failed", isPresented: Binding(
            get: { viewModel.actionError != nil },
            set: { if !$0 { viewModel.dismissActionError() } }
        )) {
            Button("OK", role: .cancel) { viewModel.dismissActionError() }
        } message: {
            Text(viewModel.actionError ?? "")
        }
    }
}

private struct AdminBlockUserRow: View {
    let item: RegisteredUserListItem
    let isSelf: Bool
    let isBusy: Bool
    let onBlockToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)
                    Text(item.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if item.isBlocked {
                    Text("Blocked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if isSelf {
                Text("You cannot block your own admin account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    onBlockToggle(!item.isBlocked)
                } label: {
                    HStack {
                        if isBusy {
                            ProgressView()
                        }
                        Text(item.isBlocked ? "Unblock account" : "Block account")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(item.isBlocked ? Color.pink : Color.white)
                    .background(item.isBlocked ? Color.white : Color.red.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(item.isBlocked ? Color.pink.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
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
        AdminBlockUserView()
    }
}
