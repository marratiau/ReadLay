
//  MyJournalView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.

//  MyJournalView.swift - UPDATED EXISTING FILE
//  Key changes: Book-organized journal + fixed to show session notes/comments

import SwiftUI

struct MyJournalView: View {
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var selectedBook: BookJournalSummary? = nil
    
    // Group journal entries by book
    private var bookJournalSummaries: [BookJournalSummary] {
        let groupedEntries = Dictionary(grouping: readSlipViewModel.journalEntries) { $0.bookId }
        
        return groupedEntries.compactMap { (bookId, entries) in
            guard let firstEntry = entries.first else { return nil }
            
            let totalSessions = entries.count
            let totalTime = entries.reduce(0) { $0 + $1.sessionDuration }
            let totalPages = entries.reduce(0) { $0 + $1.pagesRead }
            let lastSession = entries.max(by: { $0.date < $1.date })?.date ?? Date()
            
            return BookJournalSummary(
                bookId: bookId,
                bookTitle: firstEntry.bookTitle,
                bookAuthor: firstEntry.bookAuthor,
                totalSessions: totalSessions,
                totalTime: totalTime,
                totalPages: totalPages,
                lastSession: lastSession,
                entries: entries.sorted { $0.date > $1.date }
            )
        }.sorted { $0.lastSession > $1.lastSession }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if readSlipViewModel.journalEntries.isEmpty {
                    emptyState
                } else {
                    booksListView
                }
            }
            .background(backgroundGradient)
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedBook) { bookSummary in
            BookJournalDetailView(
                bookSummary: bookSummary,
                onDismiss: {
                    selectedBook = nil
                }
            )
        }
    }
    
    private var booksListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(bookJournalSummaries) { bookSummary in
                BookJournalRowView(
                    bookSummary: bookSummary,
                    onTap: {
                        selectedBook = bookSummary
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.pages")
                .font(.system(size: 64))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Your Reading Journal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                
                Text("Complete reading sessions to build your personal reading journal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.goodreadsBeige,
                Color.goodreadsWarm.opacity(0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}


