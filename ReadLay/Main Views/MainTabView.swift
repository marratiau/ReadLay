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
        TabView {                                                   //tab view with all the main views
            MyBookshelfView(readSlipViewModel: readSlipViewModel)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Bookshelf")
                }
            
            MyBetsView()
                .environmentObject(readSlipViewModel)
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("My Bets")
                }
            
            
            MyJournalView(readSlipViewModel: readSlipViewModel)
                .tabItem {
                    Image(systemName: "book.pages")
                    Text("My Journal")
                }
            
        }
    }
}

#Preview {
    MainTabView()
}
