//
//  GoogleBooksResponse.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import Foundation

struct GoogleBooksResponse: Codable {
    let items: [GoogleBook]?
}

struct GoogleBook: Codable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let pageCount: Int?
    let imageLinks: ImageLinks?
    let description: String?
    let categories: [String]?
}

struct ImageLinks: Codable {
    let thumbnail: String?
    let smallThumbnail: String?
}

class GoogleBooksAPI: ObservableObject {
    static let shared = GoogleBooksAPI()

    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    func searchBooks(query: String) async throws -> [GoogleBook] {
        guard !query.isEmpty else { return [] }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?q=\(encodedQuery)&maxResults=10"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return response.items ?? []
    }

    // MARK: - ISBN Search Method
    func searchByISBN(isbn: String) async throws -> GoogleBook? {
        let cleanedISBN = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        guard !cleanedISBN.isEmpty else { return nil }

        let urlString = "\(baseURL)?q=isbn:\(cleanedISBN)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)

        return response.items?.first
    }
}
