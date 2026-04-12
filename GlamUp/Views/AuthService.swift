// ============================================================
// AuthService.swift — Melissa's changes
// ============================================================
// - Created this file as a centralized auth singleton (AuthService.shared).
// - Defined AppUserRole (admin, beautyPro, client) and AppUser model.
// - signIn() signs in with Firebase and fetches the user's role
//   from Firestore — defaults to .client if nothing is found.
// - register() creates the Firebase Auth account and stores the
//   role + email in "users/{uid}" in Firestore.
// - signOut() and a private fetchRole() helper included.
// ============================================================

import Foundation
import FirebaseAuth
import FirebaseFirestore

// Represents the roles used throughout the app
public enum AppUserRole: String, Codable {
    case admin
    case beautyPro
    case client
}

// Lightweight user model returned after authentication
public struct AppUser: Codable, Sendable {
    public let uid: String
    public let email: String
    public let role: AppUserRole
}

// Centralized authentication service used by LoginView and others
final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    /// Signs in with email and password, then fetches the user's role from Firestore.
    /// Expects a document at `users/{uid}` with a `role` string field of values: "admin", "beautyPro", or "client".
    /// If the role is missing or invalid, defaults to `.client`.
    @discardableResult
    func signIn(email: String, password: String) async throws -> AppUser {
        // FirebaseAuth sign-in
        let authData = try await auth.signIn(withEmail: email, password: password)
        let uid = authData.user.uid
        let emailValue = authData.user.email ?? email
        
        // Fetch role from Firestore
        let role = try await fetchRole(for: uid) ?? .client
        
        return AppUser(uid: uid, email: emailValue, role: role)
    }

    /// Registers a new user, persists their role in Firestore, and returns the created AppUser.
    @discardableResult
    func register(email: String, password: String, role: AppUserRole) async throws -> AppUser {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // Persist minimal profile with role
        try await db.collection("users").document(uid).setData([
            "email": email,
            "role": role.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true)

        return AppUser(uid: uid, email: email, role: role)
    }

    /// Signs out the current user.
    func signOut() throws {
        try auth.signOut()
    }

    private func fetchRole(for uid: String) async throws -> AppUserRole? {
        let docRef = db.collection("users").document(uid)
        let snapshot = try await docRef.getDocument()
        guard let data = snapshot.data(), let roleString = data["role"] as? String else {
            return nil
        }
        return AppUserRole(rawValue: roleString) ?? nil
    }

    // MARK: - Admin / aggregate reads

    /// Same collection as registration: `AuthViewModel.register` and `register(email:password:role:)` write `users/{uid}`.
    private let usersCollectionPath = "users"

    /// One-shot read of all `users` documents (count == registered accounts with a profile doc).
    /// - Important: Requires Firestore rules that allow the signed-in **admin** to **list/read** `users` (see `firestore.rules` in the repo). If rules only allow `users/{ownUid}`, collection reads return permission denied and the dashboard shows "—".
    func fetchRegisteredUsersCount() async throws -> Int {
        print("[GlamUp/AdminStats] fetchRegisteredUsersCount → Firestore.collection(\"\(usersCollectionPath)\").getDocuments()")
        do {
            let snapshot = try await db.collection(usersCollectionPath).getDocuments()
            let count = snapshot.documents.count
            print("[GlamUp/AdminStats] fetchRegisteredUsersCount ✓ count=\(count) documents (metadata fromCache=\(snapshot.metadata.isFromCache))")
            return count
        } catch {
            let ns = error as NSError
            print("[GlamUp/AdminStats] fetchRegisteredUsersCount ✗ error=\(error.localizedDescription) domain=\(ns.domain) code=\(ns.code)")
            throw error
        }
    }

    /// Real-time updates for the same `users` collection count.
    /// - Note: Callbacks are dispatched on the main queue. Remove the returned registration when done.
    @discardableResult
    func observeRegisteredUsersCount(
        onUpdate: @escaping (Result<Int, Error>) -> Void
    ) -> ListenerRegistration {
        print("[GlamUp/AdminStats] observeRegisteredUsersCount → addSnapshotListener on collection \"\(usersCollectionPath)\"")
        return db.collection(usersCollectionPath).addSnapshotListener { snapshot, error in
            if let error {
                let ns = error as NSError
                print("[GlamUp/AdminStats] listener ✗ error=\(error.localizedDescription) domain=\(ns.domain) code=\(ns.code)")
                DispatchQueue.main.async {
                    onUpdate(.failure(error))
                }
                return
            }
            guard let snapshot else {
                print("[GlamUp/AdminStats] listener ✗ snapshot is nil (no error — unexpected)")
                DispatchQueue.main.async {
                    onUpdate(.failure(NSError(
                        domain: "GlamUp.AdminStats",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Firestore returned nil snapshot"]
                    )))
                }
                return
            }
            let count = snapshot.documents.count
            print("[GlamUp/AdminStats] listener ✓ count=\(count) fromCache=\(snapshot.metadata.isFromCache) hasPendingWrites=\(snapshot.metadata.hasPendingWrites)")
            DispatchQueue.main.async {
                onUpdate(.success(count))
            }
        }
    }
}
