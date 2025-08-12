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
    @Published var totalPagesRead: [UUID: Int] = [:] // Total pages read (cumulative)
    @Published var currentPagePosition: [UUID: Int] = [:] // Current page position in book
    @Published var lastReadPage: [UUID: Int] = [:] // Last page read for each book
    @Published var engagementProgress: [UUID: [UUID: Int]] = [:]

    // Balance management
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

    // MARK: - FIXED Progress Tracking
    func updateReadingProgress(for betId: UUID, startingPage: Int, endingPage: Int) {
        guard let bet = placedBets.first(where: { $0.id == betId }) else {
            print("DEBUG: No bet found for \(betId)")
            return
        }

        // FIXED: Use reading preferences for page validation
        let clampedStartingPage = max(startingPage, bet.book.readingStartPage)
        let clampedEndingPage = min(endingPage, bet.book.readingEndPage)

        // Correct page counting (inclusive)
        let pagesRead = max(0, clampedEndingPage - clampedStartingPage + 1)

        // Update daily progress (pages read in this session today)
        dailyProgress[betId] = (dailyProgress[betId] ?? 0) + pagesRead

        // Update total pages read (cumulative count)
        totalPagesRead[betId] = (totalPagesRead[betId] ?? 0) + pagesRead

        // FIXED: Update current page position (use reading range)
        currentPagePosition[betId] = clampedEndingPage

        // Update last read page
        lastReadPage[betId] = clampedEndingPage

        print("DEBUG: Updated progress for bet \(betId)")
        print("DEBUG: Reading range: \(bet.book.readingStartPage)-\(bet.book.readingEndPage)")
        print("DEBUG: Effective pages: \(bet.book.effectiveTotalPages)")
        print("DEBUG: Current page position: \(clampedEndingPage)")

        // Force UI update
        objectWillChange.send()

        // Check if any bets are completed
        checkForCompletedBets()
    }

    // MARK: - Progress Getters

    /// Get current page position in the book (what should be displayed in progress)
    func getCurrentPagePosition(for betId: UUID) -> Int {
        return currentPagePosition[betId] ?? 1
    }

    /// FIXED: Get progress as pages read within the custom reading range
    func getProgressInPages(for betId: UUID) -> Int {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return 0 }
        let currentPosition = getCurrentPagePosition(for: betId)
        
        // If current position is before reading start page, no progress yet
        if currentPosition < bet.book.readingStartPage {
            return 0
        }
        
        // Progress is how many pages into the reading range we are
        return currentPosition - bet.book.readingStartPage + 1
    }

    /// Get total pages read for a bet (cumulative count across all sessions)
    func getTotalPagesRead(for betId: UUID) -> Int {
        return totalPagesRead[betId] ?? 0
    }

    /// FIXED: This should return progress within reading range for calculations
    func getTotalProgress(for betId: UUID) -> Int {
        return getProgressInPages(for: betId)
    }

    // Helper methods for better MVVM
    func getDailyProgress(for betId: UUID) -> Int {
        return dailyProgress[betId] ?? 0
    }

    func getLastReadPage(for betId: UUID) -> Int {
        let lastPage = lastReadPage[betId] ?? 1
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return lastPage }
        
        // FIXED: For first session, return page before reading start to trigger correct flow
        return lastPage
    }

    // Check if daily goal is completed
    func isDailyGoalCompleted(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let dailyPagesRead = getDailyProgress(for: betId)
        return dailyPagesRead >= bet.pagesPerDay
    }

    // FIXED: Check if book is completed using reading end page
    func isBookCompleted(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let currentPage = getCurrentPagePosition(for: betId)
        return currentPage >= bet.book.readingEndPage // Use reading preferences
    }

    // MARK: - Enhanced Day Tracking

    /// Get progress status for a reading bet
    func getProgressStatus(for betId: UUID) -> ReadingBet.ProgressStatus {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return .onTrack }
        let currentPage = getCurrentPagePosition(for: betId)
        return bet.getProgressStatus(actualProgress: currentPage)
    }

    /// Check if user can work on next day's goal (get ahead functionality)
    func canGetAhead(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let currentPage = getCurrentPagePosition(for: betId)
        let currentDayTarget = bet.book.readingStartPage + (bet.pagesPerDay * bet.currentDay) - 1

        // Can get ahead if current day's goal is completed and not on final day
        return currentPage >= currentDayTarget && bet.currentDay < bet.totalDays
    }

    /// Get next available day to work on
    func getNextAvailableDay(for betId: UUID) -> Int {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return 1 }
        let currentPage = getCurrentPagePosition(for: betId)
        return bet.getNextAvailableDay(actualProgress: currentPage)
    }

    /// Check if daily goal is completed for a specific day
    func isDailyGoalCompleted(for betId: UUID, day: Int) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let currentPage = getCurrentPagePosition(for: betId)
        let targetProgress = bet.expectedPagesByDay(day)
        return currentPage >= targetProgress
    }

    /// Check if user is behind schedule
    func isBehindSchedule(for betId: UUID) -> Bool {
        return getProgressStatus(for: betId) == .behind
    }

    /// Check if user is ahead of schedule
    func isAheadOfSchedule(for betId: UUID) -> Bool {
        return getProgressStatus(for: betId) == .ahead
    }

    /// FIXED: Get detailed progress info for a bet using reading range
    func getProgressInfo(for betId: UUID) -> (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        guard let bet = placedBets.first(where: { $0.id == betId }) else {
            return (0, 0, .onTrack)
        }

        // FIXED: Use progress in pages (within reading range) instead of absolute position
        let actualProgress = getProgressInPages(for: betId)
        
        // Calculate expected progress within the effective reading range
        let expectedPagesFromStart = (bet.book.effectiveTotalPages * bet.currentDay) / bet.totalDays
        let expectedProgress = expectedPagesFromStart

        let currentPosition = getCurrentPagePosition(for: betId)
        let status = bet.getProgressStatus(actualProgress: currentPosition)

        return (actualProgress, expectedProgress, status)
    }

    // MARK: - Day Management

    /// Start next day for a bet (reveals next day without forcing reading session)
    func startNextDay(for betId: UUID) {
        guard let betIndex = placedBets.firstIndex(where: { $0.id == betId }) else {
            print("DEBUG: No bet found with ID \(betId)")
            return
        }

        var bet = placedBets[betIndex]

        // Check if can advance to next day
        guard bet.currentDay < bet.totalDays else {
            print("DEBUG: Already on final day for bet \(betId)")
            return
        }

        // Check if current day goal is completed
        let currentPage = getCurrentPagePosition(for: betId)
        let currentDayTarget = bet.book.readingStartPage + (bet.pagesPerDay * bet.currentDay) - 1

        guard currentPage >= currentDayTarget else {
            print("DEBUG: Current day goal not completed, cannot advance to next day")
            return
        }

        // Advance to next day
        bet.advanceToNextDay()
        placedBets[betIndex] = bet

        print("DEBUG: Advanced to day \(bet.currentDay) for bet \(betId)")

        // Force UI update to show new daily bet views
        objectWillChange.send()

        // Post notification that day was advanced (optional, for additional UI updates)
        NotificationCenter.default.post(
            name: NSNotification.Name("DayAdvanced"),
            object: nil,
            userInfo: ["betId": betId, "newDay": bet.currentDay]
        )
    }

    // MARK: - Reading Bets
    func addBet(book: Book, timeframe: String, odds: String) {
        // Check if book already has active bets
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
        // Check if book already has active engagement bet
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
            totalPagesRead[bet.id] = 0
            
            // FIXED: Set position to one page BEFORE the reading start page to indicate no progress yet
            currentPagePosition[bet.id] = bet.book.readingStartPage - 1  // For book starting at page 2, this sets to 1
            lastReadPage[bet.id] = bet.book.readingStartPage - 1         // For book starting at page 2, this sets to 1
            
            print("DEBUG: Initialized bet \(bet.id) with start page \(bet.book.readingStartPage)")
            print("DEBUG: Current position set to \(bet.book.readingStartPage - 1) (before starting)")
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
            let currentPage = getCurrentPagePosition(for: bet.id)
            if currentPage >= bet.book.readingEndPage { // FIXED: Use reading end page
                betsToComplete.append(bet)
            }
        }

        // Move completed bets to settled and pay out winnings
        for bet in betsToComplete {
            let currentPage = getCurrentPagePosition(for: bet.id)
            let wasSuccessful = currentPage >= bet.book.readingEndPage // FIXED: Use reading end page
            let payout = wasSuccessful ? bet.totalPayout : 0

            // Add winnings to balance
            if wasSuccessful {
                addToBalance(payout)
                print("🎉 Bet won! Added $\(payout) to balance. New balance: $\(formattedBalance)")
            }

            let completedBet = CompletedBet(
                originalBet: bet,
                completedDate: Date(),
                totalPagesRead: getTotalPagesRead(for: bet.id),
                wasSuccessful: wasSuccessful,
                payout: payout
            )

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                completedBets.append(completedBet)
                placedBets.removeAll { $0.id == bet.id }
                dailyProgress.removeValue(forKey: bet.id)
                totalPagesRead.removeValue(forKey: bet.id)
                currentPagePosition.removeValue(forKey: bet.id)
                lastReadPage.removeValue(forKey: bet.id)
            }
        }
    }

    // Manual daily progress reset (for testing or day changes)
    func resetDailyProgress() {
        for betId in dailyProgress.keys {
            dailyProgress[betId] = 0
        }
        objectWillChange.send()
    }

    // Reset daily progress for specific bet
    func resetDailyProgress(for betId: UUID) {
        dailyProgress[betId] = 0
        objectWillChange.send()
    }

    // MARK: - Data Helpers
    func getJournalEntries(for bookId: UUID) -> [JournalEntry] {
        return journalEntries.filter { $0.bookId == bookId }.sorted { $0.date > $1.date }
    }

    // To avoid conflict with getTotalPagesRead(for betId:)
    func getTotalPagesReadFromJournal(for bookId: UUID) -> Int {
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

// MARK: - Extension for Day Tracking
extension ReadSlipViewModel {
    /// Get number of pages read during the window for a specific day of a ReadingBet
    func getPagesReadForDay(bet: ReadingBet, day: Int) -> Int {
        let calendar = Calendar.current
        guard day > 0, day <= bet.totalDays else { return 0 }
        let dayStartDate = calendar.date(byAdding: .day, value: day - 1, to: bet.startDate)!
        let dayEndDate = calendar.date(byAdding: .day, value: day, to: bet.startDate)!
        let entries = journalEntries.filter { entry in
            entry.bookId == bet.book.id &&
            entry.date >= dayStartDate &&
            entry.date < dayEndDate
        }
        let totalPages = entries.reduce(0) { $0 + $1.pagesRead }
        return totalPages
    }

    func getMaxPageReached(for betId: UUID) -> Int {
        guard let readingBet = placedBets.first(where: { $0.id == betId }) else { return 0 }
        let entries = journalEntries.filter { $0.bookId == readingBet.book.id }
        guard !entries.isEmpty else { return 0 }
        return entries.map { $0.endingPage ?? ($0.startingPage + $0.pagesRead - 1) }.max() ?? 0
    }
}
