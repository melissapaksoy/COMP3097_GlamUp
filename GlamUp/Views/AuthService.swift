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
}
