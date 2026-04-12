// Meric — Admin: create Firebase Auth + Firestore user

import SwiftUI
import FirebaseAuth

private extension AppUserRole {
    var addUserPickerTitle: String {
        switch self {
        case .client: return "Client"
        case .beautyPro: return "Beauty Professional"
        case .admin: return "Admin"
        }
    }
}

private let adminAddUserRoleOrder: [AppUserRole] = [.client, .beautyPro, .admin]

struct AdminAddUserView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedRole: AppUserRole = .client
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let screenBackground = Color(red: 1.0, green: 0.97, blue: 0.99)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("You can add users as an admin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                adminField(title: "Full name", content: {
                    TextField("Full name", text: $fullName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                })

                adminField(title: "Email", content: {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                })

                adminField(title: "Password", content: {
                    SecureField("Password (min. 6 characters)", text: $password)
                        .textContentType(.newPassword)
                })

                VStack(alignment: .leading, spacing: 8) {
                    Text("Account type")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.pink)
                    Picker("Account type", selection: $selectedRole) {
                        ForEach(adminAddUserRoleOrder, id: \.rawValue) { role in
                            Text(role.addUserPickerTitle).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)

                Button {
                    Task { await submit() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        PrimaryButton(title: "Create user")
                    }
                }
                .disabled(isLoading)
            }
            .padding()
        }
        .background(screenBackground)
        .navigationTitle("Add User")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Could not create user", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    @ViewBuilder
    private func adminField(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.quaternaryLabel), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }

    private func submit() async {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.createUserAsAdmin(
                newEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
                newPassword: password,
                fullName: trimmedName,
                role: selectedRole
            )
            authVM.loginBannerMessage = "New user added. Sign in again with your admin account."
        } catch {
            let text = friendlyError(error.localizedDescription)
            if Auth.auth().currentUser == nil {
                authVM.authErrorMessage = text
            } else {
                errorMessage = text
            }
        }
    }

    private func friendlyError(_ message: String) -> String {
        if message.contains("email address is already in use") || message.contains("already in use") {
            return "An account with this email already exists."
        }
        if message.contains("badly formatted") || message.contains("invalid") {
            return "Please enter a valid email address."
        }
        if message.contains("at least 6") || message.contains("weak") {
            return "Password must be at least 6 characters."
        }
        return message
    }
}

#Preview {
    NavigationStack {
        AdminAddUserView()
            .environmentObject(AuthViewModel())
    }
}
