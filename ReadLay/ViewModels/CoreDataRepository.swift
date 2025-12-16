//
//  CoreDataRepository.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/22/25.
//

import Foundation
import CoreData

final class CoreDataRepository {
    private let ctx: NSManagedObjectContext
    private var currentUserId: UUID?

    init(context: NSManagedObjectContext) {
        self.ctx = context
    }

    // MARK: - User Management

    func setCurrentUser(userId: UUID) {
        self.currentUserId = userId
    }

    // MARK: - Books

    func fetchBooks() throws -> [Book] {
        let req: NSFetchRequest<CDBook> = CDBook.fetchRequest()

        // Filter by current user
        if let userId = currentUserId {
            req.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)
        }

        req.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return try ctx.fetch(req).map(CoreDataBridge.toModel)
    }

    func save(book: Book) throws {
        let cdBook = try CoreDataBridge.upsertBook(from: book, in: ctx)

        // Associate with current user
        if let userId = currentUserId {
            let userReq: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            userReq.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            if let user = try ctx.fetch(userReq).first {
                cdBook.user = user
            }
        }

        try ctx.save()
    }

    func deleteBook(id: UUID) throws {
        let req: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = try ctx.fetch(req).first {
            ctx.delete(obj)
            try ctx.save()
        }
    }

    // MARK: - Sessions

    func addSession(to bookId: UUID, pages: Int, minutes: Int, note: String? = nil) throws {
        let req: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        guard let book = try ctx.fetch(req).first else { return }
        let session = CoreDataBridge.makeSession(for: book, pages: pages, minutes: minutes, note: note, in: ctx)

        // Associate with current user
        if let userId = currentUserId {
            let userReq: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            userReq.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            if let user = try ctx.fetch(userReq).first {
                session.user = user
            }
        }

        try ctx.save()
    }

    // MARK: - Journal

    func addJournalEntry(to bookId: UUID, text: String, mood: String? = nil, extra: Data? = nil) throws {
        let req: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        guard let book = try ctx.fetch(req).first else { return }
        let entry = CoreDataBridge.addJournalEntry(book: book, text: text, mood: mood, extra: extra, in: ctx)

        // Associate with current user
        if let userId = currentUserId {
            let userReq: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            userReq.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            if let user = try ctx.fetch(userReq).first {
                entry.user = user
            }
        }

        try ctx.save()
    }

    func fetchJournalEntries() throws -> [JournalEntry] {
        let req: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()

        // Filter by current user
        if let userId = currentUserId {
            req.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)
        }

        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try ctx.fetch(req).map(CoreDataBridge.toJournalStruct)
    }
}
