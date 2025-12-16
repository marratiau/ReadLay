//
//  User.swift
//  ReadLay
//
//  User model for authentication
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let firebaseUID: String?
    let email: String?
    let displayName: String?
    let isGuest: Bool
    let createdAt: Date
    var lastLoginAt: Date?

    var isAuthenticated: Bool {
        !isGuest && (firebaseUID != nil || email != nil)
    }

    // Guest user factory
    static func guest() -> User {
        User(
            id: UUID(),
            firebaseUID: nil,
            email: nil,
            displayName: "Guest",
            isGuest: true,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }

    // Authenticated user factory (for Firebase - currently commented out)
    static func authenticated(firebaseUID: String?, email: String, displayName: String?) -> User {
        User(
            id: UUID(),
            firebaseUID: firebaseUID,
            email: email,
            displayName: displayName ?? email,
            isGuest: false,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }

    // Local-only authenticated user (for offline mode)
    static func localAuthenticated(email: String, displayName: String?) -> User {
        User(
            id: UUID(),
            firebaseUID: nil,
            email: email,
            displayName: displayName ?? email,
            isGuest: false,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
}
