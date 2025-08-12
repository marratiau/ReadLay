//
//  EngagementBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//

import Foundation

struct EngagementBet: Identifiable, Hashable {
    let id: UUID
    let book: Book
    var goals: [EngagementGoal]
    let odds: String
    var wager: Double

    var totalTargetCount: Int {
        return goals.reduce(0) { $0 + $1.targetCount }
    }

    var totalCurrentCount: Int {
        return goals.reduce(0) { $0 + $1.currentCount }
    }

    var completedGoalsCount: Int {
        return goals.filter { $0.isCompleted }.count
    }

    var isCompleted: Bool {
        return goals.allSatisfy { $0.isCompleted }
    }

    var progressPercentage: Double {
        guard !goals.isEmpty else { return 0 }
        let totalProgress = goals.reduce(0.0) { $0 + $1.progressPercentage }
        return totalProgress / Double(goals.count)
    }

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
