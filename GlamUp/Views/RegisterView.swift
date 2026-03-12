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
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        isLoading = true
        Task {
            do {
                await authVM.register(email: email, password: password, role: selectedRole)
                // After registration, FirebaseAuth signs the user in automatically.
                // RootView will switch to ContentView via auth state listener.
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    RegisterView().environmentObject(AuthViewModel())
}
