//
//  JournalEntry.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI
import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let bookId: UUID
    let bookTitle: String
    let bookAuthor: String?
    let date: Date
    let comment: String // Main reading comment/takeaway
    let engagementEntries: [EngagementEntry] // Quotes, thoughts, etc.
    let sessionDuration: TimeInterval
    let pagesRead: Int
    let startingPage: Int
    let endingPage: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let hours = Int(sessionDuration) / 3600
        let minutes = Int(sessionDuration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var hasEngagementContent: Bool {
        return !engagementEntries.isEmpty
    }
}

struct EngagementEntry: Identifiable, Codable {
    let id: UUID
    let type: EngagementGoal.EngagementType
    let content: String
    let timestamp: Date
}
