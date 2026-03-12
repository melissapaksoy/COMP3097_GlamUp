import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    enum UserRole: String, Codable, CaseIterable, Sendable {
        case client
        case beautyPro
        case admin
    }

    @Published var currentUser: User?
    @Published var userRole: UserRole?
    @Published var authErrorMessage: String?
    @Published var didCompleteRegistration = false
    @Published var isLoadingRole = false

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        listenForAuthChanges()
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func listenForAuthChanges() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            Task { @MainActor in
                self.currentUser = user
                self.authErrorMessage = nil

                if let uid = user?.uid {
                    await self.loadUserRole(uid: uid)
                } else {
                    self.userRole = nil
                    self.isLoadingRole = false
                }
            }
        }
    }

    private func loadUserRole(uid: String) async {
        isLoadingRole = true

        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            guard
                let data = snapshot.data(),
                let roleRaw = data["role"] as? String,
                let role = UserRole(rawValue: roleRaw)
            else {
                self.userRole = nil
                self.authErrorMessage = "User role not found."
                self.isLoadingRole = false
                return
            }

            self.userRole = role
            self.isLoadingRole = false
        } catch {
            self.userRole = nil
            self.authErrorMessage = error.localizedDescription
            self.isLoadingRole = false
        }
    }

    func register(email: String, password: String, role: UserRole) async {
        authErrorMessage = nil
        didCompleteRegistration = false

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "role": role.rawValue,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ])

            didCompleteRegistration = true

            try Auth.auth().signOut()
            currentUser = nil
            userRole = nil
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        authErrorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await loadUserRole(uid: result.user.uid)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            userRole = nil
            authErrorMessage = nil
            isLoadingRole = false
        } catch {
            authErrorMessage = error.localizedDescription
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
}
