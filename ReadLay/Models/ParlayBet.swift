//
//  ParlayBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 9/9/25.
//


//
//  ParlayBet.swift
//  ReadLay
//
//  Created for FanDuel-style parlay betting
//

import SwiftUI

struct ParlayBet: Identifiable {
    let id: UUID
    let legs: [ReadingBet]
    let wager: Double
    let combinedOdds: String
    let startDate: Date
    var isActive: Bool = true
    var completedLegs: Set<UUID> = []
    
    var potentialWin: Double {
        let oddsValue = parseOdds(combinedOdds)
        return wager * (Double(oddsValue) / 100.0)
    }
    
    var totalPayout: Double {
        return wager + potentialWin
    }
    
    var totalLegs: Int {
        return legs.count
    }
    
    var completedLegsCount: Int {
        return completedLegs.count
    }
    
    var progress: Double {
        guard totalLegs > 0 else { return 0 }
        return Double(completedLegsCount) / Double(totalLegs)
    }
    
    var status: ParlayStatus {
        if completedLegsCount == totalLegs {
            return .won
        } else if !isActive {
            return .lost
        } else {
            return .inProgress
        }
    }
    
    enum ParlayStatus {
        case inProgress
        case won
        case lost
        
        var displayText: String {
            switch self {
            case .inProgress: return "In Progress"
            case .won: return "Won"
            case .lost: return "Lost"
            }
        }
        
        var color: Color {
            switch self {
            case .inProgress: return .blue
            case .won: return .green
            case .lost: return .red
            }
        }
    }
    
    private func parseOdds(_ odds: String) -> Int {
        let cleanOdds = odds.replacingOccurrences(of: "+", with: "")
        return Int(cleanOdds) ?? 100
    }
    
    mutating func markLegCompleted(_ legId: UUID) {
        completedLegs.insert(legId)
    }
    
    mutating func markAsLost() {
        isActive = false
    }
}