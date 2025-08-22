//
//  BookSearchView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.

//  Performance optimized version
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
    let onBookSelected: (Book) -> Void

    // OPTIMIZED: Cache results to avoid recalculation
    @State private var cachedResults: [SearchResult] = []
    
    private var allResults: [SearchResult] {
        // Only recalculate if cache is empty
        if !cachedResults.isEmpty {
            return cachedResults
        }
        
        var results: [SearchResult] = []
        results.append(contentsOf: openLibraryResults.map { SearchResult.openLibrary($0) })
        results.append(contentsOf: googleBooksResults.map { SearchResult.googleBooks($0) })
        
        // Store in cache
        DispatchQueue.main.async {
            self.cachedResults = results.removingDuplicates()
        }
        
        return results.removingDuplicates()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                simplifiedSearchBar  // SIMPLIFIED: Reduced complexity
                contentSection
            }
            .background(Color.goodreadsBeige)  // SIMPLIFIED: Static color instead of gradient
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
                    Button("Manual") {
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
        .sheet(isPresented: $showingISBNLookup) {
            ISBNLookupView { book in
                onBookSelected(book)
                dismiss()
            }
        }
    }

    // SIMPLIFIED: Reduced visual complexity
    private var simplifiedSearchBar: some View {
        VStack(spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.goodreadsAccent)
                    .font(.system(size: 16))

                TextField("Search for books...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(.goodreadsBrown)
                    .submitLabel(.search)
                    .onSubmit {
                        searchBooks()
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.goodreadsAccent.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(Color.goodreadsBeige)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
            )

            // Quick actions - SIMPLIFIED design
            HStack(spacing: 8) {
                Button(action: {
                    showingISBNLookup = true
                }) {
                    Label("ISBN", systemImage: "barcode.viewfinder")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.goodreadsBrown)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.goodreadsWarm)
                        .cornerRadius(6)
                }

                Button(action: {
                    showingManualEntry = true
                }) {
                    Label("Manual", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.goodreadsBrown)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.goodreadsWarm)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var contentSection: some View {
        if isSearching {
            searchingView
        } else if hasSearched && allResults.isEmpty {
            noResultsView
        } else if !allResults.isEmpty {
            optimizedResultsView  // OPTIMIZED: List instead of ScrollView
        } else {
            simpleEmptyState  // SIMPLIFIED: Reduced complexity
        }
    }

    private var searchingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
            Text("Searching...")
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
            Text("Try a different search")
                .font(.system(size: 14))
                .foregroundColor(.goodreadsAccent)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // OPTIMIZED: Use List for better performance with large datasets
    private var optimizedResultsView: some View {
        List(allResults, id: \.id) { result in
            SimplifiedResultRow(
                result: result,
                onSelect: {
                    let book = result.toBook()
                    onBookSelected(book)
                    dismiss()
                }
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // SIMPLIFIED: Much simpler empty state
    private var simpleEmptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            
            Text("Search for books")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            
            Text("Enter title or author above")
                .font(.system(size: 14))
                .foregroundColor(.goodreadsAccent)
            Spacer()
        }
    }

    private func clearResults() {
        openLibraryResults = []
        googleBooksResults = []
        cachedResults = []
        hasSearched = false
    }

    private func searchBooks() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isSearching = true
        hasSearched = true
        cachedResults = []  // Clear cache before new search

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

// SIMPLIFIED: Lighter weight result row
struct SimplifiedResultRow: View {
    let result: SearchResult
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Simplified placeholder - no AsyncImage
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.goodreadsBeige)
                    .frame(width: 50, height: 70)
                    .overlay(
                        Group {
                            if let url = result.coverURL {
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "book.closed")
                                        .foregroundColor(.goodreadsAccent)
                                }
                            } else {
                                Image(systemName: "book.closed")
                                    .foregroundColor(.goodreadsAccent)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)

                    if let author = result.author {
                        Text(author)
                            .font(.system(size: 13))
                            .foregroundColor(.goodreadsAccent)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Text("\(result.pageCount) pages")
                            .font(.system(size: 11))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.goodreadsAccent.opacity(0.5))
                        
                        Text(result.source)
                            .font(.system(size: 11))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.goodreadsBrown)
            }
            .padding(12)
            .background(Color.goodreadsWarm)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Keep existing SearchResult enum and extensions...

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
