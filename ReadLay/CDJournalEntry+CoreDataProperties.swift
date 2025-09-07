//
//  CDJournalEntry+CoreDataProperties.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/22/25.
//


import Foundation
import CoreData

extension CDJournalEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDJournalEntry> {
        NSFetchRequest<CDJournalEntry>(entityName: "CDJournalEntry")
    }

    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Date
    @NSManaged public var text: String
    @NSManaged public var mood: String?
    @NSManaged public var extraJSON: Data?   // optional stash for pages/duration/etc.
    @NSManaged public var book: CDBook
}

extension CDJournalEntry: Identifiable {}
