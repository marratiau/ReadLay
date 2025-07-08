//
//  ReadingBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//
//  ReadingBet.swift - UPDATED EXISTING FILE
//  Key changes: Made currentDay mutable to support day progression

import SwiftUI
import Foundation

struct ReadingBet: Identifiable, Hashable {
    let id: UUID
    let book: Book
    let timeframe: String
    let odds: String
    var wager: Double
    let pagesPerDay: Int
    let totalDays: Int
    
    // ADDED: Day tracking properties
    let startDate: Date
    let targetEndDate: Date
    
    // UPDATED: Made currentDay mutable and computed from start date
    private var _currentDay: Int? = nil
    
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
    
    // ADDED: Initialize with day tracking
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
    
    // ADDED: Days remaining calculation
    var daysRemaining: Int {
        return max(0, totalDays - currentDay + 1)
    }
    
    // ADDED: Check if bet is overdue
    var isOverdue: Bool {
        return currentDay > totalDays
    }
    
    // ADDED: Check if user is behind schedule
    var isBehindSchedule: Bool {
        let expectedProgress = currentDay * pagesPerDay
        // This will be compared with actual progress from ReadSlipViewModel
        return false // Will be calculated in ReadSlipViewModel
    }
    
    // ADDED: Check if user is ahead of schedule
    var isAheadOfSchedule: Bool {
        let expectedProgress = currentDay * pagesPerDay
        // This will be compared with actual progress from ReadSlipViewModel
        return false // Will be calculated in ReadSlipViewModel
    }
    
    // ADDED: Progress status enum
    enum ProgressStatus {
        case onTrack
        case ahead
        case behind
        case overdue
        case completed
    }
    
    // ADDED: Get progress status (will be calculated in ReadSlipViewModel with actual progress)
    func getProgressStatus(actualProgress: Int) -> ProgressStatus {
        if actualProgress >= book.totalPages {
            return .completed
        }
        
        if isOverdue {
            return .overdue
        }
        
        let expectedProgress = currentDay * pagesPerDay
        
        if actualProgress >= expectedProgress + pagesPerDay {
            return .ahead
        } else if actualProgress < expectedProgress - pagesPerDay {
            return .behind
        } else {
            return .onTrack
        }
    }
    
    // ADDED: Formatted time remaining
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
    
    // ADDED: Formatted start date
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
    
    // ADDED: Formatted target end date
    var formattedTargetEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetEndDate)
    }
    
    private func parseOdds(_ odds: String) -> Int {
        let cleanOdds = odds.replacingOccurrences(of: "+", with: "")
        return Int(cleanOdds) ?? 150
    }
}

// ADDED: Extension for day tracking utilities
extension ReadingBet {
    
    /// Get the expected pages that should be read by a specific day
    func expectedPagesByDay(_ day: Int) -> Int {
        return min(day * pagesPerDay, book.totalPages)
    }
    
    /// Get the expected pages that should be read by today
    var expectedPagesToday: Int {
        return expectedPagesByDay(currentDay)
    }
    
    /// Check if a specific day's goal can be worked on (for "get ahead" functionality)
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
    
    /// ADDED: Advance to next day
    mutating func advanceToNextDay() {
        if currentDay < totalDays {
            _currentDay = currentDay + 1
        }
    }
}
