//
//  EngagementBet.swift
//  ReadLay
//
//  Engagement bet model with parlay support
//

import SwiftUI

struct EngagementBet: Identifiable {
    let id: UUID
    let book: Book
    var goals: [EngagementGoal]
    let odds: String
    var wager: Double
    var parlayId: UUID? = nil
    
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
    
    var isPartOfParlay: Bool {
        return parlayId != nil
    }
}

