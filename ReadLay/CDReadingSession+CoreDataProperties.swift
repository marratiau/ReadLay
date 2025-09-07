//
//  CDReadingSession+CoreDataProperties.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/22/25.
//


import Foundation
import CoreData

extension CDReadingSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDReadingSession> {
        NSFetchRequest<CDReadingSession>(entityName: "CDReadingSession")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var minutes: Int32
    @NSManaged public var pagesRead: Int32
    @NSManaged public var note: String?
    @NSManaged public var book: CDBook
}

extension CDReadingSession: Identifiable {}
