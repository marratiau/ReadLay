//
//  MyBookshelfView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import CoreData

struct MyBookshelfView: View {
    
    @Environment(\.managedObjectContext) private var ctx
    private var repo: CoreDataRepository { CoreDataRepository(context: ctx) }
    @State private var books: [Book] = []
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var showingBookSearch = false
    @State private var shouldNavigateToActiveBets = false
    
    // CHANGED: Support multiple selected books
    @State private var selectedBooks: Set<UUID> = []
    @State private var bookOrder: [UUID] = []  // Maintain order of selection
    @State private var showHelpMessage = false
    
    // Animation states for selected books
    @State private var bookScales: [UUID: CGFloat] = [:]
    @State private var bookRotations: [UUID: Double] = [:]

    // NEW: holds the book being edited so we can present the preferences sheet
    @State private var editingBook: Book?   // <<< ADDED
    
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
                    // Auto-select newly added book
                    selectedBooks.insert(book.id)
                    bookOrder.append(book.id)
                    updateBookAnimationStates()
                    
                    // Show help message for first book
                    if bookOrder.count == 1 {
                        showHelpMessage = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showHelpMessage = false
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BetsPlaced"))) { _ in
            // Clear all selections after placing bets
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedBooks.removeAll()
                bookOrder.removeAll()
                showHelpMessage = false
                updateBookAnimationStates()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveBets"))) { _ in
            shouldNavigateToActiveBets = true
        }
        // NEW: preferences sheet driven by the tapped row’s book
        .sheet(item: $editingBook) { initial in    // <<< ADDED
            QuickPageSetupView(
                book: Binding(
                    get: { initial },
                    set: { updated in editingBook = updated }
                ),
                onSave: { final in
                    if let idx = books.firstIndex(where: { $0.id == final.id }) {
                        books[idx] = final
                    }
                    editingBook = nil
                }
            )
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            bookshelfSection
            bettingRowsSection
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

                Text(headerSubtitle)
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
    
    private var headerSubtitle: String {
        if books.isEmpty {
            return "Add books to get started"
        } else if selectedBooks.isEmpty {
            return "Tap books to create your ReadSlip"
        } else if selectedBooks.count == 1 {
            return "1 book selected"
        } else {
            return "\(selectedBooks.count) books selected"
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
            HStack(spacing: 4) {
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
                .scaleEffect(bookScales[book.id] ?? 1.0)
                .rotation3DEffect(
                    .degrees(bookRotations[book.id] ?? 0.0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .zIndex(selectedBooks.contains(book.id) ? 1.0 : 0.0)
                .overlay(
                    // Selection indicator
                    selectedBooks.contains(book.id) ?
                    VStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.goodreadsBrown)
                            .background(Circle().fill(Color.white))
                            .font(.system(size: 16))
                    }
                    .padding(.bottom, 4)
                    : nil
                )
                .onTapGesture {
                    toggleBookSelection(book)
                }
        }
    }
    
    private func toggleBookSelection(_ book: Book) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if readSlipViewModel.hasActiveBets(for: book.id) {
                // Navigate to active bets if book has active bets
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToActiveBets"), object: nil)
            } else if selectedBooks.contains(book.id) {
                // Deselect
                selectedBooks.remove(book.id)
                bookOrder.removeAll { $0 == book.id }
            } else {
                // Select
                selectedBooks.insert(book.id)
                bookOrder.append(book.id)
                
                // Show help for first selection
                if bookOrder.count == 1 && !showHelpMessage {
                    showHelpMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showHelpMessage = false
                        }
                    }
                }
            }
            updateBookAnimationStates()
        }
    }
    
    private func updateBookAnimationStates() {
        for book in books {
            if selectedBooks.contains(book.id) {
                bookScales[book.id] = 1.06
                bookRotations[book.id] = 3.0
            } else {
                bookScales[book.id] = 1.0
                bookRotations[book.id] = 0.0
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
                    .frame(width: 30, height: 155)
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

    // MARK: - Betting Rows Section
    private var bettingRowsSection: some View {
        VStack(spacing: 0) {
            // Help message
            if showHelpMessage && !selectedBooks.isEmpty {
                helpMessageView
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
            
            // Betting rows for selected books
            if !selectedBooks.isEmpty {
                VStack(spacing: 8) {
                    ForEach(bookOrder, id: \.self) { bookId in
                        if let book = books.first(where: { $0.id == bookId }) {
                            FanDuelParlayRowView(
                                book: book,
                                onClose: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedBooks.remove(bookId)
                                        bookOrder.removeAll { $0 == bookId }
                                        updateBookAnimationStates()
                                        
                                        if selectedBooks.isEmpty {
                                            showHelpMessage = false
                                        }
                                    }
                                },
                                onBookUpdated: { updatedBook in
                                    if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
                                        books[index] = updatedBook
                                    }
                                },
                                onNavigateToActiveBets: {
                                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToActiveBets"), object: nil)
                                    
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedBooks.removeAll()
                                        bookOrder.removeAll()
                                        showHelpMessage = false
                                        updateBookAnimationStates()
                                    }
                                },
                                onEditPreferences: {
                                    // CHANGED: open the QuickPageSetupView for this specific book
                                    if let bookToEdit = books.first(where: { $0.id == bookId }) {
                                        editingBook = bookToEdit     // <<< CHANGED
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, showHelpMessage ? 8 : 16)
            } else if books.isEmpty {
                emptyState
            } else {
                placeholderState
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var helpMessageView: some View {
        Text("Pick how many days to finish each book and place your bets!")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.goodreadsAccent)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
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
            Text("Tap books to add them to your ReadSlip")
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
