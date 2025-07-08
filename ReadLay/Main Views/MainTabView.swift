//
//  MainTabView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var readSlipViewModel = ReadSlipViewModel()
    @State private var selectedTab = 0 // ADDED: Track selected tab
    
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
        // FIXED: Navigation to active bets
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveBets"))) { _ in
            DispatchQueue.main.async {
                selectedTab = 1 // Switch to My Bets tab
            }
        }
    }
}

#Preview {
    MainTabView()
}
