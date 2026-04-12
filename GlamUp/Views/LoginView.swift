// Meric — Refined UI: auth-bg, shared GlamUpAuthLogo/AuthScreenChrome, welcome title + logo layout.
// Kashfi - Created the template file with dummy buttons and navigation
// Melissa - Created login screen with Firebase auth and role-based navigation to client, pro, or admin dashboard.

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    private enum Destination: Hashable {
        case admin
        case beautyPro
        case client
    }

    @State private var path: [Destination] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Image("auth-bg")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                ScrollView {
                    VStack(spacing: AuthScreenChrome.stackSpacing) {
                    // Back button to match RegisterView
                    HStack {
                        BackPillButton { dismiss() }
                        Spacer()
                    }

                    // Title to match RegisterView styling
                    Text("Welcome to")
                        .font(.title2).bold()
                        .foregroundStyle(.pink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, AuthScreenChrome.titleTopPadding)

                    GlamUpAuthLogo()

                    // Fields styled like RegisterView (roundedBorder)
                    // Email
                    HStack {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.vertical, 14)     // controls height
                            .padding(.horizontal, 12)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.quaternaryLabel), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)

                    // Password
                    HStack {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 12)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.quaternaryLabel), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)

                    // Primary action styled like RegisterView
                    Button {
                        Task {
                            await handleLogin()
                        }
                    } label: {
                        PrimaryButton(title: "Login").fontWeight(.bold)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                    }

                    // Footer to navigate to RegisterView
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        NavigationLink(destination: RegisterView()) {
                            Text("Sign up!").foregroundStyle(.pink)
                        }
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 0)
                    }
                    .padding(.horizontal, AuthScreenChrome.horizontalPadding)
                    .padding(.vertical, AuthScreenChrome.verticalPadding)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Destination.self) { dest in
                switch dest {
                case .admin:
                    AdminDashboardView()
                case .beautyPro:
                    BeautyProDashboardView()
                case .client:
                    HomeView()
                }
            }
            .alert("Login Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { msg in
                Text(msg)
            }
        }
    }

    private func handleLogin() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await AuthService.shared.signIn(email: email, password: password)
            switch user.role {
            case .admin:
                path.append(.admin)
            case .beautyPro:
                path.append(.beautyPro)
            case .client:
                path.append(.client)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
}

