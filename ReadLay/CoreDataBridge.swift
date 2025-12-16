//
//  CoreDataBridge.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/22/25.
//


import Foundation
import CoreData
import SwiftUI

enum CoreDataBridge {
    // MARK: Book (struct Book ↔ CDBook)
    static func upsertBook(from model: Book, in ctx: NSManagedObjectContext) throws -> CDBook {
        let req: NSFetchRequest<CDBook> = CDBook.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", model.id as CVarArg)
        req.fetchLimit = 1
        let existing = try ctx.fetch(req).first
        let obj = existing ?? CDBook(context: ctx)
        obj.id = model.id
        obj.title = model.title
        obj.author = model.author
        
        // Use pageCount (what exists in your Core Data model)
        obj.pageCount = Int32(model.totalPages)
        
        // Only set coverImageURL (coverImageName doesn't exist in model)
        obj.coverImageURL = model.coverImageURL
        
        if existing == nil {
            obj.currentPage = 0
        }
        return obj
    }

    static func toModel(_ obj: CDBook) -> Book {
        return Book(
            id: obj.id ?? UUID(),
            title: obj.title ?? "Untitled",
            author: obj.author,
            totalPages: Int(obj.pageCount),
            totalChapters: nil,  // CDBook doesn't store chapters yet
            coverImageName: nil,
            coverImageURL: obj.coverImageURL,
            googleBooksId: nil,
            spineColor: Color.goodreadsBrown,
            difficulty: .medium
        )
    }

    // MARK: Reading Session
    static func makeSession(for book: CDBook, pages: Int, minutes: Int, note: String? = nil, in ctx: NSManagedObjectContext) -> CDReadingSession {
        let sss = CDReadingSession(context: ctx)
        sss.id = UUID()
        sss.date = Date()
        sss.pagesRead = Int32(pages)
        sss.minutes = Int32(minutes)
        // Note: 'note' property doesn't exist in your CDReadingSession model
        sss.book = book
        book.currentPage = max(book.currentPage, book.currentPage + Int32(pages))
        return sss
    }

    // MARK: Journal Entry
    static func addJournalEntry(book: CDBook, text: String, mood: String? = nil, extra: Data? = nil, in ctx: NSManagedObjectContext) -> CDJournalEntry {
        let eee = CDJournalEntry(context: ctx)
        eee.id = UUID()
        eee.createdAt = Date()
        eee.text = text
        // Note: 'mood' and 'extraJSON' properties don't exist in your CDJournalEntry model
        eee.book = book
        return eee
    }

    // Map CDJournalEntry → JournalEntry struct
    static func toJournalStruct(_ eee: CDJournalEntry) -> JournalEntry {
        // Since extraJSON doesn't exist in Core Data, use defaults
        let sessionDuration: TimeInterval = 0
        let pagesRead = 0
        let startingPage = 0
        let endingPage = 0
        
        // FIXED: Safely unwrap all optional Core Data properties
        return JournalEntry(
            id: eee.id ?? UUID(),
            bookId: eee.book?.id ?? UUID(),
            bookTitle: eee.book?.title ?? "Unknown Book",
            bookAuthor: eee.book?.author,
            date: eee.createdAt ?? Date(),
            comment: eee.text ?? "",
            engagementEntries: [],
            sessionDuration: sessionDuration,
            pagesRead: pagesRead,
            startingPage: startingPage,
            endingPage: endingPage
        )
    }
}
