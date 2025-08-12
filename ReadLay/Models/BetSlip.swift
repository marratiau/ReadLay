//
//  BetSlip.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/10/25.
//

import SwiftUI

struct BetSlip {
    var readingBets: [ReadingBet] = []
    var engagementBets: [EngagementBet] = []
    var isExpanded: Bool = false

    var totalBets: Int {
        return readingBets.count + engagementBets.count
    }

    var totalWager: Double {
        let readingWager = readingBets.reduce(0) { $0 + $1.wager }
        let engagementWager = engagementBets.reduce(0) { $0 + $1.wager }
        return readingWager + engagementWager
    }

    var totalPotentialWin: Double {
        let readingWin = readingBets.reduce(0) { $0 + $1.potentialWin }
        let engagementWin = engagementBets.reduce(0) { $0 + $1.potentialWin }
        return readingWin + engagementWin
    }

    var totalPayout: Double {
        return totalWager + totalPotentialWin
    }

    // FIXED: Use effective pages for bet creation
    mutating func addReadingBet(book: Book, timeframe: String, odds: String) {
        readingBets.removeAll { $0.book.id == book.id }

        let totalDays = calculateDays(from: timeframe)
        // FIXED: Use effective pages for calculation
        let pagesPerDay = Int(ceil(Double(book.effectiveTotalPages) / Double(totalDays)))

        let newBet = ReadingBet(
            book: book,
            timeframe: timeframe,
            odds: odds,
            wager: 10.0,
            pagesPerDay: pagesPerDay,
            totalDays: totalDays
        )
        readingBets.append(newBet)
    }

    mutating func addEngagementBet(book: Book, goals: [EngagementGoal], odds: String) {
        engagementBets.removeAll { $0.book.id == book.id }

        let newBet = EngagementBet(
            id: UUID(),
            book: book,
            goals: goals,
            odds: odds,
            wager: 10.0
        )
        engagementBets.append(newBet)
    }

    // IMPROVED: Enhanced timeframe parsing for custom timeframes
    private func calculateDays(from timeframe: String) -> Int {
        let lowercased = timeframe.lowercased()

        // Extract number from the string
        let numbers = lowercased.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let count = Int(numbers), count > 0 else {
            return 1
        }

        // Determine unit and calculate total days
        if lowercased.contains("day") {
            return count
        } else if lowercased.contains("week") {
            return count * 7
        } else if lowercased.contains("month") {
            return count * 30
        } else {
            // Fallback to original logic for backwards compatibility
            switch timeframe {
            case "1 Day": return 1
            case "1 Week": return 7
            case "1 Month": return 30
            default: return count // Assume days if unclear
            }
        }
    }

    mutating func removeReadingBet(id: UUID) {
        readingBets.removeAll { $0.id == id }
    }

    mutating func removeEngagementBet(id: UUID) {
        engagementBets.removeAll { $0.id == id }
    }

    mutating func updateReadingWager(for betId: UUID, wager: Double) {
        if let index = readingBets.firstIndex(where: { $0.id == betId }) {
            readingBets[index].wager = wager
        }
    }

    mutating func updateEngagementWager(for betId: UUID, wager: Double) {
        if let index = engagementBets.firstIndex(where: { $0.id == betId }) {
            engagementBets[index].wager = wager
        }
    }

    mutating func clearAll() {
        readingBets.removeAll()
        engagementBets.removeAll()
        isExpanded = false
    }
}
