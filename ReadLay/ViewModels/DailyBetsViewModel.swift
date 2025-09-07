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
    
    // FIXED: Optimized to avoid O(n²) complexity
    func updateDailyBetsWithMultiDay(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) {
        // Pre-calculate all progress data once
        let progressMap = Dictionary(uniqueKeysWithValues:
            placedBets.map { bet in
                (bet.id, readSlipViewModel.getTotalProgress(for: bet.id))
            }
        )
         
        // Use flatMap for efficient generation
        dailyBets = placedBets.flatMap { bet -> [DailyBet] in
            let totalProgress = progressMap[bet.id] ?? 0
            let currentDay = bet.currentDay
            var bets: [DailyBet] = []
            
            // Only show current day (not all previous days)
            let currentDayBet = DailyBet.forDay(
                currentDay,
                readingBet: bet,
                totalProgress: totalProgress,
                readSlipViewModel: readSlipViewModel,
                isNextDay: false
            )
            bets.append(currentDayBet)
            
            // Show next day if can get ahead
            if readSlipViewModel.canGetAhead(for: bet.id) && currentDay < bet.totalDays {
                let nextDayBet = DailyBet.forDay(
                    currentDay + 1,
                    readingBet: bet,
                    totalProgress: totalProgress,
                    readSlipViewModel: readSlipViewModel,
                    isNextDay: true
                )
                bets.append(nextDayBet)
            }
            
            return bets
        }
    }
    
    func getOverdueBets(from placedBets: [ReadingBet]) -> [ReadingBet] {
        return placedBets.filter { $0.isOverdue }
    }
    
    func getBehindScheduleBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [ReadingBet] {
        return placedBets.filter { bet in
            let actualProgress = readSlipViewModel.getTotalProgress(for: bet.id)
            return bet.getProgressStatus(actualProgress: actualProgress) == .behind
        }
    }
    
    func getAheadOfScheduleBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [ReadingBet] {
        return placedBets.filter { bet in
            let actualProgress = readSlipViewModel.getTotalProgress(for: bet.id)
            return bet.getProgressStatus(actualProgress: actualProgress) == .ahead
        }
    }
    
    func getBetsThatCanGetAhead(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [ReadingBet] {
        return placedBets.filter { bet in
            readSlipViewModel.canGetAhead(for: bet.id)
        }
    }
    
    func getBetStatuses(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [UUID: ReadingBet.ProgressStatus] {
        var statuses: [UUID: ReadingBet.ProgressStatus] = [:]
        for bet in placedBets {
            statuses[bet.id] = readSlipViewModel.getProgressStatus(for: bet.id)
        }
        return statuses
    }
    
    func hasUrgentBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> Bool {
        return placedBets.contains { bet in
            let status = readSlipViewModel.getProgressStatus(for: bet.id)
            return status == .overdue || status == .behind
        }
    }
    
    func getBetStatusSummary(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> BetStatusSummary {
        var summary = BetStatusSummary(onTrack: 0, ahead: 0, behind: 0, overdue: 0, completed: 0)
        
        for bet in placedBets {
            switch readSlipViewModel.getProgressStatus(for: bet.id) {
            case .onTrack:   summary.onTrack += 1
            case .ahead:     summary.ahead += 1
            case .behind:    summary.behind += 1
            case .overdue:   summary.overdue += 1
            case .completed: summary.completed += 1
            }
        }
        
        return summary
    }
    
    func getDailyBet(by betId: UUID) -> DailyBet? {
        return dailyBets.first { $0.betId == betId }
    }
    
    var completedDailyBets: [DailyBet] {
        return dailyBets.filter { $0.isCompleted }
    }
    
    var incompleteDailyBets: [DailyBet] {
        return dailyBets.filter { !$0.isCompleted }
    }
    
    var overallCompletionPercentage: Double {
        guard !dailyBets.isEmpty else { return 0.0 }
        let totalProgress = dailyBets.reduce(0.0) { $0 + $1.progressPercentage }
        return totalProgress / Double(dailyBets.count)
    }
    
    var completedDailyGoalsCount: Int {
        return completedDailyBets.count
    }
    
    var totalDailyGoalsCount: Int {
        return dailyBets.count
    }
    
    var allDailyGoalsCompleted: Bool {
        return !dailyBets.isEmpty && dailyBets.allSatisfy { $0.isCompleted }
    }
    
    func getDailyBetsSortedByPriority(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> [DailyBet] {
        return dailyBets.sorted { bet1, bet2 in
            if bet1.book.title != bet2.book.title {
                return bet1.book.title < bet2.book.title
            }
            return bet1.dayNumber < bet2.dayNumber
        }
    }
    
    func getDailyProgressSummary() -> (completed: Int, total: Int, percentage: Double) {
        let completed = completedDailyGoalsCount
        let total = totalDailyGoalsCount
        let percentage = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, percentage)
    }
    
    func getMotivationalMessage(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) -> String {
        let summary = getBetStatusSummary(from: placedBets, readSlipViewModel: readSlipViewModel)
        
        if summary.overdue > 0 {
            return "You have \(summary.overdue) overdue bet\(summary.overdue > 1 ? "s" : ""). Focus on catching up!"
        } else if summary.behind > 0 {
            return "You're behind on \(summary.behind) bet\(summary.behind > 1 ? "s" : ""). Time to read!"
        } else if summary.ahead > 0 {
            return "You're ahead on \(summary.ahead) bet\(summary.ahead > 1 ? "s" : "")!"
        } else if summary.completed > 0 {
            return "You've completed \(summary.completed) bet\(summary.completed > 1 ? "s" : "")!"
        } else {
            return "You're on track with all your reading goals!"
        }
    }
    
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
