//
//  BookSearchView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//  Performance optimized version - WITH PAGE SETUP INTEGRATION
//

import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var openLibraryResults: [OpenLibraryBook] = []
    @State private var googleBooksResults: [GoogleBook] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var showingManualEntry = false
    @State private var showingISBNLookup = false
    @State private var errorMessage: String? = nil
    @State private var selectedBookForSetup: Book?
    @State private var showingPageSetup = false
    @State private var cachedResults: [SearchResult] = []
    @State private var lastSearchText: String = ""
    @FocusState private var isSearchFocused: Bool

    let currentBookCount: Int
    let onBookSelected: (Book) -> Void
    
    private var allResults: [SearchResult] {
        if lastSearchText == searchText && !cachedResults.isEmpty {
            return cachedResults
        }
        var results: [SearchResult] = []
        results.append(contentsOf: openLibraryResults.map { SearchResult.openLibrary($0) })
        results.append(contentsOf: googleBooksResults.map { SearchResult.googleBooks($0) })
        let finalResults = results.removingDuplicates()
        DispatchQueue.main.async {
            self.cachedResults = finalResults
            self.lastSearchText = self.searchText
        }
        return finalResults
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with back button and search bar
            customHeader

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.nunitoMedium(size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }

            contentSection
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color.readlayPaleMint.opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingManualEntry) {
            ManualBookEntryView(currentBookCount: currentBookCount) { book in
                selectedBookForSetup = book
                showingPageSetup = true
                showingManualEntry = false
            }
        }
        .sheet(isPresented: $showingISBNLookup) {
            ISBNLookupView(currentBookCount: currentBookCount) { book in
                selectedBookForSetup = book
                showingPageSetup = true
                showingISBNLookup = false
            }
        }
        .sheet(item: $selectedBookForSetup) { initial in
            QuickPageSetupView(
                book: Binding(
                    get: { initial },
                    set: { updated in
                        selectedBookForSetup = updated
                    }
                ),
                onSave: { finalBook in
                    onBookSelected(finalBook)
                    dismiss()
                }
            )
        }

    }
    
    // Custom header with back button and search bar
    private var customHeader: some View {
        VStack(spacing: 16) {
            // Search bar with back button
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.readlayDarkBrown)
                        .frame(width: 44, height: 44)
                }

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.readlayTan.opacity(0.6))
                        .font(.system(size: 18))

                    TextField("Search for books...", text: $searchText)
                        .font(.nunitoMedium(size: 16))
                        .foregroundColor(.readlayDarkBrown)
                        .submitLabel(.search)
                        .focused($isSearchFocused)
                        .onSubmit {
                            isSearchFocused = false
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            clearResults()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.readlayTan.opacity(0.5))
                                .font(.system(size: 20))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .readlayDarkBrown.opacity(0.08), radius: 8, x: 0, y: 2)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .background(Color.white)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if isSearching {
            searchingView
        } else if hasSearched && allResults.isEmpty {
            noResultsView
        } else if !allResults.isEmpty {
            optimizedResultsView
        } else {
            simpleEmptyState
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(.readlayMediumBlue)
            Text("Searching...")
                .font(.nunitoMedium(size: 17))
                .foregroundColor(.readlayTan)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundColor(.readlayTan.opacity(0.4))
            Text("No books found")
                .font(.nunitoBold(size: 22))
                .foregroundColor(.readlayDarkBrown)
            Text("Try a different search")
                .font(.nunitoMedium(size: 15))
                .foregroundColor(.readlayTan.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var optimizedResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(allResults, id: \.id) { result in
                    SimplifiedResultRow(
                        result: result,
                        onSelect: {
                            let book = result.toBook(bookIndex: currentBookCount)
                            selectedBookForSetup = book
                            showingPageSetup = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    private var simpleEmptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 56))
                    .foregroundColor(.readlayTan.opacity(0.4))

                Text("Find Your Next Book")
                    .font(.nunitoBold(size: 24))
                    .foregroundColor(.readlayDarkBrown)

                Text("Search by title or author above")
                    .font(.nunitoMedium(size: 15))
                    .foregroundColor(.readlayTan.opacity(0.8))
            }

            VStack(spacing: 16) {
                // ISBN Scan button - centered, larger
                Button(action: {
                    showingISBNLookup = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 22, weight: .semibold))
                        Text("Scan ISBN")
                            .font(.nunitoBold(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.readlayMediumBlue)
                            .shadow(color: .readlayMediumBlue.opacity(0.3), radius: 12, x: 0, y: 4)
                    )
                }

                // Manual Entry button - centered, larger
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .semibold))
                        Text("Enter Manually")
                            .font(.nunitoBold(size: 18))
                    }
                    .foregroundColor(.readlayMediumBlue)
                    .frame(maxWidth: 280)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.readlayMediumBlue, lineWidth: 2)
                            )
                            .shadow(color: .readlayDarkBrown.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private func clearResults() {
        openLibraryResults = []
        googleBooksResults = []
        cachedResults = []
        lastSearchText = ""
        hasSearched = false
        errorMessage = nil
    }
    
    private func performSearch() {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "Please enter a search term"
            return
        }
        searchBooks()
    }
    
    private func searchBooks() {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        isSearching = true
        hasSearched = true
        cachedResults = []
        errorMessage = nil
        Task {
            do {
                async let openLibraryTask = searchOpenLibrary()
                async let googleBooksTask = searchGoogleBooks()
                let (openLibSuccess, googleSuccess) = await (openLibraryTask, googleBooksTask)
                await MainActor.run {
                    self.isSearching = false
                    if !openLibSuccess && !googleSuccess {
                        self.errorMessage = "Search failed. Please check your internet connection."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                    self.errorMessage = "Search error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func searchOpenLibrary() async -> Bool {
        do {
            let results = try await OpenLibraryAPI.shared.searchBooks(query: searchText)
            await MainActor.run {
                self.openLibraryResults = results
            }
            return true
        } catch {
            return false
        }
    }
    
    private func searchGoogleBooks() async -> Bool {
        do {
            let results = try await GoogleBooksAPI.shared.searchBooks(query: searchText)
            await MainActor.run {
                self.googleBooksResults = results
            }
            return true
        } catch {
            return false
        }
    }
}

struct SimplifiedResultRow: View {
    let result: SearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Book cover
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.readlayCream.opacity(0.3))
                    .frame(width: 56, height: 80)
                    .overlay(
                        Group {
                            if let url = result.coverURL {
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.readlayTan)
                                }
                            } else {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.readlayTan.opacity(0.5))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .readlayDarkBrown.opacity(0.08), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(result.title)
                        .font(.nunitoBold(size: 16))
                        .foregroundColor(.readlayDarkBrown)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let author = result.author {
                        Text(author)
                            .font(.nunitoMedium(size: 14))
                            .foregroundColor(.readlayTan)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text("\(result.pageCount) pages")
                            .font(.nunitoMedium(size: 12))
                            .foregroundColor(.readlayTan.opacity(0.7))

                        Text("•")
                            .foregroundColor(.readlayTan.opacity(0.4))

                        Text(result.source)
                            .font(.nunitoMedium(size: 12))
                            .foregroundColor(.readlayTan.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.readlayTan.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .readlayDarkBrown.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SearchResult: Identifiable {
    case openLibrary(OpenLibraryBook)
    case googleBooks(GoogleBook)
    
    var id: String {
        switch self {
        case .openLibrary(let book):
            return "ol_\(book.id)"
        case .googleBooks(let book):
            return "gb_\(book.id)"
        }
    }
    
    var title: String {
        switch self {
        case .openLibrary(let book):
            return book.title
        case .googleBooks(let book):
            return book.volumeInfo.title
        }
    }
    
    var author: String? {
        switch self {
        case .openLibrary(let book):
            return book.author
        case .googleBooks(let book):
            return book.volumeInfo.authors?.first
        }
    }
    
    var pageCount: Int {
        switch self {
        case .openLibrary(let book):
            return book.pageCount
        case .googleBooks(let book):
            return book.volumeInfo.pageCount ?? 250
        }
    }
    
    var coverURL: String? {
        switch self {
        case .openLibrary(let book):
            return book.mediumCoverURL
        case .googleBooks(let book):
            return book.volumeInfo.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://")
        }
    }
    
    var source: String {
        switch self {
        case .openLibrary:
            return "Open Library"
        case .googleBooks:
            return "Google Books"
        }
    }
    
    func toBook(bookIndex: Int = 0) -> Book {
        let difficulty: Book.ReadingDifficulty
        if pageCount < 250 {
            difficulty = .easy
        } else if pageCount < 400 {
            difficulty = .medium
        } else {
            difficulty = .hard
        }
        return Book(
            id: UUID(),
            title: title,
            author: author,
            totalPages: pageCount,
            totalChapters: nil,  // TODO: Extract from API if available
            coverImageName: nil,
            coverImageURL: coverURL,
            googleBooksId: id,
            spineColor: Color.readlaySpineColor(index: bookIndex),
            difficulty: difficulty
        )
    }
}

extension Array where Element == SearchResult {
    func removingDuplicates() -> [SearchResult] {
        var seen = Set<String>()
        return self.filter { result in
            let key = result.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return seen.insert(key).inserted
        }
    }
}
