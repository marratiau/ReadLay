//
//  DailyBetsViewModel.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

import SwiftUI
import Combine

class DailyBetsViewModel: ObservableObject {
    @Published var dailyBets: [DailyBet] = []
    
    // ADDED: Multi-day tracking
    func updateDailyBetsWithMultiDay(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) {
        var newDailyBets: [DailyBet] = []
        
        for readingBet in placedBets {
            let totalProgress = readSlipViewModel.getTotalProgress(for: readingBet.id)
            let currentDay = readingBet.currentDay
            
            // Create daily bets for all days up to current day
            for day in 1...currentDay {
                let dailyBet = createDailyBetForDay(
                    day: day,
                    readingBet: readingBet,
                    totalProgress: totalProgress,
                    readSlipViewModel: readSlipViewModel
                )
                newDailyBets.append(dailyBet)
            }
            
            // If current day goal is completed and can get ahead, prepare next day
            let canGetAhead = readSlipViewModel.canGetAhead(for: readingBet.id)
            if canGetAhead && currentDay < readingBet.totalDays {
                let nextDay = currentDay + 1
                let nextDayBet = createDailyBetForDay(
                    day: nextDay,
                    readingBet: readingBet,
                    totalProgress: totalProgress,
                    readSlipViewModel: readSlipViewModel,
                    isNextDay: true
                )
                newDailyBets.append(nextDayBet)
            }
        }
        
        dailyBets = newDailyBets
    }
    
    // ADDED: Create daily bet for specific day
    private func createDailyBetForDay(
        day: Int,
        readingBet: ReadingBet,
        totalProgress: Int,
        readSlipViewModel: ReadSlipViewModel,
        isNextDay: Bool = false
    ) -> DailyBet {
        
        // Calculate day-specific progress
        let dayStartPage = (day - 1) * readingBet.pagesPerDay + 1
        let dayEndPage = min(day * readingBet.pagesPerDay, readingBet.book.totalPages)
        let dayGoal = dayEndPage - dayStartPage + 1
        
        // Calculate current progress for this specific day
        let currentDayProgress: Int
        if isNextDay {
            currentDayProgress = 0 // Next day hasn't started yet
        } else {
            let progressInThisDay = max(0, min(totalProgress - dayStartPage + 1, dayGoal))
            currentDayProgress = max(0, progressInThisDay)
        }
        
        // Determine completion status
        let isCompleted = currentDayProgress >= dayGoal
        let progressStatus = readSlipViewModel.getProgressStatus(for: readingBet.id)
        let canGetAhead = readSlipViewModel.canGetAhead(for: readingBet.id) && day == readingBet.currentDay
        
        return DailyBet(
            book: readingBet.book,
            dailyGoal: dayGoal,
            currentProgress: currentDayProgress,
            totalDays: readingBet.totalDays,
            dayNumber: day,
            betId: readingBet.id,
            startDate: readingBet.startDate,
            isOverdue: progressStatus == .overdue && day == readingBet.currentDay,
            canGetAhead: canGetAhead,
            dayStartPage: dayStartPage,
            dayEndPage: dayEndPage,
            isNextDay: isNextDay
        )
    }
    
    // LEGACY: Keep for backward compatibility but prefer the new method above
    func updateDailyBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) {
        // Use the new multi-day method
        updateDailyBetsWithMultiDay(from: placedBets, readSlipViewModel: readSlipViewModel)
    }
    
    // LEGACY: Keep for backward compatibility but prefer the new method above
    func updateDailyBets(from placedBets: [ReadingBet], dailyProgress: [UUID: Int]) {
        dailyBets = placedBets.map { readingBet in
            let currentProgress = dailyProgress[readingBet.id] ?? 0
            let actualDay = readingBet.currentDay
            
            return DailyBet(
                book: readingBet.book,
                dailyGoal: readingBet.pagesPerDay,
                currentProgress: currentProgress,
                totalDays: readingBet.totalDays,
                dayNumber: actualDay,
                betId: readingBet.id
            )
        }
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
