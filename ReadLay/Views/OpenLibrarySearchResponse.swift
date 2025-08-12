//
//  OpenLibrarySearchResponse.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import Foundation

struct OpenLibrarySearchResponse: Codable {
    let docs: [OpenLibraryBook]
}

struct OpenLibraryBook: Codable, Identifiable {
    let key: String
    let title: String
    let authorName: [String]?
    let numberOfPagesMedian: Int?
    let coverI: Int?
    let isbn: [String]?
    let firstPublishYear: Int?
    let subject: [String]?

    var id: String { key }

    var coverURL: String? {
        if let coverId = coverI {
            return "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        }
        return nil
    }

    var mediumCoverURL: String? {
        if let coverId = coverI {
            return "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
        }
        return nil
    }

    var author: String? {
        return authorName?.first
    }

    var pageCount: Int {
        return numberOfPagesMedian ?? 250 // Default fallback
    }
}

// MARK: - ISBN-specific response model
struct OpenLibraryISBNResponse: Codable {
    let key: String
    let title: String
    let authors: [AuthorReference]?
    let numberOfPages: Int?
    let covers: [Int]?
    let isbn10: [String]?
    let isbn13: [String]?
    let publishDate: String?
    let subjects: [String]?

    struct AuthorReference: Codable {
        let key: String
    }

    func toOpenLibraryBook() -> OpenLibraryBook {
        return OpenLibraryBook(
            key: key,
            title: title,
            authorName: nil, // We'd need to fetch author details separately
            numberOfPagesMedian: numberOfPages,
            coverI: covers?.first,
            isbn: isbn13 ?? isbn10,
            firstPublishYear: nil,
            subject: subjects
        )
    }
}

class OpenLibraryAPI: ObservableObject {
    static let shared = OpenLibraryAPI()

    private let baseURL = "https://openlibrary.org/search.json"

    func searchBooks(query: String) async throws -> [OpenLibraryBook] {
        guard !query.isEmpty else { return [] }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?q=\(encodedQuery)&limit=15&fields=key,title,authorName,numberOfPagesMedian,coverI,isbn,firstPublishYear,subject"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)

        // Filter out books without covers or page counts for better results
        return response.docs.filter { book in
            book.coverI != nil && book.numberOfPagesMedian != nil && book.numberOfPagesMedian! > 50
        }
    }

    // MARK: - ISBN Search Method
    func searchByISBN(isbn: String) async throws -> OpenLibraryBook? {
        let cleanedISBN = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard !cleanedISBN.isEmpty else { return nil }

        // Open Library has a specific ISBN endpoint
        let urlString = "https://openlibrary.org/isbn/\(cleanedISBN).json"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let book = try JSONDecoder().decode(OpenLibraryISBNResponse.self, from: data)
            return book.toOpenLibraryBook()
        } catch {
            // If direct ISBN lookup fails, try search approach
            let searchURLString = "\(baseURL)?q=isbn:\(cleanedISBN)&fields=key,title,authorName,numberOfPagesMedian,coverI,isbn,firstPublishYear,subject"

            guard let searchURL = URL(string: searchURLString) else {
                throw URLError(.badURL)
            }

            let (searchData, _) = try await URLSession.shared.data(from: searchURL)
            let searchResponse = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: searchData)

            return searchResponse.docs.first
        }
    }
}
