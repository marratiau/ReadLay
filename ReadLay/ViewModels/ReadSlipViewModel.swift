//
//  ReadSlipViewModel.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//  Modified for FanDuel-style parlay support
//

import SwiftUI
import Combine
import CoreData

// Consolidated progress tracking
struct BetProgress: Equatable {
    var dailyProgress: Int = 0
    var totalPagesRead: Int = 0
    var currentPagePosition: Int = 0
    var lastReadPage: Int = 0
}

class ReadSlipViewModel: ObservableObject {
    @Published var betSlip = BetSlip()
    @Published var placedBets: [ReadingBet] = []
    @Published var placedEngagementBets: [EngagementBet] = []
    @Published var completedBets: [CompletedBet] = []
    @Published var activeParlays: [ParlayBet] = []
    @Published var journalEntries: [JournalEntry] = [] {
        didSet {
            if journalEntries.count > 100 {
                journalEntries = Array(journalEntries.prefix(100))
            }
        }
    }
    
    @Published var betProgress: [UUID: BetProgress] = [:]
    @Published var engagementProgress: [UUID: [UUID: Int]] = [:]
    @Published var currentBalance: Double = 10.0
    
    private var betLookupByBookId: [UUID: ReadingBet] = [:]
    private var engagementBetLookupByBookId: [UUID: EngagementBet] = [:]
    private var betLookupById: [UUID: ReadingBet] = [:]
    private var engagementBetLookupById: [UUID: EngagementBet] = [:]
    
    // FIXED: Use CoreDataRepository instead of CoreDataManager
    private var repository: CoreDataRepository
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: UUID?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, userId: UUID? = nil) {
        self.repository = CoreDataRepository(context: context)
        self.currentUserId = userId

        if let userId = userId {
            repository.setCurrentUser(userId: userId)
        }

        loadPersistedData()
    }

    // MARK: - User Management

    func setCurrentUser(userId: UUID) {
        self.currentUserId = userId
        repository.setCurrentUser(userId: userId)
        loadPersistedData() // Reload data for new user
    }
    
    private func updateLookupDictionaries() {
        betLookupByBookId = Dictionary(uniqueKeysWithValues: placedBets.map { ($0.book.id, $0) })
        engagementBetLookupByBookId = Dictionary(uniqueKeysWithValues: placedEngagementBets.map { ($0.book.id, $0) })
        betLookupById = Dictionary(uniqueKeysWithValues: placedBets.map { ($0.id, $0) })
        engagementBetLookupById = Dictionary(uniqueKeysWithValues: placedEngagementBets.map { ($0.id, $0) })
    }
    
    private func loadPersistedData() {
        do {
            journalEntries = try repository.fetchJournalEntries()
        } catch {
            print("Failed to load journal entries: \(error)")
        }
    }
    
    // MARK: - Balance Management
    
    var formattedBalance: String {
        return String(format: "%.2f", currentBalance)
    }
    
    func canAffordWager(_ amount: Double) -> Bool {
        return currentBalance >= amount
    }
    
    private func deductFromBalance(_ amount: Double) {
        currentBalance = max(0, currentBalance - amount)
    }
    
    private func addToBalance(_ amount: Double) {
        currentBalance += amount
    }
    
    func resetBalance() {
        currentBalance = 10.0
    }
    
    // MARK: - Book Protection Logic
    
    func hasActiveReadingBet(for bookId: UUID) -> Bool {
        return betLookupByBookId[bookId] != nil
    }
    
    func hasActiveEngagementBet(for bookId: UUID) -> Bool {
        return engagementBetLookupByBookId[bookId] != nil
    }
    
    func hasActiveBets(for bookId: UUID) -> Bool {
        return hasActiveReadingBet(for: bookId) || hasActiveEngagementBet(for: bookId)
    }
    
    func getActiveReadingBet(for bookId: UUID) -> ReadingBet? {
        return betLookupByBookId[bookId]
    }
    
    func getActiveEngagementBet(for bookId: UUID) -> EngagementBet? {
        return engagementBetLookupByBookId[bookId]
    }
    
    func getReadingBet(by id: UUID) -> ReadingBet? {
        return betLookupById[id]
    }
    
    func getEngagementBet(by id: UUID) -> EngagementBet? {
        return engagementBetLookupById[id]
    }
    
    // MARK: - Parlay Management
    
    func placeParlayBet(wager: Double) {
        guard canAffordWager(wager) else { return }
        guard betSlip.totalBets > 1 else {
            placeBets()
            return
        }
        
        deductFromBalance(wager)
        
        let parlayBet = ParlayBet(
            id: UUID(),
            legs: betSlip.readingBets,
            wager: wager,
            combinedOdds: betSlip.calculateParlayOdds(),
            startDate: Date()
        )
        
        for var bet in betSlip.readingBets {
            bet.parlayId = parlayBet.id
            bet.wager = wager / Double(betSlip.readingBets.count)
            placedBets.append(bet)
            
            betProgress[bet.id] = BetProgress(
                dailyProgress: 0,
                totalPagesRead: 0,
                currentPagePosition: bet.book.readingStartPage - 1,
                lastReadPage: bet.book.readingStartPage - 1
            )
        }
        
        activeParlays.append(parlayBet)
        updateLookupDictionaries()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.clearAll()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("BetsPlaced"), object: nil)
    }
    
    func checkParlayProgress(parlayId: UUID) {
        guard let parlayIndex = activeParlays.firstIndex(where: { $0.id == parlayId }) else { return }
        
        var parlay = activeParlays[parlayIndex]
        
        for leg in parlay.legs {
            if isBookCompleted(for: leg.id) {
                parlay.markLegCompleted(leg.id)
            }
        }
        
        if parlay.status == .won {
            addToBalance(parlay.totalPayout)
            activeParlays[parlayIndex] = parlay
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ParlayWon"),
                object: nil,
                userInfo: ["parlayId": parlayId, "payout": parlay.totalPayout]
            )
        }
        
        activeParlays[parlayIndex] = parlay
    }
    
    // MARK: - Progress Tracking
    
    func updateReadingProgress(for betId: UUID, startingPage: Int, endingPage: Int) {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return }
        
        let clampedStartingPage = max(startingPage, bet.book.readingStartPage)
        let clampedEndingPage = min(endingPage, bet.book.readingEndPage)
        let pagesRead = max(0, clampedEndingPage - clampedStartingPage + 1)
        
        var progress = betProgress[betId] ?? BetProgress()
        progress.dailyProgress += pagesRead
        progress.totalPagesRead += pagesRead
        progress.currentPagePosition = clampedEndingPage
        progress.lastReadPage = clampedEndingPage
        betProgress[betId] = progress
        
        if let parlayId = bet.parlayId {
            checkParlayProgress(parlayId: parlayId)
        }
        
        // FIXED: Use repository instead of coreDataManager
        do {
            try repository.addSession(
                to: bet.book.id,
                pages: pagesRead,
                minutes: 0,
                note: nil
            )
        } catch {
            print("Failed to save reading session: \(error)")
        }
        
        checkForCompletedBets()
    }
    
    func getCurrentPagePosition(for betId: UUID) -> Int {
        return betProgress[betId]?.currentPagePosition ?? 1
    }
    
    func getProgressInPages(for betId: UUID) -> Int {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return 0 }
        let currentPosition = getCurrentPagePosition(for: betId)
        
        if currentPosition < bet.book.readingStartPage {
            return 0
        }
        
        return currentPosition - bet.book.readingStartPage + 1
    }
    
    func getTotalPagesRead(for betId: UUID) -> Int {
        return betProgress[betId]?.totalPagesRead ?? 0
    }
    
    func getTotalProgress(for betId: UUID) -> Int {
        return getProgressInPages(for: betId)
    }
    
    func getDailyProgress(for betId: UUID) -> Int {
        return betProgress[betId]?.dailyProgress ?? 0
    }
    
    func getLastReadPage(for betId: UUID) -> Int {
        let lastPage = betProgress[betId]?.lastReadPage ?? 1
        return lastPage
    }
    
    func isDailyGoalCompleted(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let dailyPagesRead = getDailyProgress(for: betId)
        return dailyPagesRead >= bet.pagesPerDay
    }
    
    func isBookCompleted(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let currentPage = getCurrentPagePosition(for: betId)
        return currentPage >= bet.book.readingEndPage
    }
    
    // MARK: - Day Tracking
    
    func getProgressStatus(for betId: UUID) -> ReadingBet.ProgressStatus {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return .onTrack }
        let currentPage = getCurrentPagePosition(for: betId)
        return bet.getProgressStatus(actualProgress: currentPage)
    }
    
    func canGetAhead(for betId: UUID) -> Bool {
        guard let bet = placedBets.first(where: { $0.id == betId }) else { return false }
        let currentPage = getCurrentPagePosition(for: betId)
        let currentDayTarget = bet.book.readingStartPage + (bet.pagesPerDay * bet.currentDay) - 1
        return currentPage >= currentDayTarget && bet.currentDay < bet.totalDays
    }
    
    func startNextDay(for betId: UUID) {
        guard let betIndex = placedBets.firstIndex(where: { $0.id == betId }) else { return }
        
        var bet = placedBets[betIndex]
        guard bet.currentDay < bet.totalDays else { return }
        
        let currentPage = getCurrentPagePosition(for: betId)
        let currentDayTarget = bet.book.readingStartPage + (bet.pagesPerDay * bet.currentDay) - 1
        
        guard currentPage >= currentDayTarget else { return }
        
        bet.advanceToNextDay()
        placedBets[betIndex] = bet
        
        NotificationCenter.default.post(
            name: NSNotification.Name("DayAdvanced"),
            object: nil,
            userInfo: ["betId": betId, "newDay": bet.currentDay]
        )
    }
    
    // MARK: - Betting
    
    func addBet(book: Book, timeframe: String, odds: String, goalUnit: ReadingPreferences.GoalUnit = .pages) {
        guard !hasActiveBets(for: book.id) else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.addReadingBet(book: book, timeframe: timeframe, odds: odds, goalUnit: goalUnit)
        }
    }
    
    func removeBet(id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.removeReadingBet(id: id)
        }
    }
    
    func updateWager(for betId: UUID, wager: Double) {
        let maxWager = min(wager, currentBalance)
        betSlip.updateReadingWager(for: betId, wager: maxWager)
    }
    
    func addEngagementBet(book: Book, goals: [EngagementGoal], odds: String) {
        guard !hasActiveEngagementBet(for: book.id) else { return }
        
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
        let maxWager = min(wager, currentBalance)
        betSlip.updateEngagementWager(for: betId, wager: maxWager)
    }
    
    func toggleExpanded() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            betSlip.isExpanded.toggle()
        }
    }
    
    func placeBets() {
        guard canAffordWager(betSlip.totalWager) else { return }
        
        deductFromBalance(betSlip.totalWager)
        
        for bet in betSlip.readingBets {
            placedBets.append(bet)
            betProgress[bet.id] = BetProgress(
                dailyProgress: 0,
                totalPagesRead: 0,
                currentPagePosition: bet.book.readingStartPage - 1,
                lastReadPage: bet.book.readingStartPage - 1
            )
        }
        
        for bet in betSlip.engagementBets {
            placedEngagementBets.append(bet)
            var goalProgress: [UUID: Int] = [:]
            for goal in bet.goals {
                goalProgress[goal.id] = 0
            }
            engagementProgress[bet.id] = goalProgress
        }
        
        updateLookupDictionaries()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            betSlip.clearAll()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("BetsPlaced"), object: nil)
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
        
        // FIXED: Use repository instead of coreDataManager
        do {
            if let extraData = try? JSONEncoder().encode([
                "sessionDuration": Int(entry.sessionDuration),
                "pagesRead": entry.pagesRead,
                "startingPage": entry.startingPage,
                "endingPage": entry.endingPage
            ]) {
                try repository.addJournalEntry(
                    to: book.id,
                    text: entry.comment,
                    mood: nil,
                    extra: extraData
                )
            }
        } catch {
            print("Failed to save journal entry: \(error)")
        }
    }
    
    func processCompletedSession(_ session: ReadingSession) {
        guard let bet = placedBets.first(where: { $0.id == session.betId }) else { return }
        
        updateReadingProgress(
            for: session.betId,
            startingPage: session.startingPage,
            endingPage: session.endingPage
        )
        
        addJournalEntry(from: session, book: bet.book)
    }
    
    // MARK: - Bet Completion
    
    private func checkForCompletedBets() {
        var betsToComplete: [ReadingBet] = []
        
        for bet in placedBets {
            let currentPage = getCurrentPagePosition(for: bet.id)
            if currentPage >= bet.book.readingEndPage {
                betsToComplete.append(bet)
            }
        }
        
        for bet in betsToComplete {
            let currentPage = getCurrentPagePosition(for: bet.id)
            let wasSuccessful = currentPage >= bet.book.readingEndPage
            
            if bet.parlayId == nil && wasSuccessful {
                let payout = bet.totalPayout
                addToBalance(payout)
            }
            
            let completedBet = CompletedBet(
                originalBet: bet,
                completedDate: Date(),
                totalPagesRead: getTotalPagesRead(for: bet.id),
                wasSuccessful: wasSuccessful,
                payout: bet.parlayId == nil ? (wasSuccessful ? bet.totalPayout : 0) : 0
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                completedBets.append(completedBet)
                placedBets.removeAll { $0.id == bet.id }
                betProgress.removeValue(forKey: bet.id)
            }
        }
        
        updateLookupDictionaries()
    }
    
    func resetDailyProgress() {
        for betId in betProgress.keys {
            betProgress[betId]?.dailyProgress = 0
        }
    }
    
    func resetDailyProgress(for betId: UUID) {
        betProgress[betId]?.dailyProgress = 0
    }
    
    func getJournalEntries(for bookId: UUID) -> [JournalEntry] {
        return journalEntries.filter { $0.bookId == bookId }.sorted { $0.date > $1.date }
    }
    
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
