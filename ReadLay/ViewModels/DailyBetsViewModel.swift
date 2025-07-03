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
    
    // IMPROVED: Better MVVM with ReadSlipViewModel integration
    func updateDailyBets(from placedBets: [ReadingBet], readSlipViewModel: ReadSlipViewModel) {
        dailyBets = placedBets.map { readingBet in
            let currentProgress = readSlipViewModel.getDailyProgress(for: readingBet.id)
            return DailyBet(
                book: readingBet.book,
                dailyGoal: readingBet.pagesPerDay,
                currentProgress: currentProgress,
                totalDays: readingBet.totalDays,
                dayNumber: calculateDayNumber(for: readingBet),
                betId: readingBet.id
            )
        }
    }
    
    // LEGACY: Keep for backward compatibility but prefer the new method above
    func updateDailyBets(from placedBets: [ReadingBet], dailyProgress: [UUID: Int]) {
        dailyBets = placedBets.map { readingBet in
            let currentProgress = dailyProgress[readingBet.id] ?? 0
            return DailyBet(
                book: readingBet.book,
                dailyGoal: readingBet.pagesPerDay,
                currentProgress: currentProgress,
                totalDays: readingBet.totalDays,
                dayNumber: calculateDayNumber(for: readingBet),
                betId: readingBet.id
            )
        }
    }
    
    private func calculateDayNumber(for bet: ReadingBet) -> Int {
        // TODO: Implement sophisticated day calculation with bet start date
        // For now, returning 1 as default
        return 1
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
}

// MARK: - Extensions for future enhancements
extension DailyBetsViewModel {
    
    /// More sophisticated day calculation if you add startDate to ReadingBet
    private func calculateDayNumberWithDate(for bet: ReadingBet, startDate: Date) -> Int {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(daysDifference + 1, bet.totalDays) // Ensure we don't exceed total days
    }
    
    /// Get daily progress summary
    func getDailyProgressSummary() -> (completed: Int, total: Int, percentage: Double) {
        let completed = completedDailyGoalsCount
        let total = totalDailyGoalsCount
        let percentage = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, percentage)
    }
}
