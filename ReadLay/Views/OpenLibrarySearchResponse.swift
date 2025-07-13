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
    let author_name: [String]?
    let number_of_pages_median: Int?
    let cover_i: Int?
    let isbn: [String]?
    let first_publish_year: Int?
    let subject: [String]?
    
    var id: String { key }
    
    var coverURL: String? {
        if let coverId = cover_i {
            return "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        }
        return nil
    }
    
    var mediumCoverURL: String? {
        if let coverId = cover_i {
            return "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
        }
        return nil
    }
    
    var author: String? {
        return author_name?.first
    }
    
    var pageCount: Int {
        return number_of_pages_median ?? 250 // Default fallback
    }
}

// MARK: - ISBN-specific response model
struct OpenLibraryISBNResponse: Codable {
    let key: String
    let title: String
    let authors: [AuthorReference]?
    let number_of_pages: Int?
    let covers: [Int]?
    let isbn_10: [String]?
    let isbn_13: [String]?
    let publish_date: String?
    let subjects: [String]?
    
    struct AuthorReference: Codable {
        let key: String
    }
    
    func toOpenLibraryBook() -> OpenLibraryBook {
        return OpenLibraryBook(
            key: key,
            title: title,
            author_name: nil, // We'd need to fetch author details separately
            number_of_pages_median: number_of_pages,
            cover_i: covers?.first,
            isbn: isbn_13 ?? isbn_10,
            first_publish_year: nil,
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
        let urlString = "\(baseURL)?q=\(encodedQuery)&limit=15&fields=key,title,author_name,number_of_pages_median,cover_i,isbn,first_publish_year,subject"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        
        // Filter out books without covers or page counts for better results
        return response.docs.filter { book in
            book.cover_i != nil && book.number_of_pages_median != nil && book.number_of_pages_median! > 50
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
            let searchURLString = "\(baseURL)?q=isbn:\(cleanedISBN)&fields=key,title,author_name,number_of_pages_median,cover_i,isbn,first_publish_year,subject"
            
            guard let searchURL = URL(string: searchURLString) else {
                throw URLError(.badURL)
            }
            
            let (searchData, _) = try await URLSession.shared.data(from: searchURL)
            let searchResponse = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: searchData)
            
            return searchResponse.docs.first
        }
    }
}
