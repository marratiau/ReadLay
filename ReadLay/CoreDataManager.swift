//
//  CoreDataManager.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/23/25.
//


import Foundation
import CoreData

// REMOVED actor - use standard class with background context
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    private init() {
        container = NSPersistentContainer(name: "ReadLayModel")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext = container.newBackgroundContext()
    }
    
    // MARK: - Reading Sessions (Simplified synchronous versions)
    
    func saveReadingSession(betId: UUID, bookId: UUID, startPage: Int, endPage: Int, pagesRead: Int) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                guard let book = try self.backgroundContext.fetch(fetchRequest).first else {
                    // Create book if doesn't exist
                    let newBook = CDBook(context: self.backgroundContext)
                    newBook.id = bookId
                    newBook.currentPage = Int32(endPage)
                    
                    let session = CDReadingSession(context: self.backgroundContext)
                    session.id = UUID()
                    session.date = Date()
                    session.pagesRead = Int32(pagesRead)
                    session.minutes = 0
                    session.book = newBook
                    
                    try self.backgroundContext.save()
                    return
                }
                
                let session = CDReadingSession(context: self.backgroundContext)
                session.id = UUID()
                session.date = Date()
                session.pagesRead = Int32(pagesRead)
                session.minutes = 0
                session.book = book
                
                book.currentPage = max(book.currentPage, Int32(endPage))
                
                try self.backgroundContext.save()
            } catch {
                print("Failed to save reading session: \(error)")
            }
        }
    }
    
    // MARK: - Journal Entries (Simplified synchronous versions)
    
    func saveJournalEntry(_ entry: JournalEntry) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", entry.bookId as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let book: CDBook
                if let existingBook = try self.backgroundContext.fetch(fetchRequest).first {
                    book = existingBook
                } else {
                    book = CDBook(context: self.backgroundContext)
                    book.id = entry.bookId
                    book.title = entry.bookTitle
                    book.author = entry.bookAuthor
                    book.totalPages = 0
                }
                
                let cdEntry = CDJournalEntry(context: self.backgroundContext)
                cdEntry.id = entry.id
                cdEntry.createdAt = entry.date
                cdEntry.text = entry.comment
                cdEntry.book = book
                
                if let extraData = try? JSONEncoder().encode([
                    "sessionDuration": Int(entry.sessionDuration),
                    "pagesRead": entry.pagesRead,
                    "startingPage": entry.startingPage,
                    "endingPage": entry.endingPage
                ]) {
                    cdEntry.extraJSON = extraData
                }
                
                try self.backgroundContext.save()
            } catch {
                print("Failed to save journal entry: \(error)")
            }
        }
    }
    
    func fetchJournalEntries(completion: @escaping ([JournalEntry]) -> Void) {
        backgroundContext.perform { [weak self] in
            guard let self = self else {
                completion([])
                return
            }
            
            let fetchRequest: NSFetchRequest<CDJournalEntry> = CDJournalEntry.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            fetchRequest.fetchLimit = 100
            
            do {
                let cdEntries = try self.backgroundContext.fetch(fetchRequest)
                
                let entries = cdEntries.compactMap { cdEntry -> JournalEntry? in
                    var sessionDuration: TimeInterval = 0
                    var pagesRead: Int = 0
                    var startingPage: Int = 0
                    var endingPage: Int = 0
                    
                    if let extraJSON = cdEntry.extraJSON,
                       let extra = try? JSONDecoder().decode([String: Int].self, from: extraJSON) {
                        sessionDuration = TimeInterval(extra["sessionDuration"] ?? 0)
                        pagesRead = extra["pagesRead"] ?? 0
                        startingPage = extra["startingPage"] ?? 0
                        endingPage = extra["endingPage"] ?? 0
                    }
                    
                    return JournalEntry(
                        id: cdEntry.id,
                        bookId: cdEntry.book.id,
                        bookTitle: cdEntry.book.title,
                        bookAuthor: cdEntry.book.author,
                        date: cdEntry.createdAt,
                        comment: cdEntry.text,
                        engagementEntries: [],
                        sessionDuration: sessionDuration,
                        pagesRead: pagesRead,
                        startingPage: startingPage,
                        endingPage: endingPage
                    )
                }
                
                DispatchQueue.main.async {
                    completion(entries)
                }
            } catch {
                print("Failed to fetch journal entries: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // MARK: - Books
    
    func saveBook(_ book: Book) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let cdBook: CDBook
                if let existingBook = try self.backgroundContext.fetch(fetchRequest).first {
                    cdBook = existingBook
                } else {
                    cdBook = CDBook(context: self.backgroundContext)
                    cdBook.id = book.id
                }
                
                cdBook.title = book.title
                cdBook.author = book.author
                cdBook.totalPages = Int32(book.totalPages)
                cdBook.coverImageName = book.coverImageName
                cdBook.coverImageURL = book.coverImageURL
                
                try self.backgroundContext.save()
            } catch {
                print("Failed to save book: \(error)")
            }
        }
    }
    
    func deleteBook(id: UUID) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<CDBook> = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                if let book = try self.backgroundContext.fetch(fetchRequest).first {
                    self.backgroundContext.delete(book)
                    try self.backgroundContext.save()
                }
            } catch {
                print("Failed to delete book: \(error)")
            }
        }
    }
}
