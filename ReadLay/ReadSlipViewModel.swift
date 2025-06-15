//
//  ReadSlipViewModel.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import Combine

class ReadSlipViewModel: ObservableObject {
    @Published var betSlip = BetSlip()
    @Published var placedBets: [ReadingBet] = [] // Active bets
    @Published var completedBets: [CompletedBet] = [] // Settled bets
    @Published var dailyProgress: [UUID: Int] = [:] // Daily progress by bet ID
    @Published var totalProgress: [UUID: Int] = [:] // Total progress by bet ID
    @Published var lastReadPage: [UUID: Int] = [:] // Last page read for each book
    
    func addBet(book: Book, timeframe: String, odds: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.addReadingBet(book: book, timeframe: timeframe, odds: odds)
        }
    }
    
    func removeBet(id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.removeReadingBet(id: id)
        }
    }
    
    func updateWager(for betId: UUID, wager: Double) {
        betSlip.updateReadingWager(for: betId, wager: wager)
    }
    
    func toggleExpanded() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            betSlip.isExpanded.toggle()
        }
    }
    
    func placeBets() {
        // Move bets from betslip to placed bets
        for bet in betSlip.readingBets {
            placedBets.append(bet)
            dailyProgress[bet.id] = 0
            totalProgress[bet.id] = 0
            lastReadPage[bet.id] = 1 // Start from page 1
        }
        
        // Clear the bet slip
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.clearAll()
        }
        
        print("Placed bets: \(placedBets)")
    }
    
    func updateReadingProgress(for betId: UUID, startingPage: Int, endingPage: Int) {
        let pagesRead = max(0, endingPage - startingPage)
        
        // Update daily progress
        dailyProgress[betId] = (dailyProgress[betId] ?? 0) + pagesRead
        
        // Update total progress
        totalProgress[betId] = (totalProgress[betId] ?? 0) + pagesRead
        
        // Update last read page
        lastReadPage[betId] = endingPage
        
        print("DEBUG: Updated progress for bet \(betId)")
        print("DEBUG: Starting page: \(startingPage), Ending page: \(endingPage)")
        print("DEBUG: Pages read this session: \(pagesRead)")
        print("DEBUG: Total progress: \(totalProgress[betId] ?? 0)")
        print("DEBUG: Daily progress: \(dailyProgress[betId] ?? 0)")
        print("DEBUG: Last read page: \(endingPage)")
        
        // Force UI update
        objectWillChange.send()
        
        // Check if any bets are completed
        checkForCompletedBets()
    }
    
    func getLastReadPage(for betId: UUID) -> Int {
        return lastReadPage[betId] ?? 1
    }
    
   
    
    private func checkForCompletedBets() {
        var betsToComplete: [ReadingBet] = []
        
        for bet in placedBets {
            let totalPagesRead = totalProgress[bet.id] ?? 0
            if totalPagesRead >= bet.book.totalPages {
                betsToComplete.append(bet)
            }
        }
        
        // Move completed bets to settled
        for bet in betsToComplete {
            let totalPagesRead = totalProgress[bet.id] ?? 0
            let wasSuccessful = totalPagesRead >= bet.book.totalPages
            let payout = wasSuccessful ? bet.totalPayout : 0
            
            let completedBet = CompletedBet(
                originalBet: bet,
                completedDate: Date(),
                totalPagesRead: totalPagesRead,
                wasSuccessful: wasSuccessful,
                payout: payout
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                completedBets.append(completedBet)
                placedBets.removeAll { $0.id == bet.id }
                dailyProgress.removeValue(forKey: bet.id)
                totalProgress.removeValue(forKey: bet.id)
                lastReadPage.removeValue(forKey: bet.id)
            }
        }
    }
    
    func resetDailyProgress() {
        // Reset daily progress for all active bets (called at start of new day)
        for betId in dailyProgress.keys {
            dailyProgress[betId] = 0
        }
    }
}

