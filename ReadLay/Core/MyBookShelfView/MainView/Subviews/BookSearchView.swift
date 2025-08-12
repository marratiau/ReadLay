//
//  BookSearchView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//
//  BookSearchView.swift - UPDATED WITH ISBN LOOKUP
//  Enhanced with ISBN scanning and lookup functionality

import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var openLibraryResults: [OpenLibraryBook] = []
    @State private var googleBooksResults: [GoogleBook] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var showingManualEntry = false
    @State private var showingISBNLookup = false // ADDED: ISBN lookup state
    let onBookSelected: (Book) -> Void

    private var allResults: [SearchResult] {
        var results: [SearchResult] = []

        // Add Open Library results
        results.append(contentsOf: openLibraryResults.map { SearchResult.openLibrary($0) })

        // Add Google Books results
        results.append(contentsOf: googleBooksResults.map { SearchResult.googleBooks($0) })

        // Remove duplicates based on title similarity
        return results.removingDuplicates()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                enhancedSearchBarSection // UPDATED: Enhanced search bar with ISBN option
                contentSection
            }
            .background(backgroundGradient)
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.goodreadsAccent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manual Entry") {
                        showingManualEntry = true
                    }
                    .foregroundColor(.goodreadsBrown)
                    .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBookEntryView { book in
                onBookSelected(book)
                dismiss()
            }
        }
        // ADDED: ISBN lookup sheet
        .sheet(isPresented: $showingISBNLookup) {
            ISBNLookupView { book in
                onBookSelected(book)
                dismiss()
            }
        }
    }

    // UPDATED: Enhanced search bar with ISBN option
    private var enhancedSearchBarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.goodreadsAccent)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search for books...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(.goodreadsBrown)
                    .onSubmit {
                        searchBooks()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        openLibraryResults = []
                        googleBooksResults = []
                        hasSearched = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.goodreadsAccent.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsBeige)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                    )
            )

            // ADDED: Search options
            HStack(spacing: 8) {
                Button(action: {
                    showingISBNLookup = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 14, weight: .medium))
                        Text("ISBN Lookup")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.goodreadsBrown)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.goodreadsWarm)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("Manual Entry")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.goodreadsBrown)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.goodreadsWarm)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var contentSection: some View {
        if isSearching {
            searchingView
        } else if hasSearched && allResults.isEmpty {
            noResultsView
        } else if !allResults.isEmpty {
            resultsView
        } else {
            enhancedEmptyStateView // UPDATED: Enhanced empty state
        }
    }

    private var searchingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching multiple databases...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsAccent)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            Text("No books found")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            Text("Try a different search, use ISBN lookup, or manual entry")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: {
                    showingISBNLookup = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 16, weight: .medium))
                        Text("ISBN Lookup")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.goodreadsBrown)
                    )
                }

                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Manual Entry")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.goodreadsBrown)
                    )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(allResults.enumerated()), id: \.element.id) { _, result in
                    SearchResultRowView(
                        result: result,
                        onSelect: {
                            let book = result.toBook()
                            onBookSelected(book)
                            dismiss()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // UPDATED: Enhanced empty state with search options
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))

            VStack(spacing: 8) {
                Text("Find Your Books")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.goodreadsBrown)

                Text("Search by title, author, or find exact editions with ISBN")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                Text("Search Options:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                VStack(spacing: 12) {
                    SearchOptionCard(
                        icon: "magnifyingglass",
                        title: "Title/Author Search",
                        description: "Search across multiple book databases",
                        color: .blue
                    )

                    SearchOptionCard(
                        icon: "barcode.viewfinder",
                        title: "ISBN Lookup",
                        description: "Find exact edition by scanning or entering ISBN",
                        color: .green
                    )

                    SearchOptionCard(
                        icon: "plus.circle",
                        title: "Manual Entry",
                        description: "Add any book with custom details",
                        color: .orange
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
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

    private func searchBooks() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isSearching = true
        hasSearched = true

        Task {
            async let openLibraryTask = searchOpenLibrary()
            async let googleBooksTask = searchGoogleBooks()

            _ = await (openLibraryTask, googleBooksTask)

            await MainActor.run {
                self.isSearching = false
            }
        }
    }

    private func searchOpenLibrary() async {
        do {
            let results = try await OpenLibraryAPI.shared.searchBooks(query: searchText)
            await MainActor.run {
                self.openLibraryResults = results
            }
        } catch {
            print("Open Library search error: \(error)")
        }
    }

    private func searchGoogleBooks() async {
        do {
            let results = try await GoogleBooksAPI.shared.searchBooks(query: searchText)
            await MainActor.run {
                self.googleBooksResults = results
            }
        } catch {
            print("Google Books search error: \(error)")
        }
    }
}

// MARK: - Search Option Card
struct SearchOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Keep existing SearchResult, SearchResultRowView, and extension implementations...

// MARK: - Search Result Types
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

    func toBook() -> Book {
        let spineColors: [Color] = [
            Color(red: 0.2, green: 0.4, blue: 0.8),
            Color(red: 0.1, green: 0.7, blue: 0.3),
            Color(red: 0.9, green: 0.5, blue: 0.1),
            Color(red: 0.6, green: 0.2, blue: 0.8),
            Color(red: 0.8, green: 0.1, blue: 0.1),
            Color(red: 0.1, green: 0.6, blue: 0.7),
            Color(red: 0.7, green: 0.6, blue: 0.1),
            Color(red: 0.3, green: 0.1, blue: 0.6)
        ]

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
            coverImageName: nil,
            coverImageURL: coverURL,
            googleBooksId: id,
            spineColor: spineColors.randomElement() ?? Color.goodreadsBrown,
            difficulty: difficulty
        )
    }
}

struct SearchResultRowView: View {
    let result: SearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Book cover
                AsyncImage(url: URL(string: result.coverURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.goodreadsBeige)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.title2)
                                .foregroundColor(.goodreadsAccent)
                        )
                }
                .frame(width: 60, height: 85)
                .cornerRadius(8)

                // Book details
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let author = result.author {
                        Text(author)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                            .lineLimit(1)
                    }

                    HStack(spacing: 8) {
                        Text("\(result.pageCount) pages")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))

                        Text(result.source)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(result.source == "Open Library" ? Color.green.opacity(0.7) : Color.blue.opacity(0.7))
                            )
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.goodreadsBrown)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper extension to remove duplicate search results
extension Array where Element == SearchResult {
    func removingDuplicates() -> [SearchResult] {
        var seen = Set<String>()
        return self.filter { result in
            let key = result.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return seen.insert(key).inserted
        }
    }
}
