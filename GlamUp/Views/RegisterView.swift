// Kashfi - Created the template file with dummy buttons and navigation
// Melissa - Built registration screen; fixed fullName not being saved and added friendly duplicate email error.

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedRole: AuthViewModel.UserRole = .client

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    BackPillButton { dismiss() }
                    Spacer()
                }

                Text("Create Account")
                    .font(.title2).bold()
                    .foregroundStyle(.pink)

                // Fields
                Group {
                    TextField("Full name", text: $fullName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.quaternaryLabel)))
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.quaternaryLabel)))
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.quaternaryLabel)))
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                }

                // Role picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account Type").font(.headline).foregroundStyle(.pink)
                    Picker("Account Type", selection: $selectedRole) {
                        Text("Client").tag(AuthViewModel.UserRole.client)
                        Text("Beauty Professional").tag(AuthViewModel.UserRole.beautyPro)
                    }
                    .pickerStyle(.segmented)
                }

                Button(action: register) {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        PrimaryButton(title: "Register").fontWeight(.bold)
                    }
                }
                .disabled(isLoading)

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        .alert("Registration Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
        .onChange(of: authVM.didCompleteRegistration) { _, completed in
            if completed { dismiss() }
        }
    }

    private func register() {
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        isLoading = true
        Task {
            await authVM.register(email: email, password: password, fullName: fullName, role: selectedRole)
            if let authError = authVM.authErrorMessage {
                errorMessage = friendlyError(authError)
            }
            isLoading = false
        }
    }

    private func friendlyError(_ message: String) -> String {
        if message.contains("email address is already in use") || message.contains("already in use") {
            return "An account with this email already exists. Please log in instead."
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
    RegisterView().environmentObject(AuthViewModel())
}
