//
//  ReadingPreferences.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//

//
//  ReadingPreferences.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//
//  NEW FILE - Reading preferences and page tracking system

import Foundation

// MARK: - Reading Preferences
struct ReadingPreferences: Codable {
    // Simple toggles for quick implementation
    var includeFrontMatter: Bool = true      // Preface, prologue, etc.
    var includeBackMatter: Bool = true       // Epilogue, appendix, etc.

    // Estimated pages (user can adjust)
    var estimatedFrontMatterPages: Int = 10
    var estimatedBackMatterPages: Int = 20

    // Custom range override
    var customStartPage: Int?
    var customEndPage: Int?

    // Chapter preferences (for books with chapter support)
    var estimatedFrontMatterChapters: Int = 1
    var estimatedBackMatterChapters: Int = 1
    var customStartChapter: Int?
    var customEndChapter: Int?

    // Reading style preference
    var pageCountingStyle: PageCountingStyle = .inclusive

    // Goal unit preference
    var preferredGoalUnit: GoalUnit = .pages

    enum GoalUnit: String, Codable {
        case pages = "pages"
        case chapters = "chapters"

        var displayName: String {
            switch self {
            case .pages: return "Pages"
            case .chapters: return "Chapters"
            }
        }
    }

    enum PageCountingStyle: String, CaseIterable, Codable {
        case inclusive = "inclusive"         // Count everything
        case mainOnly = "main_only"         // Skip front/back matter
        case custom = "custom"              // User-defined range

        var displayName: String {
            switch self {
            case .inclusive: return "Include Everything"
            case .mainOnly: return "Main Story Only"
            case .custom: return "Custom Range"
            }
        }

        var description: String {
            switch self {
            case .inclusive: return "Count all pages including preface, epilogue, etc."
            case .mainOnly: return "Count only the main story content"
            case .custom: return "Set custom start and end pages"
            }
        }

        var icon: String {
            switch self {
            case .inclusive: return "book.closed"
            case .mainOnly: return "book"
            case .custom: return "slider.horizontal.3"
            }
        }
    }

    static func `default`(for bookId: UUID, totalPages: Int, totalChapters: Int? = nil) -> ReadingPreferences {
        var prefs = ReadingPreferences()

        // Smart defaults based on book length
        if totalPages > 300 {
            prefs.estimatedFrontMatterPages = 15
            prefs.estimatedBackMatterPages = 25
        } else if totalPages > 150 {
            prefs.estimatedFrontMatterPages = 10
            prefs.estimatedBackMatterPages = 15
        } else {
            prefs.estimatedFrontMatterPages = 5
            prefs.estimatedBackMatterPages = 10
        }

        // Smart defaults for chapters if available
        if let chapters = totalChapters, chapters > 0 {
            if chapters > 40 {
                prefs.estimatedFrontMatterChapters = 2
                prefs.estimatedBackMatterChapters = 2
            } else if chapters > 20 {
                prefs.estimatedFrontMatterChapters = 1
                prefs.estimatedBackMatterChapters = 1
            } else {
                prefs.estimatedFrontMatterChapters = 1
                prefs.estimatedBackMatterChapters = 0
            }
        }

        return prefs
    }

    // Persistence methods

    /// Save preferences for a specific book and user
    func save(for bookId: UUID, userId: UUID) {
        if let data = try? JSONEncoder().encode(self) {
            let key = "reading_prefs_\(userId)_\(bookId)"
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Load preferences for a specific book and user
    static func load(for bookId: UUID, userId: UUID) -> ReadingPreferences? {
        let key = "reading_prefs_\(userId)_\(bookId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let prefs = try? JSONDecoder().decode(ReadingPreferences.self, from: data) else {
            return nil
        }
        return prefs
    }

    // MARK: - Legacy Methods (for backward compatibility during migration)

    /// Legacy save method without userId - will be removed after full migration
    func save(for bookId: UUID) {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "reading_prefs_\(bookId)")
        }
    }

    /// Legacy load method without userId - will be removed after full migration
    static func load(for bookId: UUID) -> ReadingPreferences? {
        guard let data = UserDefaults.standard.data(forKey: "reading_prefs_\(bookId)"),
              let prefs = try? JSONDecoder().decode(ReadingPreferences.self, from: data) else {
            return nil
        }
        return prefs
    }
}
