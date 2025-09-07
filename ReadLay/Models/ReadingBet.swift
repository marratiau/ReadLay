//
//  ReadingBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import Foundation

struct ReadingBet: Identifiable, Hashable, Equatable {
    let id: UUID
    let book: Book
    let timeframe: String
    let odds: String
    var wager: Double
    let pagesPerDay: Int
    let totalDays: Int

    // Day tracking properties
    let startDate: Date
    let targetEndDate: Date

    // Made currentDay mutable and computed from start date
    private var _currentDay: Int?

    var currentDay: Int {
        get {
            if let overrideDay = _currentDay {
                return overrideDay
            }
            // Calculate based on start date
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            return min(max(daysSinceStart + 1, 1), totalDays)
        }
        set {
            _currentDay = newValue
        }
    }

    // Initialize with day tracking
    init(id: UUID = UUID(), book: Book, timeframe: String, odds: String, wager: Double, pagesPerDay: Int, totalDays: Int) {
        self.id = id
        self.book = book
        self.timeframe = timeframe
        self.odds = odds
        self.wager = wager
        self.pagesPerDay = pagesPerDay
        self.totalDays = totalDays

        // Set start date to today
        self.startDate = Date()
        // Calculate target end date
        self.targetEndDate = Calendar.current.date(byAdding: .day, value: totalDays - 1, to: startDate) ?? startDate
    }

    var potentialWin: Double {
        let oddsValue = parseOdds(odds)
        return wager * (Double(oddsValue) / 100.0)
    }

    var totalPayout: Double {
        return wager + potentialWin
    }

    // Days remaining calculation
    var daysRemaining: Int {
        return max(0, totalDays - currentDay + 1)
    }

    // Check if bet is overdue
    var isOverdue: Bool {
        return currentDay > totalDays
    }

    // Check if user is behind schedule
    var isBehindSchedule: Bool {
        let expectedProgress = currentDay * pagesPerDay
        // This will be compared with actual progress from ReadSlipViewModel
        return false // Will be calculated in ReadSlipViewModel
    }

    // Check if user is ahead of schedule
    var isAheadOfSchedule: Bool {
        let expectedProgress = currentDay * pagesPerDay
        // This will be compared with actual progress from ReadSlipViewModel
        return false // Will be calculated in ReadSlipViewModel
    }

    // Progress status enum
    enum ProgressStatus {
        case onTrack
        case ahead
        case behind
        case overdue
        case completed
    }

    // FIXED: Get progress status using effective page calculations
    func getProgressStatus(actualProgress: Int) -> ProgressStatus {
        if actualProgress >= book.readingEndPage {
            return .completed
        }

        if isOverdue {
            return .overdue
        }

        let expectedProgress = expectedPagesToday

        if actualProgress >= expectedProgress + pagesPerDay {
            return .ahead
        } else if actualProgress < expectedProgress - pagesPerDay {
            return .behind
        } else {
            return .onTrack
        }
    }

    // Formatted time remaining
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

    // Formatted start date
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }

    // Formatted target end date
    var formattedTargetEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetEndDate)
    }

    private func parseOdds(_ odds: String) -> Int {
        let cleanOdds = odds.replacingOccurrences(of: "+", with: "")
        return Int(cleanOdds) ?? 150
    }
    // Add these implementations
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ReadingBet, rhs: ReadingBet) -> Bool {
        return lhs.id == rhs.id
    }
}

// ADDED: Extension for day tracking utilities using effective pages
extension ReadingBet {

    /// FIXED: Get the expected pages that should be read by a specific day (using effective pages)
    func expectedPagesByDay(_ day: Int) -> Int {
        let effectiveTarget = min(day * pagesPerDay, book.effectiveTotalPages)
        return book.readingStartPage + effectiveTarget - 1
    }

    /// FIXED: Get the expected pages that should be read by today (using effective pages)
    var expectedPagesToday: Int {
        return expectedPagesByDay(currentDay)
    }

    /// FIXED: Check if a specific day's goal can be worked on (using reading range)
    func canWorkOnDay(_ day: Int, actualProgress: Int) -> Bool {
        guard day <= totalDays else { return false }

        // Can work on a day if you've completed all previous days
        let previousDayTarget = expectedPagesByDay(day - 1)
        return actualProgress >= previousDayTarget
    }

    /// Get the next available day to work on
    func getNextAvailableDay(actualProgress: Int) -> Int {
        for day in currentDay...totalDays {
            if canWorkOnDay(day, actualProgress: actualProgress) {
                return day
            }
        }
        return currentDay
    }

    /// Advance to next day
    mutating func advanceToNextDay() {
        if currentDay < totalDays {
            _currentDay = currentDay + 1
        }
    }
}
