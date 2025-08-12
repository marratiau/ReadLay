//
//  Book.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct Book: Identifiable, Hashable {
    let id: UUID
    let title: String
    let author: String?
    let totalPages: Int
    let coverImageName: String?
    let coverImageURL: String?
    let googleBooksId: String?
    let spineColor: Color
    let difficulty: ReadingDifficulty

    // ADDED: Reading preferences for page tracking
    var readingPreferences: ReadingPreferences {
        get {
            // Load from UserDefaults
            return ReadingPreferences.load(for: self.id) ?? ReadingPreferences.default(for: self)
        }
        set {
            // Save to UserDefaults
            newValue.save(for: self.id)
        }
    }

    // ADDED: Computed properties based on preferences
    var effectiveTotalPages: Int {
        let prefs = readingPreferences
        if let customEnd = prefs.customEndPage, let customStart = prefs.customStartPage {
            return max(0, customEnd - customStart + 1)
        }

        switch prefs.pageCountingStyle {
        case .inclusive:
            return totalPages
        case .mainOnly:
            return totalPages - prefs.estimatedFrontMatterPages - prefs.estimatedBackMatterPages
        case .custom:
            guard let start = prefs.customStartPage, let end = prefs.customEndPage else {
                return totalPages
            }
            return max(0, end - start + 1)
        }
    }

    var readingStartPage: Int {
        let prefs = readingPreferences
        if let customStart = prefs.customStartPage {
            return customStart
        }

        switch prefs.pageCountingStyle {
        case .inclusive:
            return 1
        case .mainOnly:
            return prefs.estimatedFrontMatterPages + 1
        case .custom:
            return prefs.customStartPage ?? 1
        }
    }

    var readingEndPage: Int {
        let prefs = readingPreferences
        if let customEnd = prefs.customEndPage {
            return customEnd
        }

        switch prefs.pageCountingStyle {
        case .inclusive:
            return totalPages
        case .mainOnly:
            return totalPages - prefs.estimatedBackMatterPages
        case .custom:
            return prefs.customEndPage ?? totalPages
        }
    }

    // Check if book has custom reading preferences set
    var hasCustomReadingPreferences: Bool {
        let prefs = readingPreferences
        return prefs.pageCountingStyle != .inclusive ||
               prefs.customStartPage != nil ||
               prefs.customEndPage != nil
    }

    // Get reading preference summary
    var readingPreferenceSummary: String {
        let prefs = readingPreferences
        switch prefs.pageCountingStyle {
        case .inclusive:
            return "Full book (\(effectiveTotalPages) pages)"
        case .mainOnly:
            return "Main story (\(effectiveTotalPages) pages)"
        case .custom:
            return "Custom range (\(effectiveTotalPages) pages)"
        }
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

    // FIXED: Reading completion odds now use effective pages
    var odds: [(String, String)] {
        let baseMultiplier = difficulty.multiplier
        let pagesFactor = Double(effectiveTotalPages) / 300.0 // FIXED: Use effective pages

        let dayOdds = calculateOdds(timeframe: 1, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        let weekOdds = calculateOdds(timeframe: 7, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        let monthOdds = calculateOdds(timeframe: 30, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)

        return [
            ("1 Day", formatOdds(dayOdds)),
            ("1 Week", formatOdds(weekOdds)),
            ("1 Month", formatOdds(monthOdds))
        ]
    }

    // FIXED: Calculate odds using effective pages
    private func calculateOdds(timeframe: Int, baseMultiplier: Double, pagesFactor: Double) -> Int {
        let pagesPerDay = Double(effectiveTotalPages) / Double(timeframe) // FIXED: Use effective pages

        let difficultyFactor: Double
        switch timeframe {
        case 1: // 1 day - hardest
            difficultyFactor = min(pagesPerDay / 20.0, 8.0)
        case 7: // 1 week - moderate
            difficultyFactor = min(pagesPerDay / 10.0, 3.0)
        case 30: // 1 month - easiest
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

    // FIXED: Journal action odds now use effective pages
    var journalOdds: [(String, String)] {
        let baseMultiplier = difficulty.multiplier

        // Generate odds for different numbers of takeaways/notes
        let fewOdds = calculateJournalOdds(count: "1-3", baseMultiplier: baseMultiplier)
        let someOdds = calculateJournalOdds(count: "4-7", baseMultiplier: baseMultiplier)
        let manyOdds = calculateJournalOdds(count: "8+", baseMultiplier: baseMultiplier)

        return [
            ("1-3 Notes", formatOdds(fewOdds)),
            ("4-7 Notes", formatOdds(someOdds)),
            ("8+ Notes", formatOdds(manyOdds))
        ]
    }

    private func calculateJournalOdds(count: String, baseMultiplier: Double) -> Int {
        let difficultyFactor: Double

        switch count {
        case "1-3": // Easier - most people write a few notes
            difficultyFactor = 0.5
        case "4-7": // Moderate - good engagement
            difficultyFactor = 1.0
        case "8+": // Harder - very engaged reading
            difficultyFactor = 2.0
        default:
            difficultyFactor = 1.0
        }

        let finalOdds = 100 + Int((difficultyFactor * baseMultiplier * 30))
        return min(max(finalOdds, 105), 400)
    }
}


