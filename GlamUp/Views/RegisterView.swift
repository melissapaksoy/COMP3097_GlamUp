import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                BackPillButton { dismiss() }
                Spacer()
            }

            Text("Create Account")
                .font(.title2).bold()
                .foregroundStyle(.pink)

            VStack(spacing: 12) {
                TextField("Full name", text: .constant(""))
                    .textFieldStyle(.roundedBorder)

                TextField("Email", text: .constant(""))
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: .constant(""))
                    .textFieldStyle(.roundedBorder)

                Picker("Account Type", selection: .constant("Client")) {
                    Text("Client").tag("Client")
                    Text("Beauty Professional").tag("Beauty Professional")
                }
                .pickerStyle(.segmented)
            }

            NavigationLink {
                HomeView()
            } label: {
                PrimaryButton(title: "Register")
            }

            Spacer()
        }
        .padding(20)
        .navigationBarHidden(true)
        .background(Color(red: 1.0, green: 0.97, blue: 0.99))
    }
}

#Preview {
    RegisterView()
}
