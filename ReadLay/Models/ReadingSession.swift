//
//  ReadingSession.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI
import Foundation

struct ReadingSession: Identifiable {
    let id = UUID()
    let betId: UUID
    let startTime: Date
    var endTime: Date?
    var startingPage: Int = 0
    var endingPage: Int = 0
    var isCompleted: Bool = false
    var comment: String = "" // NEW: Mandatory comment/takeaway
    
    // FIXED: Correct page counting (inclusive)
    var pagesRead: Int {
        guard endingPage > 0 && startingPage > 0 else { return 0 }
        return max(0, endingPage - startingPage + 1)
    }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct CompletedBet: Identifiable {
    let id = UUID()
    let originalBet: ReadingBet
    let completedDate: Date
    let totalPagesRead: Int
    let wasSuccessful: Bool
    let payout: Double
}
