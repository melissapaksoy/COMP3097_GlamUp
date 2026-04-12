import Combine
import FirebaseFirestore
import Foundation
import SwiftUI

/// Drives live admin dashboard metrics from the same Firestore data the app already uses for accounts (`users` collection).
@MainActor
final class AdminDashboardViewModel: ObservableObject {

    /// `nil` only when no successful read has occurred yet, or after total failure (e.g. permission denied).
    @Published private(set) var totalUsersCount: Int?
    @Published private(set) var isLoadingTotalUsers = true

    private var usersListener: ListenerRegistration?

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    /// String shown in the Total Users stat card (formatted number, or em dash while loading / if Firestore never returned a count).
    var totalUsersDisplayValue: String {
        if isLoadingTotalUsers { return "—" }
        guard let count = totalUsersCount else { return "—" }
        return Self.decimalFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    func startObservingTotalUsers() {
        stopObservingTotalUsers()
        isLoadingTotalUsers = true
        totalUsersCount = nil

        // One-shot fetch: often easier to debug than listener-only; same security rules apply.
        Task { [weak self] in
            guard let self else { return }
            do {
                let count = try await AuthService.shared.fetchRegisteredUsersCount()
                await MainActor.run {
                    self.totalUsersCount = count
                    self.isLoadingTotalUsers = false
                    print("[GlamUp/AdminStats] ViewModel: initial fetch applied count=\(count)")
                }
            } catch {
                await MainActor.run {
                    print("[GlamUp/AdminStats] ViewModel: initial fetch did not apply (listener may still succeed): \(error.localizedDescription)")
                    // Keep loading true until listener resolves; if both fail, listener sets loading false.
                }
            }
        }

        usersListener = AuthService.shared.observeRegisteredUsersCount { [weak self] result in
            guard let self else { return }
            // AuthService already hops to main; stay defensive for future changes.
            Task { @MainActor in
                switch result {
                case .success(let count):
                    self.totalUsersCount = count
                    self.isLoadingTotalUsers = false
                    print("[GlamUp/AdminStats] ViewModel: listener applied count=\(count)")
                case .failure(let error):
                    self.isLoadingTotalUsers = false
                    print("[GlamUp/AdminStats] ViewModel: listener failure — \(error.localizedDescription)")
                    // Keep last successful count from the one-shot fetch if the listener later errors.
                }
            }
        }
    }

    func stopObservingTotalUsers() {
        usersListener?.remove()
        usersListener = nil
    }
}
