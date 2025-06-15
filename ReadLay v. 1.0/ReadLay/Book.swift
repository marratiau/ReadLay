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
    
    // NEW: Journal takeaway odds
    var journalOdds: [(String, String)] {
        // Base odds for journal entries (easier than completion)
        return [
            ("1+ Takeaway", formatOdds(120)),   // Easy
            ("2+ Takeaways", formatOdds(180)), // Medium
            ("3+ Takeaways", formatOdds(280))  // Harder
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
