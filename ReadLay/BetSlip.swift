//
//  BetSlip.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/10/25.
//
import SwiftUI

struct BetSlip {
    var readingBets: [ReadingBet] = []
    var journalBets: [JournalBet] = []
    var isExpanded: Bool = false
    
    var totalBets: Int {
        return readingBets.count + journalBets.count
    }
    
    var totalWager: Double {
        let readingWager = readingBets.reduce(0) { $0 + $1.wager }
        let journalWager = journalBets.reduce(0) { $0 + $1.wager }
        return readingWager + journalWager
    }
    
    var totalPotentialWin: Double {
        let readingWin = readingBets.reduce(0) { $0 + $1.potentialWin }
        let journalWin = journalBets.reduce(0) { $0 + $1.potentialWin }
        return readingWin + journalWin
    }
    
    var totalPayout: Double {
        return totalWager + totalPotentialWin
    }
    
    mutating func addReadingBet(book: Book, timeframe: String, odds: String) {
        // Remove existing reading bet for same book if any
        readingBets.removeAll { $0.book.id == book.id }
        
        let totalDays = calculateDays(from: timeframe)
        let pagesPerDay = Int(ceil(Double(book.totalPages) / Double(totalDays)))
        
        let newBet = ReadingBet(
            id: UUID(),
            book: book,
            timeframe: timeframe,
            odds: odds,
            wager: 10.0,
            pagesPerDay: pagesPerDay,
            totalDays: totalDays
        )
        readingBets.append(newBet)
    }
    
    mutating func addJournalBet(book: Book, takeawayLabel: String, odds: String) {
        // Remove existing journal bet for same book if any
        journalBets.removeAll { $0.book.id == book.id }
        
        let takeawayCount = extractTakeawayCount(from: takeawayLabel)
        
        let newBet = JournalBet(
            id: UUID(),
            book: book,
            takeawayCount: takeawayCount,
            odds: odds,
            wager: 10.0
        )
        journalBets.append(newBet)
    }
    
    private func extractTakeawayCount(from label: String) -> Int {
        if label.contains("1+") { return 1 }
        if label.contains("2+") { return 2 }
        if label.contains("3+") { return 3 }
        return 1
    }
    
    private func calculateDays(from timeframe: String) -> Int {
        switch timeframe {
        case "1 Day": return 1
        case "1 Week": return 7
        case "1 Month": return 30
        default: return 7
        }
    }
    
    mutating func removeReadingBet(id: UUID) {
        readingBets.removeAll { $0.id == id }
    }
    
    mutating func removeJournalBet(id: UUID) {
        journalBets.removeAll { $0.id == id }
    }
    
    mutating func updateReadingWager(for betId: UUID, wager: Double) {
        if let index = readingBets.firstIndex(where: { $0.id == betId }) {
            readingBets[index].wager = wager
        }
    }
    
    mutating func updateJournalWager(for betId: UUID, wager: Double) {
        if let index = journalBets.firstIndex(where: { $0.id == betId }) {
            journalBets[index].wager = wager
        }
    }
    
    mutating func clearAll() {
        readingBets.removeAll()
        journalBets.removeAll()
        isExpanded = false
    }
}
