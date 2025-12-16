//
//  AuthenticationManager.swift
//  ReadLay
//
//  Manages user authentication, session state, and data migration
//  Currently using local-only storage. Firebase code is commented out and ready to enable.
//

import SwiftUI
import CoreData
import Combine

// MARK: - Firebase Imports (Uncomment when Firebase is added)
// import FirebaseAuth
// import FirebaseFirestore
// import GoogleSignIn

enum AuthError: LocalizedError {
    case emailAlreadyExists
    case invalidCredentials
    case weakPassword
    case invalidEmail
    case notGuest
    case migrationFailed
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .invalidCredentials:
            return "Invalid email or password"
        case .weakPassword:
            return "Password must be at least 8 characters with 1 number and 1 uppercase letter"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .notGuest:
            return "This operation is only available for guest users"
        case .migrationFailed:
            return "Failed to migrate your data. Please try again."
        case .unknownError(let message):
            return message
        }
    }
}

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var authError: String?

    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext

    // MARK: - Firebase Auth Listener (Uncomment when Firebase is added)
    // private var authStateListener: AuthStateDidChangeListenerHandle?

    // MARK: - Local Storage Keys
    private let currentUserKey = "com.readlay.currentUser"
    private let usersKey = "com.readlay.users" // Simple local user storage

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext

        // Load persisted session
        loadPersistedSession()

        // MARK: - Firebase Auth State Listener (Uncomment when Firebase is added)
        // setupFirebaseAuthListener()
    }

    deinit {
        // MARK: - Remove Firebase Listener (Uncomment when Firebase is added)
        // if let listener = authStateListener {
        //     Auth.auth().removeStateDidChangeListener(listener)
        // }
    }

    // MARK: - Session Management

    func checkAuthenticationState() {
        isLoading = true

        // MARK: - Firebase Auth Check (Uncomment when Firebase is added)
        // if let firebaseUser = Auth.auth().currentUser {
        //     loadOrCreateUser(from: firebaseUser)
        // } else {
        //     isLoading = false
        // }

        // Local-only: Just load from UserDefaults
        loadPersistedSession()
        isLoading = false
    }

    private func loadPersistedSession() {
        guard let data = UserDefaults.standard.data(forKey: currentUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            currentUser = nil
            return
        }
        currentUser = user
    }

    private func saveSession() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentUserKey)
        }
    }

    // MARK: - Email/Password Authentication (Local-only for now)

    @MainActor
    func signUpWithEmail(_ email: String, password: String, displayName: String) async throws {
        isLoading = true
        authError = nil

        defer { isLoading = false }

        // Validate inputs
        guard isValidEmail(email) else {
            authError = AuthError.invalidEmail.errorDescription
            throw AuthError.invalidEmail
        }

        guard isStrongPassword(password) else {
            authError = AuthError.weakPassword.errorDescription
            throw AuthError.weakPassword
        }

        // MARK: - Firebase Sign Up (Uncomment when Firebase is added)
        // do {
        //     let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        //     let changeRequest = authResult.user.createProfileChangeRequest()
        //     changeRequest.displayName = displayName
        //     try await changeRequest.commitChanges()
        //
        //     let newUser = User.authenticated(
        //         firebaseUID: authResult.user.uid,
        //         email: email,
        //         displayName: displayName
        //     )
        //
        //     await handleUserCreated(newUser)
        // } catch {
        //     authError = error.localizedDescription
        //     throw AuthError.unknownError(error.localizedDescription)
        // }

        // Local-only sign up
        let localUsers = loadLocalUsers()
        if localUsers.contains(where: { $0.email == email }) {
            authError = AuthError.emailAlreadyExists.errorDescription
            throw AuthError.emailAlreadyExists
        }

        // Store password (hashed in production - simplified for offline mode)
        let passwordHash = hashPassword(password)
        UserDefaults.standard.set(passwordHash, forKey: "password_\(email)")

        let newUser = User.localAuthenticated(email: email, displayName: displayName)

        // Handle guest data migration if needed
        if let guestUser = currentUser, guestUser.isGuest {
            try await migrateGuestData(to: newUser)
        }

        // Save user locally
        saveLocalUser(newUser)
        currentUser = newUser
        saveSession()
        createCoreDataUser(from: newUser)

        // Assign any existing data without user relationships to new user
        assignOrphanedDataIfNeeded(to: newUser.id)
    }

    @MainActor
    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        authError = nil

        defer { isLoading = false }

        // MARK: - Firebase Sign In (Uncomment when Firebase is added)
        // do {
        //     let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        //
        //     let user = loadUserFromCoreData(firebaseUID: authResult.user.uid)
        //         ?? User.authenticated(
        //             firebaseUID: authResult.user.uid,
        //             email: email,
        //             displayName: authResult.user.displayName
        //         )
        //
        //     await handleUserSignedIn(user)
        // } catch {
        //     authError = "Invalid email or password"
        //     throw AuthError.invalidCredentials
        // }

        // Local-only sign in
        let localUsers = loadLocalUsers()
        guard localUsers.contains(where: { $0.email == email }) else {
            authError = AuthError.invalidCredentials.errorDescription
            throw AuthError.invalidCredentials
        }

        // Verify password
        let storedPasswordHash = UserDefaults.standard.string(forKey: "password_\(email)") ?? ""
        let inputPasswordHash = hashPassword(password)

        guard storedPasswordHash == inputPasswordHash else {
            authError = AuthError.invalidCredentials.errorDescription
            throw AuthError.invalidCredentials
        }

        // Load user
        guard let user = localUsers.first(where: { $0.email == email }) else {
            throw AuthError.invalidCredentials
        }

        // Handle guest data migration if needed
        if let guestUser = currentUser, guestUser.isGuest {
            try await migrateGuestData(to: user)
        }

        currentUser = user
        saveSession()

        // Assign any existing data without user relationships to signed-in user
        assignOrphanedDataIfNeeded(to: user.id)
    }

    // MARK: - Google Sign-In (Commented out until Firebase is added)

    func signInWithGoogle() async throws {
        // MARK: - Google Sign-In Implementation (Uncomment when Firebase is added)
        // isLoading = true
        // authError = nil
        //
        // defer { isLoading = false }
        //
        // guard let clientID = FirebaseApp.app()?.options.clientID else {
        //     throw AuthError.unknownError("Firebase not configured")
        // }
        //
        // let config = GIDConfiguration(clientID: clientID)
        // GIDSignIn.sharedInstance.configuration = config
        //
        // guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        //       let rootViewController = windowScene.windows.first?.rootViewController else {
        //     throw AuthError.unknownError("No root view controller")
        // }
        //
        // do {
        //     let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        //     guard let idToken = result.user.idToken?.tokenString else {
        //         throw AuthError.unknownError("Failed to get ID token")
        //     }
        //
        //     let credential = GoogleAuthProvider.credential(
        //         withIDToken: idToken,
        //         accessToken: result.user.accessToken.tokenString
        //     )
        //
        //     let authResult = try await Auth.auth().signIn(with: credential)
        //
        //     let user = User.authenticated(
        //         firebaseUID: authResult.user.uid,
        //         email: authResult.user.email ?? "",
        //         displayName: authResult.user.displayName
        //     )
        //
        //     await handleUserCreated(user)
        // } catch {
        //     authError = error.localizedDescription
        //     throw AuthError.unknownError(error.localizedDescription)
        // }

        // Placeholder for offline mode
        authError = "Google Sign-In requires Firebase. Please add Firebase dependencies to enable this feature."
        throw AuthError.unknownError("Google Sign-In not available in offline mode")
    }

    // MARK: - Guest Mode

    func continueAsGuest() {
        let guestUser = User.guest()
        currentUser = guestUser
        saveSession()
        createCoreDataUser(from: guestUser)

        // Assign any existing data without user relationships to guest
        assignOrphanedDataIfNeeded(to: guestUser.id)
    }

    @MainActor
    func convertGuestToAuthenticated(email: String, password: String, displayName: String) async throws {
        guard let guestUser = currentUser, guestUser.isGuest else {
            throw AuthError.notGuest
        }

        // Call signUpWithEmail which will handle migration
        try await signUpWithEmail(email, password: password, displayName: displayName)
    }

    // MARK: - Sign Out

    func signOut() throws {
        // MARK: - Firebase Sign Out (Uncomment when Firebase is added)
        // try Auth.auth().signOut()

        currentUser = nil
        saveSession()
    }

    // MARK: - Core Data User Management

    private func createCoreDataUser(from user: User) {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)

        do {
            let existingUsers = try context.fetch(fetchRequest)

            let cdUser: CDUser
            if let existing = existingUsers.first {
                cdUser = existing
            } else {
                cdUser = CDUser(context: context)
                cdUser.id = user.id
                cdUser.createdAt = user.createdAt
            }

            cdUser.firebaseUID = user.firebaseUID
            cdUser.email = user.email
            cdUser.displayName = user.displayName
            cdUser.isGuest = user.isGuest
            cdUser.lastLoginAt = Date()

            try context.save()
        } catch {
            print("Failed to create/update CDUser: \(error)")
        }
    }

    private func loadUserFromCoreData(firebaseUID: String) -> User? {
        let fetchRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "firebaseUID == %@", firebaseUID)

        do {
            if let cdUser = try context.fetch(fetchRequest).first {
                return User(
                    id: cdUser.id ?? UUID(),
                    firebaseUID: cdUser.firebaseUID,
                    email: cdUser.email,
                    displayName: cdUser.displayName,
                    isGuest: cdUser.isGuest,
                    createdAt: cdUser.createdAt ?? Date(),
                    lastLoginAt: cdUser.lastLoginAt
                )
            }
        } catch {
            print("Failed to load user from Core Data: \(error)")
        }

        return nil
    }

    // MARK: - Data Migration

    @MainActor
    private func migrateGuestData(to authenticatedUser: User) async throws {
        guard let guestUser = currentUser, guestUser.isGuest else { return }

        let migrationManager = DataMigrationManager(context: context)

        do {
            try migrationManager.migrateAllData(from: guestUser.id, to: authenticatedUser.id)
        } catch {
            authError = AuthError.migrationFailed.errorDescription
            throw AuthError.migrationFailed
        }
    }

    // MARK: - Local User Storage (Offline Mode)

    private func saveLocalUser(_ user: User) {
        var users = loadLocalUsers()
        users.removeAll { $0.id == user.id || $0.email == user.email }
        users.append(user)

        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    private func loadLocalUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }

    // MARK: - Validation Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isStrongPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }

        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil

        return hasUppercase && hasNumber
    }

    private func hashPassword(_ password: String) -> String {
        // Simple hash for offline mode - in production with Firebase, this isn't needed
        // Firebase handles password security
        return String(password.hashValue)
    }

    // MARK: - Orphaned Data Handling

    /// Assigns any existing data without user relationships to the specified user
    /// This handles the case where data exists from before authentication was implemented
    private func assignOrphanedDataIfNeeded(to userId: UUID) {
        let migrationManager = DataMigrationManager(context: context)

        do {
            // Check if there's orphaned data
            let hasOrphanedData = try migrationManager.hasOrphanedData()

            if hasOrphanedData {
                print("Found orphaned data, assigning to user \(userId)")
                try migrationManager.assignExistingDataToUser(userId)
                print("Successfully assigned orphaned data to user")
            }
        } catch {
            print("Failed to assign orphaned data: \(error)")
            // Don't throw - this is a best-effort operation
        }
    }

    // MARK: - Firebase Auth Listener Setup (Uncomment when Firebase is added)

    // private func setupFirebaseAuthListener() {
    //     authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
    //         guard let self = self else { return }
    //
    //         if let firebaseUser = user {
    //             self.loadOrCreateUser(from: firebaseUser)
    //         } else {
    //             self.currentUser = nil
    //         }
    //     }
    // }
    //
    // private func loadOrCreateUser(from firebaseUser: FirebaseAuth.User) {
    //     if let user = loadUserFromCoreData(firebaseUID: firebaseUser.uid) {
    //         currentUser = user
    //     } else {
    //         let newUser = User.authenticated(
    //             firebaseUID: firebaseUser.uid,
    //             email: firebaseUser.email ?? "",
    //             displayName: firebaseUser.displayName
    //         )
    //         currentUser = newUser
    //         createCoreDataUser(from: newUser)
    //     }
    // }
    //
    // @MainActor
    // private func handleUserCreated(_ user: User) async {
    //     if let guestUser = currentUser, guestUser.isGuest {
    //         try? await migrateGuestData(to: user)
    //     }
    //
    //     currentUser = user
    //     createCoreDataUser(from: user)
    // }
    //
    // @MainActor
    // private func handleUserSignedIn(_ user: User) async {
    //     if let guestUser = currentUser, guestUser.isGuest {
    //         try? await migrateGuestData(to: user)
    //     }
    //
    //     currentUser = user
    // }
}
