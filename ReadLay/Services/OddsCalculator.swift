//
//  OddsCalculator.swift
//  ReadLay
//
//  Created by Claude Code on 12/15/25.
//  Centralized odds calculation service
//

import SwiftUI

/// Centralized service for calculating betting odds
/// Uses unified formula across all bet types for consistency
struct OddsCalculator {

    // MARK: - Cache for Performance
    private static var oddsCache: [String: String] = [:]

    // MARK: - Reading Completion Odds

    /// Calculate odds for reading completion bets
    /// - Parameters:
    ///   - book: The book being bet on
    ///   - timeframeDays: Number of days to complete the reading
    /// - Returns: Formatted odds string (e.g., "+150")
    static func calculateReadingOdds(book: Book, timeframeDays: Int) -> String {
        let cacheKey = "reading_\(book.id)_\(timeframeDays)"

        // Check cache first
        if let cached = oddsCache[cacheKey] {
            return cached
        }

        let pagesPerDay = Double(book.effectiveTotalPages) / Double(timeframeDays)
        let difficultyFactor = calculateDifficultyFactor(pagesPerDay: pagesPerDay, timeframeDays: timeframeDays)
        let bookMultiplier = book.difficulty.multiplier

        let finalOdds = 100 + Int((difficultyFactor * bookMultiplier * 40))
        let clampedOdds = min(max(finalOdds, 110), 999)

        let result = "+\(clampedOdds)"

        // Cache the result
        oddsCache[cacheKey] = result
        return result
    }

    // MARK: - Chapter Reading Odds

    /// Calculate odds for chapter-based reading goals
    /// - Parameters:
    ///   - book: The book being bet on
    ///   - timeframeDays: Number of days to complete the reading
    /// - Returns: Formatted odds string (e.g., "+130")
    static func calculateChapterReadingOdds(book: Book, timeframeDays: Int) -> String {
        let cacheKey = "chapter_\(book.id)_\(timeframeDays)"

        // Check cache first
        if let cached = oddsCache[cacheKey] {
            return cached
        }

        let totalChapters = book.effectiveTotalChapters
        guard totalChapters > 0 else {
            return "+110"
        }

        let chaptersPerDay = Double(totalChapters) / Double(timeframeDays)

        // Base odds by chapters per day
        let baseOdds: Int
        switch chaptersPerDay {
        case 0..<1:
            baseOdds = 110  // Less than 1/day - easy
        case 1..<2:
            baseOdds = 130  // 1-2/day - moderate
        case 2..<3:
            baseOdds = 160  // 2-3/day - challenging
        default:
            baseOdds = 200  // 3+/day - very difficult
        }

        // Apply difficulty multiplier
        let difficultyFactor = book.difficulty.multiplier - 1.0
        let finalOdds = baseOdds + Int(Double(baseOdds - 100) * difficultyFactor)
        let clampedOdds = min(max(finalOdds, 105), 500)

        let result = "+\(clampedOdds)"

        // Cache the result
        oddsCache[cacheKey] = result
        return result
    }

    // MARK: - Journal/Engagement Odds

    /// Calculate odds for journal/engagement bets
    /// - Parameters:
    ///   - book: The book being bet on
    ///   - noteTarget: Target note count ("1-3", "4-7", "8+")
    /// - Returns: Formatted odds string (e.g., "+120")
    static func calculateJournalOdds(book: Book, noteTarget: String) -> String {
        let cacheKey = "journal_\(book.id)_\(noteTarget)"

        // Check cache first
        if let cached = oddsCache[cacheKey] {
            return cached
        }

        let difficultyFactor: Double
        switch noteTarget {
        case "1-3":
            difficultyFactor = 0.5
        case "4-7":
            difficultyFactor = 1.0
        case "8+":
            difficultyFactor = 2.0
        default:
            difficultyFactor = 1.0
        }

        let bookMultiplier = book.difficulty.multiplier
        let finalOdds = 100 + Int((difficultyFactor * bookMultiplier * 30))
        let clampedOdds = min(max(finalOdds, 105), 400)

        let result = "+\(clampedOdds)"

        // Cache the result
        oddsCache[cacheKey] = result
        return result
    }

    // MARK: - Helper Methods

    /// Calculate difficulty factor based on pages per day and timeframe
    private static func calculateDifficultyFactor(pagesPerDay: Double, timeframeDays: Int) -> Double {
        switch timeframeDays {
        case 1...3:
            // Aggressive: 1-3 days
            return min(pagesPerDay / 15.0, 10.0)
        case 4...7:
            // Moderate: 4-7 days
            return min(pagesPerDay / 20.0, 8.0)
        case 8...21:
            // Easier: 1-3 weeks
            return min(pagesPerDay / 12.0, 4.0)
        default:
            // Easiest: 22+ days
            return min(pagesPerDay / 8.0, 2.0)
        }
    }

    // MARK: - Cache Management

    /// Clear all cached odds calculations
    static func clearCache() {
        oddsCache.removeAll()
    }

    /// Clear cached odds for a specific book
    /// - Parameter bookId: The UUID of the book
    static func clearCache(for bookId: UUID) {
        oddsCache = oddsCache.filter { !$0.key.contains(bookId.uuidString) }
    }
}
