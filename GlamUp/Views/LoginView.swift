import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isAdminPresented: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("GlamUp!")
                            .font(.largeTitle).bold()
                        Image(systemName: "alarm.waves.left.and.right")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Welcome to GlamUp!")
                            .font(.title3).bold()
                        Text("Find beauty services near you — nails, lashes, makeup")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textInputAutocapitalization(.never)
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                                Image(systemName: "lock")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
                        }

                        HStack {
                            Spacer()
                            Button("Forgot password?") {}
                                .font(.footnote)
                        }
                    }

                    VStack(spacing: 10) {
                        NavigationLink(destination: AdminDashboardView()) {
                            Text("Admin Login")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button("BeautyPro Login") {}
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        NavigationLink(destination: HomeView()) {
                            Text("Client Login")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }


                        HStack {
                            Rectangle().fill(.quaternary).frame(height: 1)
                            Text("or").font(.caption).foregroundStyle(.secondary)
                            Rectangle().fill(.quaternary).frame(height: 1)
                        }
                        .padding(.vertical, 6)

                        Button {
                            // Google auth action
                        } label: {
                            HStack {
                                Image(systemName: "g.circle")
                                Text("Continue with Google")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            // Facebook auth action
                        } label: {
                            HStack {
                                Image(systemName: "f.cursive.circle")
                                Text("Continue with Facebook")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign up") {}
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    LoginView()
}

