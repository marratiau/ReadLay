//
//  BookJournalSummary.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/8/25.
//

import SwiftUI
// MARK: - Book Journal Summary Data Model (NEW STRUCT)
struct BookJournalSummary: Identifiable {
    let id = UUID()
    let bookId: UUID
    let bookTitle: String
    let bookAuthor: String?
    let totalSessions: Int
    let totalTime: TimeInterval
    let totalPages: Int
    let lastSession: Date
    let entries: [JournalEntry]

    var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var formattedLastSession: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: lastSession, relativeTo: Date())
    }
}
