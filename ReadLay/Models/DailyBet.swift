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
    
    var progressPercentage: Double {
        return min(Double(currentProgress) / Double(dailyGoal), 1.0)
    }
    
    var isCompleted: Bool {
        return currentProgress >= dailyGoal
    }
}


