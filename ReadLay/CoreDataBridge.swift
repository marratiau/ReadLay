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
        obj.totalPages = Int32(model.totalPages)
        obj.coverImageName = model.coverImageName
        obj.coverImageURL = model.coverImageURL
        if existing == nil { obj.currentPage = 0 }
        return obj
    }

    static func toModel(_ obj: CDBook) -> Book {
        return Book(
            id: obj.id,
            title: obj.title,
            author: obj.author,
            totalPages: Int(obj.totalPages),
            coverImageName: obj.coverImageName,
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
        sss.note = note
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
        eee.mood = mood
        eee.extraJSON = extra
        eee.book = book
        return eee
    }

    // Optional: map CDJournalEntry → your struct JournalEntry (for ViewModel lists)
    static func toJournalStruct(_ eee: CDJournalEntry) -> JournalEntry {
        var sessionDuration: TimeInterval = 0
        var pagesRead = 0
        var startingPage = 0
        var endingPage = 0
        
        // Parse extra JSON if present
        if let extraJSON = eee.extraJSON,
           let extra = try? JSONDecoder().decode([String: Int].self, from: extraJSON) {
            sessionDuration = TimeInterval(extra["sessionDuration"] ?? 0)
            pagesRead = extra["pagesRead"] ?? 0
            startingPage = extra["startingPage"] ?? 0
            endingPage = extra["endingPage"] ?? 0
        }
        
        return JournalEntry(
            id: eee.id,
            bookId: eee.book.id,
            bookTitle: eee.book.title,
            bookAuthor: eee.book.author,
            date: eee.createdAt,
            comment: eee.text,
            engagementEntries: [],
            sessionDuration: sessionDuration,
            pagesRead: pagesRead,
            startingPage: startingPage,
            endingPage: endingPage
        )
    }
}
