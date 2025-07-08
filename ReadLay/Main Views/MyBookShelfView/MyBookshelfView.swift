//
//  MyBookshelfView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct MyBookshelfView: View {
    @State private var books: [Book] = [] // Start with empty array
    @State private var selectedBook: Book? = nil
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var showingBookSearch = false
    @State private var shouldNavigateToActiveBets = false // ADDED: Navigation state
    
    init(readSlipViewModel: ReadSlipViewModel) {
        self.readSlipViewModel = readSlipViewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mainContent
            readSlipOverlay
        }
        .background(backgroundGradient)
        .sheet(isPresented: $showingBookSearch) {
            BookSearchView { book in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    books.append(book)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BetsPlaced"))) { _ in
            // Auto-close bet row after placing bets
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedBook = nil
            }
        }
        // ADDED: Navigation observer
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveBets"))) { _ in
            shouldNavigateToActiveBets = true
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            bookshelfSection
            selectedBookSection
            Spacer()
            bottomPadding
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("My Bookshelf")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.goodreadsBrown)
                
                Text(books.isEmpty ? "Add books to get started" : "Tap a book to see reading odds")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            Spacer()
            
            balanceSection
        }
    }
    
    private var balanceSection: some View {
        VStack(spacing: 4) {
            Text("Balance")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.goodreadsBrown)
            
            Text("$\(readSlipViewModel.currentBalance, specifier: "%.2f")")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.goodreadsBrown)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Bookshelf Section
    private var bookshelfSection: some View {
        VStack(spacing: 0) {
            shelfBackground
            shelfEdge
        }
    }
    
    private var shelfBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.shelfWood.opacity(0.3),
                        Color.shelfWood.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 180)
            .overlay(booksScrollView, alignment: .bottom)
    }
    
    private var booksScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) { // ADDED: Small gap between books (4px)
                existingBooks
                addBookButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var existingBooks: some View {
        ForEach(books) { book in
            SpineView(book: book)
                .scaleEffect(selectedBook?.id == book.id ? 1.06 : 1.0)
                .rotation3DEffect(
                    .degrees(selectedBook?.id == book.id ? 3 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                // REMOVED: All shadows that create visual gaps between books
                .zIndex(selectedBook?.id == book.id ? 1 : 0)
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedBook = (selectedBook?.id == book.id) ? nil : book
                    }
                }
        }
    }
    
    private var addBookButton: some View {
        Button(action: {
            showingBookSearch = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.goodreadsAccent.opacity(0.3),
                                Color.goodreadsAccent.opacity(0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 30, height: 155) // FIXED: Standard medium width
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.goodreadsAccent.opacity(0.5), lineWidth: 1)
                    )
                
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.goodreadsAccent)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 12)
    }
    
    private var shelfEdge: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.shelfWood,
                        Color.shelfWood.opacity(0.8),
                        Color.shelfShadow.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 20)
            .overlay(woodGrainEffect)
            .shadow(color: .shelfShadow.opacity(0.4), radius: 4, x: 0, y: 2)
    }
    
    private var woodGrainEffect: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.shelfShadow.opacity(0.1),
                        Color.clear,
                        Color.shelfShadow.opacity(0.1),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    // MARK: - Selected Book Section
    private var selectedBookSection: some View {
        VStack {
            if let book = selectedBook {
                selectedBookDetails(book: book)
            } else if books.isEmpty {
                emptyState
            } else {
                placeholderState
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func selectedBookDetails(book: Book) -> some View {
        FanDuelParlayRowView(
            book: book,
            onClose: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedBook = nil
                }
            },
            onNavigateToActiveBets: {
                // ADDED: Navigation to active bets
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToActiveBets"), object: nil)
                
                // Close the selected book
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedBook = nil
                }
            },
            readSlipViewModel: readSlipViewModel
        )
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            
            Text("Your Library Awaits")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            
            Text("Add your first book to start tracking your reading goals")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
            
            addBookEmptyStateButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .frame(maxWidth: .infinity)
    }
    
    private var addBookEmptyStateButton: some View {
        Button(action: {
            showingBookSearch = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Add Book")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsBrown)
            )
        }
        .padding(.top, 8)
    }
    
    private var placeholderState: some View {
        VStack(spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .font(.title3)
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            Text("Select a book to view reading odds")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
    
    // MARK: - Supporting Views
    private var bottomPadding: some View {
        Group {
            if readSlipViewModel.betSlip.totalBets > 0 {
                Color.clear.frame(height: readSlipViewModel.betSlip.isExpanded ? 180 : 60)
            }
        }
    }
    
    private var readSlipOverlay: some View {
        ReadSlipView(viewModel: readSlipViewModel)
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

#Preview {
    MyBookshelfView(readSlipViewModel: ReadSlipViewModel())
}
