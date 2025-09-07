//
//  CDBook+CoreDataProperties.swift
//  ReadLay
//
//  Created by Mateo Arratia on 8/22/25.
//


import Foundation
import CoreData

extension CDBook {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBook> {
        NSFetchRequest<CDBook>(entityName: "CDBook")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String?
    @NSManaged public var totalPages: Int32
    @NSManaged public var coverImageName: String?
    @NSManaged public var coverImageURL: String?
    @NSManaged public var currentPage: Int32
    @NSManaged public var startedAt: Date?
    @NSManaged public var finishedAt: Date?
    @NSManaged public var sessions: NSSet?
    @NSManaged public var entries: NSSet?
}

extension CDBook: Identifiable {}
