//
//  EngagementGoal.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//

import Foundation

struct EngagementGoal: Identifiable, Codable, Hashable {  // ADDED: Hashable
    let id: UUID
    let type: EngagementType
    let targetCount: Int
    var currentCount: Int = 0
    var entries: [String] = []

    var isCompleted: Bool {
        return currentCount >= targetCount
    }

    var progressPercentage: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }

    enum EngagementType: String, CaseIterable, Codable, Hashable {  // ADDED: Hashable
        case quotes = "quotes"
        case thoughts = "thoughts"
        case applications = "applications"
        case questions = "questions"

        var displayName: String {
            switch self {
            case .quotes: return "Write Quotes"
            case .thoughts: return "Personal Thoughts"
            case .applications: return "Real-life Applications"
            case .questions: return "Questions About Content"
            }
        }

        var shortName: String {
            switch self {
            case .quotes: return "Quotes"
            case .thoughts: return "Thoughts"
            case .applications: return "Applications"
            case .questions: return "Questions"
            }
        }

        var description: String {
            switch self {
            case .quotes: return "Extract meaningful quotes or passages"
            case .thoughts: return "Share your personal reactions and insights"
            case .applications: return "How will you apply this in real life?"
            case .questions: return "What questions does this raise for you?"
            }
        }

        var icon: String {
            switch self {
            case .quotes: return "quote.bubble"
            case .thoughts: return "brain.head.profile"
            case .applications: return "arrow.triangle.turn.up.right.diamond"
            case .questions: return "questionmark.bubble"
            }
        }
    }
}
