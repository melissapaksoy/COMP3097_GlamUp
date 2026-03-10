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
                    NavigationLink {
                        HomeView()
                    } label: {
                        PrimaryButton(title: "Login").fontWeight(.bold)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                    }

                    // Secondary role-based logins grouped similarly
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Other options")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        NavigationLink(destination: AdminDashboardView()) {
                            ZStack {
                                // Leading icon pinned to the left with the same horizontal padding as the card
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark")
                                        .foregroundStyle(.pink)
                                    Spacer()
                                }

                                // Centered label overlays the whole row
                                Text("Admin Login")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: BeautyProDashboardView()) {
                            ZStack {
                                HStack {
                                    Image(systemName: "scissors")
                                        .foregroundStyle(.pink)
                                    Spacer()
                                }

                                Text("BeautyPro Login")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
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

                        // Google
                        Button {
                            // Google auth action
                        } label: {
                            ZStack {
                                // Leading icon pinned left
                                HStack {
                                    Image(systemName: "g.circle")
                                        .foregroundStyle(.pink) // optional: tint to match accent
                                    Spacer()
                                }

                                // Centered label
                                Text("Continue with Google")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        // Facebook
                        Button {
                            // Facebook auth action
                        } label: {
                            ZStack {
                                HStack {
                                    Image(systemName: "f.cursive.circle")
                                        .foregroundStyle(.pink) // optional
                                    Spacer()
                                }

                                Text("Continue with Facebook")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
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

