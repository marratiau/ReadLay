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
    @Published var placedBets: [ReadingBet] = []
    @Published var placedEngagementBets: [EngagementBet] = []
    @Published var completedBets: [CompletedBet] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var dailyProgress: [UUID: Int] = [:] // Pages read TODAY
    @Published var totalProgress: [UUID: Int] = [:] // Total pages read in book
    @Published var lastReadPage: [UUID: Int] = [:] // Last page read for each book
    @Published var engagementProgress: [UUID: [UUID: Int]] = [:]
    
    // ADDED: Balance management
    @Published var currentBalance: Double = 10.0 // Start with $10
    
    // MARK: - Balance Management
    
    /// Get formatted balance string with decimals
    var formattedBalance: String {
        return String(format: "%.2f", currentBalance)
    }
    
    /// Check if player has sufficient funds for a wager
    func canAffordWager(_ amount: Double) -> Bool {
        return currentBalance >= amount
    }
    
    /// Deduct money from balance (when placing bets)
    private func deductFromBalance(_ amount: Double) {
        currentBalance = max(0, currentBalance - amount)
    }
    
    /// Add money to balance (when winning bets)
    private func addToBalance(_ amount: Double) {
        currentBalance += amount
    }
    
    /// Reset balance to starting amount
    func resetBalance() {
        currentBalance = 10.0
    }
    
    // MARK: - Book Protection Logic
    
    /// Check if a book already has an active reading bet
    func hasActiveReadingBet(for bookId: UUID) -> Bool {
        return placedBets.contains { $0.book.id == bookId }
    }
    
    /// Check if a book already has an active engagement bet
    func hasActiveEngagementBet(for bookId: UUID) -> Bool {
        return placedEngagementBets.contains { $0.book.id == bookId }
    }
    
    /// Check if a book has any active bets
    func hasActiveBets(for bookId: UUID) -> Bool {
        return hasActiveReadingBet(for: bookId) || hasActiveEngagementBet(for: bookId)
    }
    
    /// Get the active reading bet for a book
    func getActiveReadingBet(for bookId: UUID) -> ReadingBet? {
        return placedBets.first { $0.book.id == bookId }
    }
    
    /// Get the active engagement bet for a book
    func getActiveEngagementBet(for bookId: UUID) -> EngagementBet? {
        return placedEngagementBets.first { $0.book.id == bookId }
    }
    
    /// Get all active bets for a book
    func getActiveBets(for bookId: UUID) -> (readingBet: ReadingBet?, engagementBet: EngagementBet?) {
        return (getActiveReadingBet(for: bookId), getActiveEngagementBet(for: bookId))
    }
    
    // MARK: - Enhanced Day Tracking
    
    /// Get progress status for a reading bet
    func getProgressStatus(for betId: UUID) -> ReadingBet.ProgressStatus {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return .onTrack }
        let actualProgress = getTotalProgress(for: betId)
        return bet.getProgressStatus(actualProgress: actualProgress)
    }
    
    /// Check if user can work on next day's goal (get ahead functionality)
    func canGetAhead(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let actualProgress = getTotalProgress(for: betId)
        let currentDayTarget = bet.expectedPagesToday
        
        // Can get ahead if current day's goal is completed and not on final day
        return actualProgress >= currentDayTarget && bet.currentDay < bet.totalDays
    }
    
    /// Get next available day to work on
    func getNextAvailableDay(for betId: UUID) -> Int {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return 1 }
        let actualProgress = getTotalProgress(for: betId)
        return bet.getNextAvailableDay(actualProgress: actualProgress)
    }
    
    /// Check if daily goal is completed for a specific day
    func isDailyGoalCompleted(for betId: UUID, day: Int) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let actualProgress = getTotalProgress(for: betId)
        let targetProgress = bet.expectedPagesByDay(day)
        return actualProgress >= targetProgress
    }
    
    /// Check if user is behind schedule
    func isBehindSchedule(for betId: UUID) -> Bool {
        return getProgressStatus(for: betId) == .behind
    }
    
    /// Check if user is ahead of schedule
    func isAheadOfSchedule(for betId: UUID) -> Bool {
        return getProgressStatus(for: betId) == .ahead
    }
    
    /// Get detailed progress info for a bet
    func getProgressInfo(for betId: UUID) -> (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        guard let bet = placedBets.first(where: { $0.id == betId }) else {
            return (0, 0, .onTrack)
        }
        
        let actualProgress = getTotalProgress(for: betId)
        let expectedProgress = bet.expectedPagesToday
        let status = bet.getProgressStatus(actualProgress: actualProgress)
        
        return (actualProgress, expectedProgress, status)
    }
    
    // MARK: - Day Management
    
    /// ADDED: Start next day for a bet (advance to work on next day's goal)
    func startNextDay(for betId: UUID) {
        guard let bet = placedBets.first(where: { $0.id == betId }) else {
            print("DEBUG: No bet found with ID \(betId)")
            return
        }
        
        // Check if can advance to next day
        guard bet.currentDay < bet.totalDays else {
            print("DEBUG: Already on final day for bet \(betId)")
            return
        }
        
        // Check if current day goal is completed
        let currentProgress = getTotalProgress(for: betId)
        let currentDayTarget = bet.pagesPerDay * bet.currentDay
        
        guard currentProgress >= currentDayTarget else {
            print("DEBUG: Current day goal not completed, cannot advance to next day")
            return
        }
        
        // Reset daily progress to start fresh for the new day
        // The user can now work on the next day's goal
        resetDailyProgress(for: betId)
        
        print("DEBUG: Reset daily progress for bet \(betId) - user can now work on day \(bet.currentDay + 1)")
        objectWillChange.send()
    }
    
    // MARK: - Reading Bets
    func addBet(book: Book, timeframe: String, odds: String) {
        // ADDED: Check if book already has active bets
        guard !hasActiveBets(for: book.id) else {
            print("Book already has active bets - cannot place new bet")
            return
        }
        
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
        // Ensure wager doesn't exceed available balance
        let maxWager = min(wager, currentBalance)
        betSlip.updateReadingWager(for: betId, wager: maxWager)
    }
    
    // MARK: - Engagement Bets
    func addEngagementBet(book: Book, goals: [EngagementGoal], odds: String) {
        // ADDED: Check if book already has active engagement bet
        guard !hasActiveEngagementBet(for: book.id) else {
            print("Book already has active engagement bet - cannot place new bet")
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.addEngagementBet(book: book, goals: goals, odds: odds)
        }
    }
    
    func removeEngagementBet(id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.removeEngagementBet(id: id)
        }
    }
    
    func updateEngagementWager(for betId: UUID, wager: Double) {
        // Ensure wager doesn't exceed available balance
        let maxWager = min(wager, currentBalance)
        betSlip.updateEngagementWager(for: betId, wager: maxWager)
    }
    
    // MARK: - Bet Management
    func toggleExpanded() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            betSlip.isExpanded.toggle()
        }
    }
    
    func placeBets() {
        // Check if player has sufficient funds
        guard canAffordWager(betSlip.totalWager) else {
            print("Insufficient funds to place bets")
            return
        }
        
        // Deduct total wager from balance
        deductFromBalance(betSlip.totalWager)
        
        // Move reading bets from betslip to placed bets
        for bet in betSlip.readingBets {
            placedBets.append(bet)
            dailyProgress[bet.id] = 0
            totalProgress[bet.id] = 0
            lastReadPage[bet.id] = 1
        }
        
        // Move engagement bets from betslip to placed bets
        for bet in betSlip.engagementBets {
            placedEngagementBets.append(bet)
            var goalProgress: [UUID: Int] = [:]
            for goal in bet.goals {
                goalProgress[goal.id] = 0
            }
            engagementProgress[bet.id] = goalProgress
        }
        
        // Clear the bet slip
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.clearAll()
        }
        
        // Notify views that bets were placed
        NotificationCenter.default.post(name: NSNotification.Name("BetsPlaced"), object: nil)
        
        print("Placed bets: \(placedBets.count) reading, \(placedEngagementBets.count) engagement")
        print("Remaining balance: $\(formattedBalance)")
    }
    
    // MARK: - Progress Tracking
    func updateReadingProgress(for betId: UUID, startingPage: Int, endingPage: Int) {
        // Correct page counting (inclusive)
        let pagesRead = max(0, endingPage - startingPage + 1)
        
        // Update daily progress (pages read in this session today)
        dailyProgress[betId] = (dailyProgress[betId] ?? 0) + pagesRead
        
        // Update total progress (total pages read in the book)
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
    
    func updateEngagementProgress(for betId: UUID, goalId: UUID, increment: Int = 1) {
        if engagementProgress[betId] == nil {
            engagementProgress[betId] = [:]
        }
        
        let currentCount = engagementProgress[betId]?[goalId] ?? 0
        engagementProgress[betId]?[goalId] = currentCount + increment
        
        if let betIndex = placedEngagementBets.firstIndex(where: { $0.id == betId }),
           let goalIndex = placedEngagementBets[betIndex].goals.firstIndex(where: { $0.id == goalId }) {
            placedEngagementBets[betIndex].goals[goalIndex].currentCount = currentCount + increment
        }
        
        objectWillChange.send()
        print("DEBUG: Updated engagement progress for bet \(betId), goal \(goalId)")
        print("DEBUG: New count: \(currentCount + increment)")
    }
    
    func getLastReadPage(for betId: UUID) -> Int {
        return lastReadPage[betId] ?? 1
    }
    
    // Helper methods for better MVVM
    func getDailyProgress(for betId: UUID) -> Int {
        return dailyProgress[betId] ?? 0
    }
    
    func getTotalProgress(for betId: UUID) -> Int {
        return totalProgress[betId] ?? 0
    }
    
    // Check if daily goal is completed
    func isDailyGoalCompleted(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let dailyPagesRead = getDailyProgress(for: betId)
        return dailyPagesRead >= bet.pagesPerDay
    }
    
    // Check if book is completed
    func isBookCompleted(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let totalPagesRead = getTotalProgress(for: betId)
        return totalPagesRead >= bet.book.totalPages
    }
    
    // MARK: - Journal Management
    func addJournalEntry(from session: ReadingSession, book: Book, engagementEntries: [EngagementEntry] = []) {
        let entry = JournalEntry(
            id: UUID(),
            bookId: book.id,
            bookTitle: book.title,
            bookAuthor: book.author,
            date: session.endTime ?? Date(),
            comment: session.comment,
            engagementEntries: engagementEntries,
            sessionDuration: session.duration,
            pagesRead: session.pagesRead,
            startingPage: session.startingPage,
            endingPage: session.endingPage
        )
        
        journalEntries.append(entry)
        print("DEBUG: Added journal entry for \(book.title)")
    }
    
    func processCompletedSession(_ session: ReadingSession) {
        guard let bet = placedBets.first(where: { $0.id == session.betId }) else {
            print("DEBUG: No bet found for session \(session.betId)")
            return
        }
        
        updateReadingProgress(
            for: session.betId,
            startingPage: session.startingPage,
            endingPage: session.endingPage
        )
        
        addJournalEntry(from: session, book: bet.book)
        print("DEBUG: Processed completed session for \(bet.book.title)")
    }
    
    // MARK: - Bet Completion
    private func checkForCompletedBets() {
        var betsToComplete: [ReadingBet] = []
        
        for bet in placedBets {
            let totalPagesRead = totalProgress[bet.id] ?? 0
            if totalPagesRead >= bet.book.totalPages {
                betsToComplete.append(bet)
            }
        }
        
        // Move completed bets to settled and pay out winnings
        for bet in betsToComplete {
            let totalPagesRead = totalProgress[bet.id] ?? 0
            let wasSuccessful = totalPagesRead >= bet.book.totalPages
            let payout = wasSuccessful ? bet.totalPayout : 0
            
            // Add winnings to balance
            if wasSuccessful {
                addToBalance(payout)
                print("🎉 Bet won! Added $\(payout) to balance. New balance: $\(formattedBalance)")
            }
            
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
    
    // ADDED: Manual daily progress reset (for testing or day changes)
    func resetDailyProgress() {
        for betId in dailyProgress.keys {
            dailyProgress[betId] = 0
        }
        objectWillChange.send()
    }
    
    // ADDED: Reset daily progress for specific bet
    func resetDailyProgress(for betId: UUID) {
        dailyProgress[betId] = 0
        objectWillChange.send()
    }
    
    // MARK: - Data Helpers
    func getJournalEntries(for bookId: UUID) -> [JournalEntry] {
        return journalEntries.filter { $0.bookId == bookId }.sorted { $0.date > $1.date }
    }
    
    func getTotalPagesRead(for bookId: UUID) -> Int {
        return journalEntries
            .filter { $0.bookId == bookId }
            .reduce(0) { $0 + $1.pagesRead }
    }
    
    func getTotalReadingTime(for bookId: UUID) -> TimeInterval {
        return journalEntries
            .filter { $0.bookId == bookId }
            .reduce(0) { $0 + $1.sessionDuration }
    }
}
