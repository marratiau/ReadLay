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
        let baseMultiplier = difficulty.multiplier
        let pagesFactor = Double(effectiveTotalPages) / 300.0
        
        let dayOdds = calculateOdds(timeframe: 1, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        let weekOdds = calculateOdds(timeframe: 7, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        let monthOdds = calculateOdds(timeframe: 30, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        
        let result = [
            ("1 Day", formatOdds(dayOdds)),
            ("1 Week", formatOdds(weekOdds)),
            ("1 Month", formatOdds(monthOdds))
        ]
        
        // Store in static cache
        Book.oddsCache[id] = result
        return result
    }
    
    private func calculateOdds(timeframe: Int, baseMultiplier: Double, pagesFactor: Double) -> Int {
        let pagesPerDay = Double(effectiveTotalPages) / Double(timeframe)
        
        let difficultyFactor: Double
        switch timeframe {
        case 1:
            difficultyFactor = min(pagesPerDay / 20.0, 8.0)
        case 7:
            difficultyFactor = min(pagesPerDay / 10.0, 3.0)
        case 30:
            difficultyFactor = min(pagesPerDay / 5.0, 1.5)
        default:
            difficultyFactor = 1.0
        }
        
        let finalOdds = 100 + Int((difficultyFactor * baseMultiplier * 50))
        return min(max(finalOdds, 110), 800)
    }
    
    private func formatOdds(_ value: Int) -> String {
        return "+\(value)"
    }
    
    // OPTIMIZED: Cache journal odds calculations using static cache
    var journalOdds: [(String, String)] {
        // Check static cache first
        if let cached = Book.journalOddsCache[id] {
            return cached
        }
        let baseMultiplier = difficulty.multiplier
        
        let fewOdds = calculateJournalOdds(count: "1-3", baseMultiplier: baseMultiplier)
        let someOdds = calculateJournalOdds(count: "4-7", baseMultiplier: baseMultiplier)
        let manyOdds = calculateJournalOdds(count: "8+", baseMultiplier: baseMultiplier)
        
        let result = [
            ("1-3 Notes", formatOdds(fewOdds)),
            ("4-7 Notes", formatOdds(someOdds)),
            ("8+ Notes", formatOdds(manyOdds))
        ]
        
        // Store in static cache
        Book.journalOddsCache[id] = result
        return result
    }
    
    private func calculateJournalOdds(count: String, baseMultiplier: Double) -> Int {
        let difficultyFactor: Double
        
        switch count {
        case "1-3":
            difficultyFactor = 0.5
        case "4-7":
            difficultyFactor = 1.0
        case "8+":
            difficultyFactor = 2.0
        default:
            difficultyFactor = 1.0
        }
        
        let finalOdds = 100 + Int((difficultyFactor * baseMultiplier * 30))
        return min(max(finalOdds, 105), 400)
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
    }
}
