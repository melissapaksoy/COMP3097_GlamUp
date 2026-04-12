// Melissa - Set up Firebase, AuthViewModel, and RootView for role-based navigation (client, beautyPro, admin).

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
