//
//  Persistence.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ReadLay")

        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension NSManagedObjectContext {
    func saveIfNeeded() {
        if hasChanges {
            try? save()
        }
    }
}
