// ============================================================
// GlamUpApp.swift — Melissa's changes
// ============================================================
// - Added FirebaseApp.configure() so Firebase loads on startup.
// - Set up AuthViewModel as a @StateObject and passed it through
//   the whole app as an environment object.
// - Built RootView that watches auth state and sends users to
//   the right screen: LoginView if not logged in, loading spinner
//   while fetching role, then HomeView / BeautyProDashboardView /
//   AdminDashboardView depending on their role.
// ============================================================

import SwiftUI
import FirebaseCore

@main
struct GlamUpApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            Group {
                if authVM.currentUser == nil {
                    LoginView()
                }
                else if authVM.userRole == nil {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Loading dashboard...")
                            .foregroundStyle(.secondary)
                    }
                }
                else {
                    switch authVM.userRole! {
                    case .client:
                        HomeView()

                    case .beautyPro:
                        BeautyProDashboardView()

                    case .admin:
                        AdminDashboardView()
                    }
                }
            }
        }
    }
}
