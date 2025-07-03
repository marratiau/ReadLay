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
}