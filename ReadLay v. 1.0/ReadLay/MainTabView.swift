//
//  MainTabView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var readSlipViewModel = ReadSlipViewModel()
    
    var body: some View {
        TabView {
            MyBookshelfView(readSlipViewModel: readSlipViewModel)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Bookshelf")
                }
            
            MyBetsView()
                .environmentObject(readSlipViewModel) // ✅ Same instance
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("My Bets")
                }
            
//            MyJournalView(readSlipViewModel: readSlipViewModel) // ✅ FIXED: Same instance
//                .tabItem {
//                    Image(systemName: "book.pages")
//                    Text("My Journal")
//                }
            
            MyActionBetsView()
                .tabItem {
                    Image(systemName: "bolt.circle")
                    Text("Action Bets")
                }
        }
        .accentColor(.goodreadsBrown)
    }
}

#Preview {
    MainTabView()
}
