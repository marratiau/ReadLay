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
    
    @State private var selectedBooks: Set<UUID> = []
    @State private var bookOrder: [UUID] = []
    @State private var showHelpMessage = false
    
    @State private var bookScales: [UUID: CGFloat] = [:]
    @State private var bookRotations: [UUID: Double] = [:]
    @State private var editingBook: Book?
    
    // iOS 17 FIX: Complete view recreation
    @State private var viewID = UUID()
    
    init(readSlipViewModel: ReadSlipViewModel) {
        self.readSlipViewModel = readSlipViewModel
    }

    var body: some View {
        // iOS 17 FIX: Separate background and content completely
        ZStack {
            // Background layer - Fresh ReadLay palette
            Color.white
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.readlayPaleMint.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .edgesIgnoringSafeArea(.all) // Use older API that works better
            
            // Content layer
            VStack(spacing: 0) {
                headerSection
                bookshelfSection
                bettingRowsSection
                Spacer()
                bottomPadding
            }
            .id(viewID) // Force complete recreation when ID changes
            
            // ReadSlip overlay
            VStack {
                Spacer()
                ReadSlipView(viewModel: readSlipViewModel)
            }
        }
        .sheet(isPresented: $showingBookSearch) {
            BookSearchView(currentBookCount: books.count) { book in
                books.append(book)
                selectedBooks.insert(book.id)
                bookOrder.append(book.id)
                updateBookAnimationStates()

                if bookOrder.count == 1 {
                    showHelpMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        showHelpMessage = false
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BetsPlaced"))) { _ in
            // iOS 17 FIX: Recreate view after bets placed
            recreateView()
            
            selectedBooks.removeAll()
            bookOrder.removeAll()
            showHelpMessage = false
            updateBookAnimationStates()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveBets"))) { _ in
            shouldNavigateToActiveBets = true
        }
        // iOS 17 FIX: Use fullScreenCover instead of sheet for preferences
        .fullScreenCover(item: $editingBook) { bookToEdit in
            NavigationView {
                QuickPageSetupView(
                    book: Binding(
                        get: {
                            books.first(where: { $0.id == bookToEdit.id }) ?? bookToEdit
                        },
                        set: { updatedBook in
                            if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
                                books[index] = updatedBook
                            }
                        }
                    ),
                    onSave: { finalBook in
                        if let index = books.firstIndex(where: { $0.id == finalBook.id }) {
                            books[index] = finalBook
                        }
                        editingBook = nil
                        // iOS 17 FIX: Recreate view after save
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            recreateView()
                        }
                    }
                )
                .navigationBarItems(
                    leading: Button("Cancel") {
                        editingBook = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            recreateView()
                        }
                    }
                    .foregroundColor(.goodreadsAccent)
                )
            }
        }
    }
    
    // iOS 17 FIX: Force complete view recreation
    private func recreateView() {
        withAnimation(.none) {
            viewID = UUID()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("My Bookshelf")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.readlayDarkBrown)

                Text(headerSubtitle)
                    .font(.nunitoMedium(size: 16))
                    .foregroundColor(.readlayTan)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)

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
            return "1 book selected • Ready to place bet"
        } else {
            return "\(selectedBooks.count) books selected • Parlay ready"
        }
    }

    private var balanceSection: some View {
        VStack(spacing: 4) {
            Text("Balance")
                .font(.nunitoBold(size: 16))
                .foregroundColor(.readlayDarkBrown)

            Text("$\(readSlipViewModel.currentBalance, specifier: "%.2f")")
                .font(.nunitoSemiBold(size: 22))
                .foregroundColor(.readlayDarkBrown)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Bookshelf Section
    private var bookshelfSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("MY LIBRARY")
                .font(.nunitoSemiBold(size: 11))
                .foregroundColor(.readlayTan.opacity(0.7))
                .tracking(1.2)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            // Books horizontal scroll
            booksScrollView
                .padding(.bottom, 16)
        }
    }

    private var booksScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                existingBooks
                addBookButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    private var existingBooks: some View {
        ForEach(books) { book in
            SpineView(book: book)
                .scaleEffect(bookScales[book.id] ?? 1.0)
                .zIndex(selectedBooks.contains(book.id) ? 1.0 : 0.0)
                .overlay(
                    selectedBooks.contains(book.id) ?
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.readlayDarkBrown)
                                .background(Circle().fill(Color.white))
                                .font(.system(size: 16))
                        }
                        Spacer()
                    }
                    .padding(.trailing, 4)
                    .padding(.top, 4)
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
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToActiveBets"), object: nil)
            } else if selectedBooks.contains(book.id) {
                selectedBooks.remove(book.id)
                bookOrder.removeAll { $0 == book.id }
            } else {
                selectedBooks.insert(book.id)
                bookOrder.append(book.id)
                
                if bookOrder.count == 1 && !showHelpMessage {
                    showHelpMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        showHelpMessage = false
                    }
                }
            }
            updateBookAnimationStates()
        }
    }
    
    private func updateBookAnimationStates() {
        for book in books {
            if selectedBooks.contains(book.id) {
                bookScales[book.id] = 1.08  // Slightly more prominent selection
            } else {
                bookScales[book.id] = 1.0
            }
        }
    }

    private var addBookButton: some View {
        Button(action: {
            showingBookSearch = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.readlayCream.opacity(0.2))
                    .frame(width: 36, height: 155)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.readlayTan.opacity(0.4), lineWidth: 1)
                    )

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.readlayTan)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Betting Rows Section
    private var bettingRowsSection: some View {
        VStack(spacing: 0) {
            if showHelpMessage && !selectedBooks.isEmpty {
                helpMessageView
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }

            if !selectedBooks.isEmpty {
                // Section header for betting rows
                HStack {
                    Text("READY TO BET")
                        .font(.nunitoSemiBold(size: 11))
                        .foregroundColor(.readlayTan.opacity(0.7))
                        .tracking(1.2)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)

                VStack(spacing: 12) {
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
                                    if let bookToEdit = books.first(where: { $0.id == bookId }) {
                                        editingBook = bookToEdit
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
                .padding(.horizontal, 16)
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
            .font(.nunitoMedium(size: 14))
            .foregroundColor(.readlayTan)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.readlayTan.opacity(0.5))

            Text("Your Library Awaits")
                .font(.nunitoBold(size: 20))
                .foregroundColor(.readlayDarkBrown)

            Text("Add your first book to start tracking your reading goals")
                .font(.nunitoMedium(size: 16))
                .foregroundColor(.readlayTan)
                .multilineTextAlignment(.center)

            addBookEmptyStateButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
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
                    .font(.nunitoBold(size: 18))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.readlayMediumBlue)
            )
        }
        .padding(.top, 8)
    }

    private var placeholderState: some View {
        VStack(spacing: 6) {
            Text("Select books from your library to create bets")
                .font(.nunitoMedium(size: 16))
                .foregroundColor(.readlayTan.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Supporting Views
    private var bottomPadding: some View {
        Group {
            if readSlipViewModel.betSlip.totalBets > 0 {
                Color.clear.frame(height: readSlipViewModel.betSlip.isExpanded ? 180 : 60)
            }
        }
    }
}

#Preview {
    MyBookshelfView(readSlipViewModel: ReadSlipViewModel())
}
