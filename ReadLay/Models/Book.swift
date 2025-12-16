//
//  Book.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//
import SwiftUI

struct Book: Identifiable, Hashable, Equatable {
    let id: UUID
    let title: String
    let author: String?
    let totalPages: Int
    let totalChapters: Int?  // Optional - not all books have this
    let coverImageName: String?
    let coverImageURL: String?
    let googleBooksId: String?
    let spineColor: Color
    let difficulty: ReadingDifficulty
    //let categories: [String]?  // New: From API
    //let firstPublishYear: Int?  // New: From Open Library for age-based difficulty
    
    // Fixed: Uncommented the preferencesCache since it's being used
    private static var preferencesCache: [UUID: ReadingPreferences] = [:]
    private static var effectiveTotalPagesCache: [UUID: Int] = [:]
    private static var readingStartPageCache: [UUID: Int] = [:]
    private static var readingEndPageCache: [UUID: Int] = [:]
    private static var hasCustomReadingPreferencesCache: [UUID: Bool] = [:]
    private static var readingPreferenceSummaryCache: [UUID: String] = [:]
    private static var oddsCache: [UUID: [(String, String)]] = [:]
    private static var journalOddsCache: [UUID: [(String, String)]] = [:]

    // Chapter support caches
    private static var effectiveTotalChaptersCache: [UUID: Int] = [:]
    private static var readingStartChapterCache: [UUID: Int] = [:]
    private static var readingEndChapterCache: [UUID: Int] = [:]
    private static var chapterOddsCache: [UUID: [(String, String)]] = [:]
    
    var readingPreferences: ReadingPreferences {
        get {
            // Check static cache first
            if let cached = Book.preferencesCache[id] {
                return cached
            }
            let prefs = ReadingPreferences.load(for: id) ?? ReadingPreferences.default(for: id, totalPages: totalPages)
            // Store in static cache
            Book.preferencesCache[id] = prefs
            return prefs
        }
        set {
            // Update static cache
            Book.preferencesCache[id] = newValue
            newValue.save(for: id)
        }
    }
    
    // ADDED: Missing computed properties that other files are using
    var readingStartPage: Int {
        if let cached = Book.readingStartPageCache[id] {
            return cached
        }
        let prefs = readingPreferences
        let result: Int
        
        switch prefs.pageCountingStyle {
        case .inclusive, .mainOnly:
            result = 1 + prefs.estimatedFrontMatterPages
        case .custom:
            result = prefs.customStartPage ?? 1
        }
        
        Book.readingStartPageCache[id] = result
        return result
    }
    
    var readingEndPage: Int {
        if let cached = Book.readingEndPageCache[id] {
            return cached
        }
        let prefs = readingPreferences
        let result: Int
        
        switch prefs.pageCountingStyle {
        case .inclusive:
            result = totalPages
        case .mainOnly:
            result = totalPages - prefs.estimatedBackMatterPages
        case .custom:
            result = prefs.customEndPage ?? totalPages
        }
        
        Book.readingEndPageCache[id] = result
        return result
    }

    // MARK: - Chapter Support

    var hasChapters: Bool {
        return totalChapters != nil && totalChapters! > 0
    }

    var effectiveTotalChapters: Int {
        if let cached = Book.effectiveTotalChaptersCache[id] {
            return cached
        }

        guard let totalChapters = totalChapters, totalChapters > 0 else {
            return 0
        }

        let prefs = readingPreferences
        let result: Int

        switch prefs.pageCountingStyle {
        case .inclusive:
            result = totalChapters
        case .mainOnly:
            result = max(0, totalChapters - prefs.estimatedFrontMatterChapters - prefs.estimatedBackMatterChapters)
        case .custom:
            // For custom, use chapter range if provided, otherwise estimate from page range
            if let startChapter = prefs.customStartChapter, let endChapter = prefs.customEndChapter {
                result = max(0, endChapter - startChapter + 1)
            } else {
                // Estimate chapters from page range
                let pagePercentage = Double(effectiveTotalPages) / Double(totalPages)
                result = Int(Double(totalChapters) * pagePercentage)
            }
        }

        Book.effectiveTotalChaptersCache[id] = result
        return result
    }

    var readingStartChapter: Int {
        if let cached = Book.readingStartChapterCache[id] {
            return cached
        }

        guard hasChapters else {
            return 1
        }

        let prefs = readingPreferences
        let result: Int

        switch prefs.pageCountingStyle {
        case .inclusive, .mainOnly:
            result = 1 + prefs.estimatedFrontMatterChapters
        case .custom:
            result = prefs.customStartChapter ?? 1
        }

        Book.readingStartChapterCache[id] = result
        return result
    }

    var readingEndChapter: Int {
        if let cached = Book.readingEndChapterCache[id] {
            return cached
        }

        guard let totalChapters = totalChapters, totalChapters > 0 else {
            return 1
        }

        let prefs = readingPreferences
        let result: Int

        switch prefs.pageCountingStyle {
        case .inclusive:
            result = totalChapters
        case .mainOnly:
            result = totalChapters - prefs.estimatedBackMatterChapters
        case .custom:
            result = prefs.customEndChapter ?? totalChapters
        }

        Book.readingEndChapterCache[id] = result
        return result
    }

    var chapterOdds: [(String, String)] {
        if let cached = Book.chapterOddsCache[id] {
            return cached
        }

        guard hasChapters else {
            return []
        }

        let effectiveChapters = effectiveTotalChapters
        guard effectiveChapters > 0 else {
            return []
        }

        // Generate standard options: 1, 2, 3 chapters per day
        let option1Days = effectiveChapters  // 1 chapter/day
        let option2Days = Int(ceil(Double(effectiveChapters) / 2.0))  // 2 chapters/day
        let option3Days = Int(ceil(Double(effectiveChapters) / 3.0))  // 3 chapters/day

        let odds1 = OddsCalculator.calculateChapterReadingOdds(book: self, timeframeDays: option1Days)
        let odds2 = OddsCalculator.calculateChapterReadingOdds(book: self, timeframeDays: option2Days)
        let odds3 = OddsCalculator.calculateChapterReadingOdds(book: self, timeframeDays: option3Days)

        let result = [
            ("1 Chapter/Day", odds1),
            ("2 Chapters/Day", odds2),
            ("3 Chapters/Day", odds3)
        ]

        Book.chapterOddsCache[id] = result
        return result
    }

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id
    }
    
    var effectiveTotalPages: Int {
        if let cached = Book.effectiveTotalPagesCache[id] {
            return cached
        }
        let prefs = readingPreferences
        let result: Int
        
        switch prefs.pageCountingStyle {
        case .inclusive:
            result = totalPages
        case .mainOnly:
            result = totalPages - prefs.estimatedFrontMatterPages - prefs.estimatedBackMatterPages
        case .custom:
            guard let start = prefs.customStartPage, let end = prefs.customEndPage else {
                result = totalPages
                break
            }
            result = max(0, end - start + 1)
        }
        
        Book.effectiveTotalPagesCache[id] = result
        return result
    }
    
    enum ReadingDifficulty: CaseIterable {
        case easy, medium, hard
        
        var multiplier: Double {
            switch self {
            case .easy: return 0.8
            case .medium: return 1.0
            case .hard: return 1.4
            }
        }
    }
    
    // OPTIMIZED: Cache odds calculations using static cache
    var odds: [(String, String)] {
        // Check static cache first
        if let cached = Book.oddsCache[id] {
            return cached
        }

        // Use centralized OddsCalculator for consistency
        let dayOdds = OddsCalculator.calculateReadingOdds(book: self, timeframeDays: 1)
        let weekOdds = OddsCalculator.calculateReadingOdds(book: self, timeframeDays: 7)
        let monthOdds = OddsCalculator.calculateReadingOdds(book: self, timeframeDays: 30)

        let result = [
            ("1 Day", dayOdds),
            ("1 Week", weekOdds),
            ("1 Month", monthOdds)
        ]

        // Store in static cache
        Book.oddsCache[id] = result
        return result
    }
    
    // OPTIMIZED: Cache journal odds calculations using static cache
    var journalOdds: [(String, String)] {
        // Check static cache first
        if let cached = Book.journalOddsCache[id] {
            return cached
        }

        // Use centralized OddsCalculator for consistency
        let fewOdds = OddsCalculator.calculateJournalOdds(book: self, noteTarget: "1-3")
        let someOdds = OddsCalculator.calculateJournalOdds(book: self, noteTarget: "4-7")
        let manyOdds = OddsCalculator.calculateJournalOdds(book: self, noteTarget: "8+")

        let result = [
            ("1-3 Notes", fewOdds),
            ("4-7 Notes", someOdds),
            ("8+ Notes", manyOdds)
        ]

        // Store in static cache
        Book.journalOddsCache[id] = result
        return result
    }
    
    // ADDED: Computed properties for reading preferences
    var hasCustomReadingPreferences: Bool {
        if let cached = Book.hasCustomReadingPreferencesCache[id] {
            return cached
        }
        let prefs = readingPreferences
        let result = prefs.pageCountingStyle != .inclusive
        Book.hasCustomReadingPreferencesCache[id] = result
        return result
    }
    
    var readingPreferenceSummary: String {
        if let cached = Book.readingPreferenceSummaryCache[id] {
            return cached
        }
        let prefs = readingPreferences
        let result: String
        
        switch prefs.pageCountingStyle {
        case .inclusive:
            result = "Full book"
        case .mainOnly:
            result = "Main story only"
        case .custom:
            if let start = prefs.customStartPage, let end = prefs.customEndPage {
                result = "Pages \(start)-\(end)"
            } else {
                result = "Custom range"
            }
        }
        
        Book.readingPreferenceSummaryCache[id] = result
        return result
    }
    
    // MARK: - Cache Invalidation
    
    /// Call this when preferences change to invalidate cached values
    static func invalidateCache(for bookId: UUID) {
        preferencesCache.removeValue(forKey: bookId)
        effectiveTotalPagesCache.removeValue(forKey: bookId)
        readingStartPageCache.removeValue(forKey: bookId)
        readingEndPageCache.removeValue(forKey: bookId)
        hasCustomReadingPreferencesCache.removeValue(forKey: bookId)
        readingPreferenceSummaryCache.removeValue(forKey: bookId)
        oddsCache.removeValue(forKey: bookId)
        journalOddsCache.removeValue(forKey: bookId)

        // Clear chapter caches
        effectiveTotalChaptersCache.removeValue(forKey: bookId)
        readingStartChapterCache.removeValue(forKey: bookId)
        readingEndChapterCache.removeValue(forKey: bookId)
        chapterOddsCache.removeValue(forKey: bookId)

        // Also clear OddsCalculator cache for this book
        OddsCalculator.clearCache(for: bookId)
    }

    /// Clear all caches (useful for memory management)
    static func clearAllCaches() {
        preferencesCache.removeAll()
        effectiveTotalPagesCache.removeAll()
        readingStartPageCache.removeAll()
        readingEndPageCache.removeAll()
        hasCustomReadingPreferencesCache.removeAll()
        readingPreferenceSummaryCache.removeAll()
        oddsCache.removeAll()
        journalOddsCache.removeAll()

        // Clear chapter caches
        effectiveTotalChaptersCache.removeAll()
        readingStartChapterCache.removeAll()
        readingEndChapterCache.removeAll()
        chapterOddsCache.removeAll()

        // Also clear OddsCalculator cache
        OddsCalculator.clearCache()
    }
}
