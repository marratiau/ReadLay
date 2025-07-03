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
    
    // Reading completion odds
    var odds: [(String, String)] {
        let baseMultiplier = difficulty.multiplier
        let pagesFactor = Double(totalPages) / 300.0
        
        let dayOdds = calculateOdds(timeframe: 1, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        let weekOdds = calculateOdds(timeframe: 7, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        let monthOdds = calculateOdds(timeframe: 30, baseMultiplier: baseMultiplier, pagesFactor: pagesFactor)
        
        return [
            ("1 Day", formatOdds(dayOdds)),
            ("1 Week", formatOdds(weekOdds)),
            ("1 Month", formatOdds(monthOdds))
        ]
    }
    
    private func calculateOdds(timeframe: Int, baseMultiplier: Double, pagesFactor: Double) -> Int {
        let pagesPerDay = Double(totalPages) / Double(timeframe)
        
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
    
    // Journal action odds
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

// Goodreads-inspired color palette
extension Color {
    static let goodreadsBeige = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let goodreadsWarm = Color(red: 0.93, green: 0.89, blue: 0.82)
    static let goodreadsBrown = Color(red: 0.55, green: 0.45, blue: 0.35)
    static let goodreadsAccent = Color(red: 0.65, green: 0.52, blue: 0.39)
    static let shelfWood = Color(red: 0.76, green: 0.65, blue: 0.52)
    static let shelfShadow = Color(red: 0.45, green: 0.35, blue: 0.25)
}
