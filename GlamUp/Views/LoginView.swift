import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("GlamUp!")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.pink)

            Text("Find and book beauty professionals")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: .constant(""))
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.top, 10)

            NavigationLink {
                HomeView()
            } label: {
                PrimaryButton(title: "Login")
            }

            Button("Continue with Google") { }
                .buttonStyle(.bordered)

            Button("Continue with Facebook") { }
                .buttonStyle(.bordered)

            HStack {
                Button("Forgot password?") { }
                    .font(.footnote)
                Spacer()
                NavigationLink("Create account") {
                    RegisterView()
                }
                .font(.footnote)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(20)
        .navigationBarBackButtonHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }
}
