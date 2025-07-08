//
//  DailyBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import Combine

struct DailyBet: Identifiable {
    let id = UUID()
    let book: Book
    let dailyGoal: Int // pages to read today
    let currentProgress: Int // pages read so far today
    let totalDays: Int
    let dayNumber: Int
    let betId: UUID // Reference to original bet
    
    // ADDED: Multi-day tracking properties
    let startDate: Date
    let isOverdue: Bool
    let canGetAhead: Bool
    let dayStartPage: Int  // Starting page for this day
    let dayEndPage: Int    // Ending page for this day
    let isNextDay: Bool    // Whether this is the next day to start
    
    var progressPercentage: Double {
        return min(Double(currentProgress) / Double(dailyGoal), 1.0)
    }
    
    var isCompleted: Bool {
        return currentProgress >= dailyGoal
    }
    
    // ADDED: Enhanced initializer with multi-day support
    init(
        book: Book,
        dailyGoal: Int,
        currentProgress: Int,
        totalDays: Int,
        dayNumber: Int,
        betId: UUID,
        startDate: Date = Date(),
        isOverdue: Bool = false,
        canGetAhead: Bool = false,
        dayStartPage: Int = 1,
        dayEndPage: Int = 0,
        isNextDay: Bool = false
    ) {
        self.book = book
        self.dailyGoal = dailyGoal
        self.currentProgress = currentProgress
        self.totalDays = totalDays
        self.dayNumber = dayNumber
        self.betId = betId
        self.startDate = startDate
        self.isOverdue = isOverdue
        self.canGetAhead = canGetAhead
        self.dayStartPage = dayStartPage
        self.dayEndPage = dayEndPage == 0 ? dailyGoal : dayEndPage
        self.isNextDay = isNextDay
    }
    
    // ADDED: Convenience properties for multi-day tracking
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: startDate)
    }
    
    var daysRemaining: Int {
        return max(0, totalDays - dayNumber + 1)
    }
    
    var formattedTimeRemaining: String {
        if isOverdue {
            return "Overdue"
        }
        
        let days = daysRemaining
        if days == 1 {
            return "1 day left"
        } else {
            return "\(days) days left"
        }
    }
    
    // ADDED: Page range for this specific day
    var pageRange: String {
        return "\(dayStartPage)-\(dayEndPage)"
    }
    
    // ADDED: Progress within this day's range
    var dayProgressPercentage: Double {
        guard dailyGoal > 0 else { return 0.0 }
        return min(Double(currentProgress) / Double(dailyGoal), 1.0)
    }
    
    // ADDED: Status for this specific day
    var dayStatus: DayStatus {
        if isNextDay {
            return .upcoming
        } else if isCompleted {
            return .completed
        } else if isOverdue {
            return .overdue
        } else if canGetAhead && isCompleted {
            return .canAdvance
        } else {
            return .inProgress
        }
    }
    
    enum DayStatus {
        case upcoming
        case inProgress
        case completed
        case overdue
        case canAdvance
    }
}

// MARK: - Static Helper Methods
extension DailyBet {
    
    /// Create a DailyBet from a ReadingBet with enhanced data
    static func from(_ readingBet: ReadingBet, currentProgress: Int, readSlipViewModel: ReadSlipViewModel) -> DailyBet {
        let progressStatus = readSlipViewModel.getProgressStatus(for: readingBet.id)
        
        return DailyBet(
            book: readingBet.book,
            dailyGoal: readingBet.pagesPerDay,
            currentProgress: currentProgress,
            totalDays: readingBet.totalDays,
            dayNumber: readingBet.currentDay,
            betId: readingBet.id,
            startDate: readingBet.startDate,
            isOverdue: progressStatus == .overdue,
            canGetAhead: readSlipViewModel.canGetAhead(for: readingBet.id)
        )
    }
    
    /// Create a multi-day DailyBet with specific day range
    static func forDay(
        _ day: Int,
        readingBet: ReadingBet,
        totalProgress: Int,
        readSlipViewModel: ReadSlipViewModel,
        isNextDay: Bool = false
    ) -> DailyBet {
        let dayStartPage = (day - 1) * readingBet.pagesPerDay + 1
        let dayEndPage = min(day * readingBet.pagesPerDay, readingBet.book.totalPages)
        let dayGoal = dayEndPage - dayStartPage + 1
        
        // Calculate progress for this specific day
        let progressInThisDay = max(0, min(totalProgress - dayStartPage + 1, dayGoal))
        let currentDayProgress = isNextDay ? 0 : max(0, progressInThisDay)
        
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
}
