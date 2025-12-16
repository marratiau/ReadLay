//
//  DataMigrationManager.swift
//  ReadLay
//
//  Handles migration of user data from guest to authenticated accounts
//

import Foundation
import CoreData

class DataMigrationManager {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Main Migration Method

    func migrateAllData(from guestUserId: UUID, to authenticatedUserId: UUID) throws {
        print("Starting data migration from guest \(guestUserId) to authenticated user \(authenticatedUserId)")

        try migrateBooks(from: guestUserId, to: authenticatedUserId)
        try migrateSessions(from: guestUserId, to: authenticatedUserId)
        try migrateJournalEntries(from: guestUserId, to: authenticatedUserId)
        try migrateUserDefaults(from: guestUserId, to: authenticatedUserId)
        try deleteGuestUser(guestUserId)

        print("Data migration completed successfully")
    }

    // MARK: - Core Data Migration

    private func migrateBooks(from guestUserId: UUID, to authenticatedUserId: UUID) throws {
        let bookRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        bookRequest.predicate = NSPredicate(format: "user.id == %@", guestUserId as CVarArg)

        let books = try context.fetch(bookRequest)

        guard !books.isEmpty else {
            print("No books to migrate")
            return
        }

        // Get the authenticated user
        let userRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", authenticatedUserId as CVarArg)
        guard let newUser = try context.fetch(userRequest).first else {
            throw NSError(domain: "DataMigration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authenticated user not found"])
        }

        // Reassign all books to new user
        for book in books {
            book.user = newUser
        }

        try context.save()
        print("Migrated \(books.count) books")
    }

    private func migrateSessions(from guestUserId: UUID, to authenticatedUserId: UUID) throws {
        let sessionRequest: NSFetchRequest<CDReadingSession> = CDReadingSession.fetchRequest()
        sessionRequest.predicate = NSPredicate(format: "user.id == %@", guestUserId as CVarArg)

        let sessions = try context.fetch(sessionRequest)

        guard !sessions.isEmpty else {
            print("No reading sessions to migrate")
            return
        }

        // Get the authenticated user
        let userRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", authenticatedUserId as CVarArg)
        guard let newUser = try context.fetch(userRequest).first else {
            throw NSError(domain: "DataMigration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authenticated user not found"])
        }

        // Reassign all sessions to new user
        for session in sessions {
            session.user = newUser
        }

        try context.save()
        print("Migrated \(sessions.count) reading sessions")
    }

    private func migrateJournalEntries(from guestUserId: UUID, to authenticatedUserId: UUID) throws {
        let entryRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        entryRequest.predicate = NSPredicate(format: "user.id == %@", guestUserId as CVarArg)

        let entries = try context.fetch(entryRequest)

        guard !entries.isEmpty else {
            print("No journal entries to migrate")
            return
        }

        // Get the authenticated user
        let userRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", authenticatedUserId as CVarArg)
        guard let newUser = try context.fetch(userRequest).first else {
            throw NSError(domain: "DataMigration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authenticated user not found"])
        }

        // Reassign all entries to new user
        for entry in entries {
            entry.user = newUser
        }

        try context.save()
        print("Migrated \(entries.count) journal entries")
    }

    // MARK: - UserDefaults Migration

    private func migrateUserDefaults(from guestUserId: UUID, to authenticatedUserId: UUID) {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys

        // Migrate reading preferences
        let guestPrefix = "reading_prefs_\(guestUserId)_"
        let authPrefix = "reading_prefs_\(authenticatedUserId)_"

        var migratedCount = 0

        for key in allKeys where key.hasPrefix(guestPrefix) {
            if let value = defaults.object(forKey: key) {
                let newKey = key.replacingOccurrences(of: guestPrefix, with: authPrefix)
                defaults.set(value, forKey: newKey)
                defaults.removeObject(forKey: key)
                migratedCount += 1
            }
        }

        print("Migrated \(migratedCount) UserDefaults keys")
    }

    // MARK: - Cleanup

    private func deleteGuestUser(_ guestUserId: UUID) throws {
        let userRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@ AND isGuest == YES", guestUserId as CVarArg)

        let guestUsers = try context.fetch(userRequest)

        for guestUser in guestUsers {
            context.delete(guestUser)
        }

        try context.save()
        print("Deleted guest user \(guestUserId)")
    }

    // MARK: - Migration for Existing Data (First Launch)

    /// Assigns all existing data without user relationships to the specified user
    func assignExistingDataToUser(_ userId: UUID) throws {
        print("Assigning existing data to user \(userId)")

        // Get the user
        let userRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        guard let user = try context.fetch(userRequest).first else {
            throw NSError(domain: "DataMigration", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        // Assign books without user
        let bookRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        bookRequest.predicate = NSPredicate(format: "user == nil")
        let orphanedBooks = try context.fetch(bookRequest)

        for book in orphanedBooks {
            book.user = user
        }

        // Assign sessions without user
        let sessionRequest: NSFetchRequest<CDReadingSession> = CDReadingSession.fetchRequest()
        sessionRequest.predicate = NSPredicate(format: "user == nil")
        let orphanedSessions = try context.fetch(sessionRequest)

        for session in orphanedSessions {
            session.user = user
        }

        // Assign journal entries without user
        let entryRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
        entryRequest.predicate = NSPredicate(format: "user == nil")
        let orphanedEntries = try context.fetch(entryRequest)

        for entry in orphanedEntries {
            entry.user = user
        }

        try context.save()

        print("Assigned \(orphanedBooks.count) books, \(orphanedSessions.count) sessions, and \(orphanedEntries.count) journal entries to user")
    }

    /// Checks if there's any existing data without user assignments
    func hasOrphanedData() throws -> Bool {
        let bookRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        bookRequest.predicate = NSPredicate(format: "user == nil")
        let bookCount = try context.count(for: bookRequest)

        return bookCount > 0
    }
}
