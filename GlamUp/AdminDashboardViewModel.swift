// Meric — ObservableObject for admin dashboard; loads live Total Users and Active Bookings via AuthService + Firestore listeners.

import Combine
import FirebaseFirestore
import Foundation
import SwiftUI

/// Live admin metrics from the same Firestore sources as the rest of the app (`users`, `bookings`).
@MainActor
final class AdminDashboardViewModel: ObservableObject {

    @Published private(set) var totalUsersCount: Int?
    @Published private(set) var isLoadingTotalUsers = true

    @Published private(set) var activeBookingsCount: Int?
    @Published private(set) var isLoadingActiveBookings = true

    private var usersListener: ListenerRegistration?
    private var bookingsListener: ListenerRegistration?

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    var totalUsersDisplayValue: String {
        formattedStat(count: totalUsersCount, isLoading: isLoadingTotalUsers)
    }

    var activeBookingsDisplayValue: String {
        formattedStat(count: activeBookingsCount, isLoading: isLoadingActiveBookings)
    }

    private func formattedStat(count: Int?, isLoading: Bool) -> String {
        if isLoading { return "—" }
        guard let count else { return "—" }
        return Self.decimalFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    func startObservingDashboardMetrics() {
        stopObservingDashboardMetrics()
        startUsersMetrics()
        startBookingsMetrics()
    }

    func stopObservingDashboardMetrics() {
        usersListener?.remove()
        usersListener = nil
        bookingsListener?.remove()
        bookingsListener = nil
    }

    // MARK: - Users

    private func startUsersMetrics() {
        isLoadingTotalUsers = true
        totalUsersCount = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let count = try await AuthService.shared.fetchRegisteredUsersCount()
                await MainActor.run {
                    self.totalUsersCount = count
                    self.isLoadingTotalUsers = false
                    print("[GlamUp/AdminStats] ViewModel: users initial fetch count=\(count)")
                }
            } catch {
                await MainActor.run {
                    print("[GlamUp/AdminStats] ViewModel: users initial fetch failed: \(error.localizedDescription)")
                }
            }
        }

        usersListener = AuthService.shared.observeRegisteredUsersCount { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .success(let count):
                    self.totalUsersCount = count
                    self.isLoadingTotalUsers = false
                    print("[GlamUp/AdminStats] ViewModel: users listener count=\(count)")
                case .failure(let error):
                    self.isLoadingTotalUsers = false
                    print("[GlamUp/AdminStats] ViewModel: users listener failure — \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Bookings

    private func startBookingsMetrics() {
        isLoadingActiveBookings = true
        activeBookingsCount = nil

        Task { [weak self] in
            guard let self else { return }
            do {
                let count = try await AuthService.shared.fetchActiveBookingsCount()
                await MainActor.run {
                    self.activeBookingsCount = count
                    self.isLoadingActiveBookings = false
                    print("[GlamUp/AdminStats] ViewModel: bookings initial fetch count=\(count)")
                }
            } catch {
                await MainActor.run {
                    print("[GlamUp/AdminStats] ViewModel: bookings initial fetch failed: \(error.localizedDescription)")
                }
            }
        }

        bookingsListener = AuthService.shared.observeActiveBookingsCount { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .success(let count):
                    self.activeBookingsCount = count
                    self.isLoadingActiveBookings = false
                    print("[GlamUp/AdminStats] ViewModel: bookings listener count=\(count)")
                case .failure(let error):
                    self.isLoadingActiveBookings = false
                    print("[GlamUp/AdminStats] ViewModel: bookings listener failure — \(error.localizedDescription)")
                }
            }
        }
    }
}
