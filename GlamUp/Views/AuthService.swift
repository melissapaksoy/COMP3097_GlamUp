// Melissa - Created centralized auth service with signIn, register, signOut, and role fetching from Firestore.
// Meric — Admin metrics: Firestore listeners/fetches for registered users count and active bookings count.

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

// Represents the roles used throughout the app
public enum AppUserRole: String, Codable, CaseIterable {
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

/// Row model for admin `users` collection list (`users/{uid}` from registration).
public struct RegisteredUserListItem: Identifiable, Sendable {
    public let id: String
    public let email: String
    public let fullName: String?
    public let role: AppUserRole
    public let isBlocked: Bool

    public init(id: String, email: String, fullName: String?, role: AppUserRole, isBlocked: Bool = false) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.role = role
        self.isBlocked = isBlocked
    }

    /// Primary line for display: full name when present, otherwise email.
    public var displayName: String {
        let trimmed = fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? email : trimmed
    }
}

/// Row model for admin `bookings` collection (`BookingView.saveBooking()` shape).
public struct AdminBookingListItem: Identifiable, Sendable {
    public let id: String
    public let clientID: String
    public let clientName: String
    public let proUserID: String
    public let proName: String
    public let service: String
    public let date: Date?
    public let time: String
    public let status: String
    public let createdAt: Date?

    public init(
        id: String,
        clientID: String,
        clientName: String,
        proUserID: String,
        proName: String,
        service: String,
        date: Date?,
        time: String,
        status: String,
        createdAt: Date?
    ) {
        self.id = id
        self.clientID = clientID
        self.clientName = clientName
        self.proUserID = proUserID
        self.proName = proName
        self.service = service
        self.date = date
        self.time = time
        self.status = status
        self.createdAt = createdAt
    }
}

// Centralized authentication service used by LoginView and others
final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    /// Secondary Firebase app so `createUser` does not replace the default (admin) session.
    private static let secondaryAuthAppName = "GlamUpAdminCreateUser"

    private func authForCreatingUsers() throws -> Auth {
        if let existing = FirebaseApp.app(name: Self.secondaryAuthAppName) {
            return Auth.auth(app: existing)
        }
        guard let defaultApp = FirebaseApp.app() else {
            throw NSError(
                domain: "GlamUp.AdminUsers",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Firebase is not configured."]
            )
        }
        FirebaseApp.configure(name: Self.secondaryAuthAppName, options: defaultApp.options)
        guard let secondaryApp = FirebaseApp.app(name: Self.secondaryAuthAppName) else {
            throw NSError(
                domain: "GlamUp.AdminUsers",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Could not set up secondary Firebase app."]
            )
        }
        return Auth.auth(app: secondaryApp)
    }

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

    private static func mapUserDocuments(_ documents: [QueryDocumentSnapshot]) -> [RegisteredUserListItem] {
        documents.map { doc in
            let data = doc.data()
            let roleRaw = data["role"] as? String ?? ""
            let role = AppUserRole(rawValue: roleRaw) ?? .client
            let email = (data["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedEmail = (email?.isEmpty == false) ? email! : "—"
            let fullName = data["fullName"] as? String
            let blocked = data["blocked"] as? Bool ?? false
            return RegisteredUserListItem(
                id: doc.documentID,
                email: resolvedEmail,
                fullName: fullName,
                role: role,
                isBlocked: blocked
            )
        }
        .sorted { $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending }
    }

    /// Fetches all documents in `users` for the admin user list.
    func fetchRegisteredUsers() async throws -> [RegisteredUserListItem] {
        let snapshot = try await db.collection(usersCollectionPath).getDocuments()
        return Self.mapUserDocuments(snapshot.documents)
    }

    /// Live updates for the same `users` collection as the registered-user count.
    @discardableResult
    func observeRegisteredUsers(
        onUpdate: @escaping (Result<[RegisteredUserListItem], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection(usersCollectionPath).addSnapshotListener { snapshot, error in
            if let error {
                let ns = error as NSError
                print("[GlamUp/AdminUsers] listener ✗ error=\(error.localizedDescription) domain=\(ns.domain) code=\(ns.code)")
                DispatchQueue.main.async {
                    onUpdate(.failure(error))
                }
                return
            }
            guard let snapshot else {
                DispatchQueue.main.async {
                    onUpdate(.failure(NSError(
                        domain: "GlamUp.AdminUsers",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Firestore returned nil snapshot"]
                    )))
                }
                return
            }
            let items = Self.mapUserDocuments(snapshot.documents)
            DispatchQueue.main.async {
                onUpdate(.success(items))
            }
        }
    }

    // MARK: - Admin user management

    /// Creates a new Firebase Auth user plus `users` (and `beautyProfessionals` when needed).
    /// Uses a secondary `Auth` instance so the admin stays signed in on the default app.
    func createUserAsAdmin(
        newEmail: String,
        newPassword: String,
        fullName: String,
        role: AppUserRole
    ) async throws {
        guard auth.currentUser != nil else {
            throw NSError(
                domain: "GlamUp.AdminUsers",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No signed-in admin account."]
            )
        }

        let creationAuth = try authForCreatingUsers()
        if creationAuth.currentUser != nil {
            try creationAuth.signOut()
        }

        let result = try await creationAuth.createUser(withEmail: newEmail, password: newPassword)
        let newUid = result.user.uid
        try? creationAuth.signOut()

        guard !newUid.isEmpty else {
            throw NSError(
                domain: "GlamUp.AdminUsers",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not read the new user id."]
            )
        }

        do {
            try await db.collection(usersCollectionPath).document(newUid).setData([
                "role": role.rawValue,
                "email": newEmail,
                "fullName": fullName,
                "blocked": false,
                "createdAt": FieldValue.serverTimestamp()
            ])

            if role == .beautyPro {
                try await db.collection("beautyProfessionals").document(newUid).setData([
                    "uid": newUid,
                    "email": newEmail,
                    "fullName": fullName,
                    "specialty": "Beauty Pro",
                    "bio": "",
                    "createdAt": FieldValue.serverTimestamp()
                ])
            }
        } catch {
            throw error
        }
    }

    func setUserBlocked(uid: String, blocked: Bool) async throws {
        try await db.collection(usersCollectionPath).document(uid).setData(
            [
                "blocked": blocked,
                "updatedAt": FieldValue.serverTimestamp()
            ],
            merge: true
        )
    }

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

    // MARK: - Bookings (admin)

    /// Same collection as `BookingView.saveBooking()` → `bookings` documents.
    private let bookingsCollectionPath = "bookings"
    /// `BookingView` creates `status: "pending"`; pros set `approved` or `declined` (`BeautyProDashboardView`).
    private var activeBookingsQuery: Query {
        db.collection(bookingsCollectionPath)
            .whereField("status", in: ["pending", "approved"])
    }

    private static func mapBookingDocuments(_ documents: [QueryDocumentSnapshot]) -> [AdminBookingListItem] {
        let items: [AdminBookingListItem] = documents.map { doc in
            let data = doc.data()
            let date = (data["date"] as? Timestamp)?.dateValue()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            return AdminBookingListItem(
                id: doc.documentID,
                clientID: data["clientID"] as? String ?? "",
                clientName: data["clientName"] as? String ?? "Client",
                proUserID: data["proUserID"] as? String ?? "",
                proName: data["proName"] as? String ?? "Pro",
                service: data["service"] as? String ?? "",
                date: date,
                time: data["time"] as? String ?? "",
                status: data["status"] as? String ?? "",
                createdAt: createdAt
            )
        }
        return items.sorted { a, b in
            let ta = a.createdAt ?? a.date ?? .distantPast
            let tb = b.createdAt ?? b.date ?? .distantPast
            if ta != tb { return ta > tb }
            return a.id > b.id
        }
    }

    /// All booking documents for the admin list (any status).
    func fetchAllBookings() async throws -> [AdminBookingListItem] {
        let snapshot = try await db.collection(bookingsCollectionPath).getDocuments()
        return Self.mapBookingDocuments(snapshot.documents)
    }

    /// Live updates for the full `bookings` collection.
    @discardableResult
    func observeAllBookings(
        onUpdate: @escaping (Result<[AdminBookingListItem], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection(bookingsCollectionPath).addSnapshotListener { snapshot, error in
            if let error {
                let ns = error as NSError
                print("[GlamUp/AdminBookings] listener ✗ error=\(error.localizedDescription) domain=\(ns.domain) code=\(ns.code)")
                DispatchQueue.main.async {
                    onUpdate(.failure(error))
                }
                return
            }
            guard let snapshot else {
                DispatchQueue.main.async {
                    onUpdate(.failure(NSError(
                        domain: "GlamUp.AdminBookings",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Firestore returned nil snapshot"]
                    )))
                }
                return
            }
            let items = Self.mapBookingDocuments(snapshot.documents)
            DispatchQueue.main.async {
                onUpdate(.success(items))
            }
        }
    }

    /// Count of bookings that are still in play (not declined / not removed).
    func fetchActiveBookingsCount() async throws -> Int {
        print("[GlamUp/AdminStats] fetchActiveBookingsCount → collection(\"\(bookingsCollectionPath)\").whereField(status, in: [pending, approved]).getDocuments()")
        do {
            let snapshot = try await activeBookingsQuery.getDocuments()
            let count = snapshot.documents.count
            print("[GlamUp/AdminStats] fetchActiveBookingsCount ✓ count=\(count) fromCache=\(snapshot.metadata.isFromCache)")
            return count
        } catch {
            let ns = error as NSError
            print("[GlamUp/AdminStats] fetchActiveBookingsCount ✗ error=\(error.localizedDescription) domain=\(ns.domain) code=\(ns.code)")
            throw error
        }
    }

    @discardableResult
    func observeActiveBookingsCount(
        onUpdate: @escaping (Result<Int, Error>) -> Void
    ) -> ListenerRegistration {
        print("[GlamUp/AdminStats] observeActiveBookingsCount → snapshot listener on active bookings query")
        return activeBookingsQuery.addSnapshotListener { snapshot, error in
            if let error {
                let ns = error as NSError
                print("[GlamUp/AdminStats] bookings listener ✗ error=\(error.localizedDescription) domain=\(ns.domain) code=\(ns.code)")
                DispatchQueue.main.async {
                    onUpdate(.failure(error))
                }
                return
            }
            guard let snapshot else {
                print("[GlamUp/AdminStats] bookings listener ✗ nil snapshot")
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
            print("[GlamUp/AdminStats] bookings listener ✓ count=\(count) fromCache=\(snapshot.metadata.isFromCache)")
            DispatchQueue.main.async {
                onUpdate(.success(count))
            }
        }
    }
}
