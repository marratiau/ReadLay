//
//  ReadingBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import Foundation

// NEW: Journal Bet Type
struct JournalBet: Identifiable, Hashable {
    let id: UUID
    let book: Book
    let takeawayCount: Int // Minimum takeaways needed
    let odds: String
    var wager: Double
    
    var potentialWin: Double {
        let oddsValue = parseOdds(odds)
        return wager * (Double(oddsValue) / 100.0)
    }
    
    var totalPayout: Double {
        return wager + potentialWin
    }
    
    private func parseOdds(_ odds: String) -> Int {
        let cleanOdds = odds.replacingOccurrences(of: "+", with: "")
        return Int(cleanOdds) ?? 150
    }
}

struct ReadingBet: Identifiable, Hashable {
    let id: UUID
    let book: Book
    let timeframe: String
    let odds: String
    var wager: Double
    let pagesPerDay: Int
    let totalDays: Int
    
    var potentialWin: Double {
        let oddsValue = parseOdds(odds)
        return wager * (Double(oddsValue) / 100.0)
    }
    
    var totalPayout: Double {
        return wager + potentialWin
    }
    
    private func parseOdds(_ odds: String) -> Int {
        let cleanOdds = odds.replacingOccurrences(of: "+", with: "")
        return Int(cleanOdds) ?? 150
    }
}



