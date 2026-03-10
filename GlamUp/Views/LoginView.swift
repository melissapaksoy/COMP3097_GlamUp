import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Back button to match RegisterView
                    HStack {
                        BackPillButton { dismiss() }
                        Spacer()
                    }

                    // Title to match RegisterView styling
                    Text("Welcome Back")
                        .font(.title2).bold()
                        .foregroundStyle(.pink)

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
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Password
                    HStack {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 12)
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Primary action styled like RegisterView
                    NavigationLink {
                        HomeView()
                    } label: {
                        PrimaryButton(title: "Login").fontWeight(.bold)
                    }

                    // Secondary role-based logins grouped similarly
                    VStack(spacing: 10) {
                        Text("Other options")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        NavigationLink(destination: AdminDashboardView()) {
                            HStack {
                                Image(systemName: "person.badge.shield.checkmark")
                                Text("Admin Login")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: BeautyProDashboardView()) {
                            HStack {
                                Image(systemName: "scissors")
                                Text("BeautyPro Login")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Social sign-in styled to match rounded cards
                    VStack(spacing: 10) {
                        HStack {
                            Rectangle().fill(.quaternary).frame(height: 1)
                            Text("or").font(.caption).foregroundStyle(.secondary)
                            Rectangle().fill(.quaternary).frame(height: 1)
                        }

                        Button {
                            // Google auth action
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle")
                                Text("Continue with Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            // Facebook auth action
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "f.cursive.circle")
                                Text("Continue with Facebook")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
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
                .padding(20)
            }
            .navigationBarHidden(true)
            .background(Color(red: 1.0, green: 0.97, blue: 0.99))
        }
    }
}

#Preview {
    LoginView()
}

