//
//  ReadLayApp.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

@main
struct ReadLayApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}


#Preview {
    MainTabView()
}
