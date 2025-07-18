//
//  DailyBetsViewModel.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

//  DailyBetsViewModel.swift - FIXED: Day 2 only shows AFTER tapping Start Day 2
//  Key changes: Removed automatic next day reveal + proper day progression logic

import SwiftUI
import Combine

class DailyBetsViewModel: ObservableObject {
    @Published var dailyBets: [DailyBet] = []
    
    // FIXED: Multi-day tracking WITHOUT automatic next day reveal
    func updateDailyBetsWithMultiDay(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) {
        var newDailyBets: [DailyBet] = []
        
        for readingBet in placedBets {
            let totalProgress = readSlipViewModel.getTotalProgress(for: readingBet.id)
            let currentDay = readingBet.currentDay
            
            // UPDATED: Only show days up to and including current day
            
            // 1. Show ALL completed previous days (but marked as completed)
            for day in 1..<currentDay {
                let dailyBet = createCompletedDailyBetForDay(
                    day: day,
                    readingBet: readingBet,
                    totalProgress: totalProgress,
                    readSlipViewModel: readSlipViewModel
                )
                newDailyBets.append(dailyBet)
            }
            
            // 2. Show current day (this is the only active day)
            let currentDayBet = createDailyBetForDay(
                day: currentDay,
                readingBet: readingBet,
                totalProgress: totalProgress,
                readSlipViewModel: readSlipViewModel,
                isCurrentDay: true
            )
            newDailyBets.append(currentDayBet)
            
            // 3. REMOVED: No automatic next day reveal
            // Next day only appears after user explicitly taps "Start Day 2"
            // This happens when ReadSlipViewModel.startNextDay() is called
        }
        
        dailyBets = newDailyBets
    }
    
    // ENHANCED: Create daily bet with better state management
    private func createDailyBetForDay(
        day: Int,
        readingBet: ReadingBet,
        totalProgress: Int,
        readSlipViewModel: ReadSlipViewModel,
        isNextDay: Bool = false,
        isCurrentDay: Bool = false
    ) -> DailyBet {
        let dayStartPage = (day - 1) * readingBet.pagesPerDay + 1
        let dayEndPage = min(day * readingBet.pagesPerDay, readingBet.book.totalPages)
        let dayGoal = dayEndPage - dayStartPage + 1

        // UPDATED: Calculate progress for this specific day more accurately
        let currentDayProgress: Int
        if isNextDay {
            currentDayProgress = 0 // Next day hasn't started yet
        } else {
            // Get actual pages read within this day's range
            let currentPage = readSlipViewModel.getCurrentPagePosition(for: readingBet.id)
            let progressInThisDay = max(0, min(currentPage - dayStartPage + 1, dayGoal))
            currentDayProgress = max(0, progressInThisDay)
        }

        let progressStatus = readSlipViewModel.getProgressStatus(for: readingBet.id)
        let canGetAhead = readSlipViewModel.canGetAhead(for: readingBet.id) && isCurrentDay

        return DailyBet(
            book: readingBet.book,
            dailyGoal: dayGoal,
            currentProgress: currentDayProgress,
            totalDays: readingBet.totalDays,
            dayNumber: day,
            betId: readingBet.id,
            startDate: readingBet.startDate,
            isOverdue: progressStatus == .overdue && isCurrentDay,
            canGetAhead: canGetAhead,
            dayStartPage: dayStartPage,
            dayEndPage: dayEndPage,
            isNextDay: isNextDay
        )
    }
    
    // NEW: Create completed daily bet (for previous days)
    private func createCompletedDailyBetForDay(
        day: Int,
        readingBet: ReadingBet,
        totalProgress: Int,
        readSlipViewModel: ReadSlipViewModel
    ) -> DailyBet {
        let dayStartPage = (day - 1) * readingBet.pagesPerDay + 1
        let dayEndPage = min(day * readingBet.pagesPerDay, readingBet.book.totalPages)
        let dayGoal = dayEndPage - dayStartPage + 1

        // Completed days show full progress
        let currentDayProgress = dayGoal

        return DailyBet(
            book: readingBet.book,
            dailyGoal: dayGoal,
            currentProgress: currentDayProgress, // Full completion
            totalDays: readingBet.totalDays,
            dayNumber: day,
            betId: readingBet.id,
            startDate: readingBet.startDate,
            isOverdue: false, // Completed days are never overdue
            canGetAhead: false, // Completed days can't get ahead
            dayStartPage: dayStartPage,
            dayEndPage: dayEndPage,
            isNextDay: false
        )
    }
    
    // LEGACY: Keep for backward compatibility but prefer the new method above
    func updateDailyBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) {
        // Use the new multi-day method
        updateDailyBetsWithMultiDay(from: placedBets, readSlipViewModel: readSlipViewModel)
    }
    
    // LEGACY: Keep for backward compatibility but prefer the new method above
    func updateDailyBets(from placedBets: [ReadingBet], dailyProgress: [UUID: Int]) {
        var newDailyBets: [DailyBet] = []
        
        for readingBet in placedBets {
            let currentProgress = dailyProgress[readingBet.id] ?? 0
            let actualDay = readingBet.currentDay
            
            let dailyBet = DailyBet(
                book: readingBet.book,
                dailyGoal: readingBet.pagesPerDay,
                currentProgress: currentProgress,
                totalDays: readingBet.totalDays,
                dayNumber: actualDay,
                betId: readingBet.id
            )
            newDailyBets.append(dailyBet)
        }
        
        dailyBets = newDailyBets
    }
    
    // ADDED: Enhanced day tracking methods
    
    /// Get all bets that are overdue
    func getOverdueBets(from placedBets: [ReadingBet]) -> [ReadingBet] {
        return placedBets.filter { $0.isOverdue }
    }
    
    /// Get all bets that are behind schedule
    func getBehindScheduleBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [ReadingBet] {
        return placedBets.filter { bet in
            let actualProgress = readSlipViewModel.getTotalProgress(for: bet.id)
            return bet.getProgressStatus(actualProgress: actualProgress) == .behind
        }
    }
    
    /// Get all bets that are ahead of schedule
    func getAheadOfScheduleBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [ReadingBet] {
        return placedBets.filter { bet in
            let actualProgress = readSlipViewModel.getTotalProgress(for: bet.id)
            return bet.getProgressStatus(actualProgress: actualProgress) == .ahead
        }
    }
    
    /// Get bets that can get ahead (completed today's goal)
    func getBetsThatCanGetAhead(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [ReadingBet] {
        return placedBets.filter { bet in
            readSlipViewModel.canGetAhead(for: bet.id)
        }
    }
    
    /// Get detailed status for all bets
    func getBetStatuses(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [UUID: ReadingBet.ProgressStatus] {
        var statuses: [UUID: ReadingBet.ProgressStatus] = [:]
        
        for bet in placedBets {
            statuses[bet.id] = readSlipViewModel.getProgressStatus(for: bet.id)
        }
        
        return statuses
    }
    
    /// Check if there are any urgent bets (overdue or behind)
    func hasUrgentBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> Bool {
        return placedBets.contains { bet in
            let status = readSlipViewModel.getProgressStatus(for: bet.id)
            return status == .overdue || status == .behind
        }
    }
    
    /// Get summary of all bet statuses
    func getBetStatusSummary(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> (onTrack: Int, ahead: Int, behind: Int, overdue: Int, completed: Int) {
        var onTrack = 0
        var ahead = 0
        var behind = 0
        var overdue = 0
        var completed = 0
        
        for bet in placedBets {
            let status = readSlipViewModel.getProgressStatus(for: bet.id)
            
            switch status {
            case .onTrack:
                onTrack += 1
            case .ahead:
                ahead += 1
            case .behind:
                behind += 1
            case .overdue:
                overdue += 1
            case .completed:
                completed += 1
            }
        }
        
        return (onTrack, ahead, behind, overdue, completed)
    }
    
    // MARK: - Helper Methods (Better MVVM)
    
    /// Get a specific daily bet by its ID
    func getDailyBet(by betId: UUID) -> DailyBet? {
        return dailyBets.first { $0.betId == betId }
    }
    
    /// Get all completed daily bets
    var completedDailyBets: [DailyBet] {
        return dailyBets.filter { $0.isCompleted }
    }
    
    /// Get all incomplete daily bets
    var incompleteDailyBets: [DailyBet] {
        return dailyBets.filter { !$0.isCompleted }
    }
    
    /// Calculate overall daily completion percentage
    var overallCompletionPercentage: Double {
        guard !dailyBets.isEmpty else { return 0.0 }
        let totalProgress = dailyBets.reduce(0.0) { $0 + $1.progressPercentage }
        return totalProgress / Double(dailyBets.count)
    }
    
    /// Get count of completed daily goals
    var completedDailyGoalsCount: Int {
        return completedDailyBets.count
    }
    
    /// Get total daily goals count
    var totalDailyGoalsCount: Int {
        return dailyBets.count
    }
    
    /// Check if all daily goals are completed
    var allDailyGoalsCompleted: Bool {
        return !dailyBets.isEmpty && dailyBets.allSatisfy { $0.isCompleted }
    }
    
    /// Get daily bets sorted by priority (overdue first, then behind, then on track)
    func getDailyBetsSortedByPriority(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [DailyBet] {
        return dailyBets.sorted { bet1, bet2 in
            // First sort by book title for grouping
            if bet1.book.title != bet2.book.title {
                return bet1.book.title < bet2.book.title
            }
            
            // Then sort by day number within same book
            return bet1.dayNumber < bet2.dayNumber
        }
    }
    
    private func getStatusPriority(_ status: ReadingBet.ProgressStatus) -> Int {
        switch status {
        case .overdue: return 0
        case .behind: return 1
        case .onTrack: return 2
        case .ahead: return 3
        case .completed: return 4
        }
    }
}

// MARK: - Extensions for future enhancements
extension DailyBetsViewModel {
    
    /// Get daily progress summary
    func getDailyProgressSummary() -> (completed: Int, total: Int, percentage: Double) {
        let completed = completedDailyGoalsCount
        let total = totalDailyGoalsCount
        let percentage = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, percentage)
    }
    
    /// Get motivational message based on current progress
    func getMotivationalMessage(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> String {
        let summary = getBetStatusSummary(from: placedBets, readSlipViewModel: readSlipViewModel)
        
        if summary.overdue > 0 {
            return "You have \(summary.overdue) overdue bet\(summary.overdue > 1 ? "s" : ""). Focus on catching up!"
        } else if summary.behind > 0 {
            return "You're behind on \(summary.behind) bet\(summary.behind > 1 ? "s" : ""). Time to read!"
        } else if summary.ahead > 0 {
            return "Great job! You're ahead on \(summary.ahead) bet\(summary.ahead > 1 ? "s" : "")!"
        } else if summary.completed > 0 {
            return "Amazing! You've completed \(summary.completed) bet\(summary.completed > 1 ? "s" : "")!"
        } else {
            return "You're on track with all your reading goals!"
        }
    }
    
    /// Get next action suggestion
    func getNextActionSuggestion(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> String {
        let overdue = getOverdueBets(from: placedBets)
        let behind = getBehindScheduleBets(from: placedBets, readSlipViewModel: readSlipViewModel)
        let canGetAhead = getBetsThatCanGetAhead(from: placedBets, readSlipViewModel: readSlipViewModel)
        
        if !overdue.isEmpty {
            return "Start with \(overdue.first!.book.title) - it's overdue!"
        } else if !behind.isEmpty {
            return "Focus on \(behind.first!.book.title) - you're behind schedule."
        } else if !canGetAhead.isEmpty {
            return "You can get ahead on \(canGetAhead.first!.book.title)!"
        } else {
            return "Keep up the great work on your current reading goals!"
        }
    }
}
