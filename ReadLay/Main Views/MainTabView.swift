//
//  MainTabView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

// Tab view that contains links to the 4 main views
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var readSlipViewModel: ReadSlipViewModel
    @State private var selectedTab = 0 //We are telling the view to watch the state of the this varialbe selectedtab.

    init() {
        // Initialize with default - will update in onAppear with actual userId
        _readSlipViewModel = StateObject(wrappedValue: ReadSlipViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MyBookshelfView(readSlipViewModel: readSlipViewModel)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Bookshelf")
                }
                .tag(0)

            MyBetsView()
                .environmentObject(readSlipViewModel)
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("My Bets")
                }
                .tag(1)

            MyActivityView(readSlipViewModel: readSlipViewModel)
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("My Activity")
                }
                .tag(2)

            MyJournalView(readSlipViewModel: readSlipViewModel)
                .tabItem {
                    Image(systemName: "book.pages")
                    Text("My Journal")
                }
                .tag(3)
        }
        
        // Navigation to active bets
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveBets"))) { _ in
            DispatchQueue.main.async {
                selectedTab = 1 // Switch to My Bets tab
            }
        }
        .onAppear {
            // Set current user in ReadSlipViewModel when view appears
            if let userId = authManager.currentUser?.id {
                readSlipViewModel.setCurrentUser(userId: userId)
            }
        }
    }
}

//#Preview {
//    MainTabView()
//}
