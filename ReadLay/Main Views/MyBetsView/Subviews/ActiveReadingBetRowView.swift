//  ActiveReadingBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//

import SwiftUI

struct ActiveReadingBetRowView: View {
    let bet: ReadingBet
    @ObservedObject var readSlipViewModel: ReadSlipViewModel

    // FIXED: Use current page position and effective pages
    private var currentPage: Int {
        return readSlipViewModel.getCurrentPagePosition(for: bet.id)
    }

    // FIXED: Get progress in pages (within reading range) without binding issues
    private var progressInPages: Int {
        let currentPosition = readSlipViewModel.getCurrentPagePosition(for: bet.id)
        
        // If current position is before reading start page, no progress yet
        if currentPosition < bet.book.readingStartPage {
            return 0
        }
        
        // Progress is how many pages into the reading range we are
        return currentPosition - bet.book.readingStartPage + 1
    }

    // Get total pages read for additional context
    private var totalPagesRead: Int {
        return readSlipViewModel.getTotalPagesRead(for: bet.id)
    }

    // FIXED: Progress percentage based on reading range, not absolute position
    private var progressPercentage: Double {
        guard bet.book.effectiveTotalPages > 0 else { return 0.0 }
        let percentage = Double(progressInPages) / Double(bet.book.effectiveTotalPages)
        return min(max(percentage, 0.0), 1.0)
    }

    // FIXED: Check completion using reading end page
    private var isCompleted: Bool {
        guard let bet = readSlipViewModel.placedBets.first(where: { $0.id == bet.id }) else { return false }
        let currentPage = readSlipViewModel.getCurrentPagePosition(for: bet.id)
        return currentPage >= bet.book.readingEndPage
    }

    // Get progress status and info
    private var progressStatus: ReadingBet.ProgressStatus {
        guard let currentBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.id }) else { return .onTrack }
        let currentPage = readSlipViewModel.getCurrentPagePosition(for: bet.id)
        return currentBet.getProgressStatus(actualProgress: currentPage)
    }

    private var progressInfo: (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        guard let currentBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.id }) else {
            return (0, 0, .onTrack)
        }

        let actualProgress = readSlipViewModel.getProgressInPages(for: bet.id)
        let expectedPagesFromStart = (currentBet.book.effectiveTotalPages * currentBet.currentDay) / currentBet.totalDays
        let expectedProgress = expectedPagesFromStart

        let currentPosition = readSlipViewModel.getCurrentPagePosition(for: bet.id)
        let status = currentBet.getProgressStatus(actualProgress: currentPosition)

        return (actualProgress, expectedProgress, status)
    }

    // FIXED: Dynamic target calculation using effective pages
    private var currentDayTarget: Int {
        return bet.book.readingStartPage + (bet.pagesPerDay * bet.currentDay) - 1
    }

    private var nextDayTarget: Int? {
        guard bet.currentDay < bet.totalDays else { return nil }
        return bet.book.readingStartPage + (bet.pagesPerDay * (bet.currentDay + 1)) - 1
    }

    private var isCurrentDayCompleted: Bool {
        return currentPage >= currentDayTarget
    }

    // FIXED: Handle canGetAhead check without binding issues
    private var canGetAheadCheck: Bool {
        guard let currentBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.id }) else { return false }
        let currentPagePosition = readSlipViewModel.getCurrentPagePosition(for: bet.id)
        let currentDayTarget = currentBet.book.readingStartPage + (currentBet.pagesPerDay * currentBet.currentDay) - 1
        return currentPagePosition >= currentDayTarget && currentBet.currentDay < currentBet.totalDays
    }

    // Status-based styling
    private var statusColor: Color {
        switch progressStatus {
        case .completed: return .green
        case .ahead: return .blue
        case .behind: return .orange
        case .overdue: return .red
        case .onTrack: return .goodreadsAccent
        }
    }

    private var statusText: String {
        switch progressStatus {
        case .completed: return "COMPLETED"
        case .ahead: return "AHEAD OF SCHEDULE"
        case .behind: return "BEHIND SCHEDULE"
        case .overdue: return "OVERDUE"
        case .onTrack: return "ON TRACK"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            headerSection
            dayTrackingSection
            progressSection
            dailyGoalSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private var statusBorderColor: Color {
        switch progressStatus {
        case .completed: return Color.green.opacity(0.4)
        case .ahead: return Color.blue.opacity(0.4)
        case .behind: return Color.orange.opacity(0.4)
        case .overdue: return Color.red.opacity(0.4)
        case .onTrack: return Color.goodreadsAccent.opacity(0.2)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bet.book.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(2)

                Text("to complete in \(bet.timeframe)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)

                HStack(spacing: 8) {
                    Text("$\(bet.wager, specifier: "%.0f") bet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsBrown.opacity(0.8))

                    Text("•")
                        .foregroundColor(.goodreadsAccent.opacity(0.5))

                    Text("Win $\(bet.potentialWin, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(bet.odds)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )

                Text(statusText)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor)
                    )
            }
        }
    }

    // MARK: - Day Tracking Section
    private var dayTrackingSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Schedule Progress")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                Spacer()
            }

            HStack(spacing: 16) {
                // Current day
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Day")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    HStack(spacing: 4) {
                        Text("\(bet.currentDay) of \(bet.totalDays)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.goodreadsBrown)

                        if isCurrentDayCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                }

                // Time remaining
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text(bet.formattedTimeRemaining)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(bet.isOverdue ? .red : .goodreadsBrown)
                }

                Spacer()

                // Current target
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isCurrentDayCompleted ? "Next Target" : "Today's Target")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text("Page \(isCurrentDayCompleted ? (nextDayTarget ?? bet.book.readingEndPage) : currentDayTarget)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(statusColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Progress Section (FIXED FOR CUSTOM READING RANGE)
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reading Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Spacer()
                // FIXED: Show progress within reading range
                if progressInPages == 0 {
                    Text("Not started (\(bet.book.effectiveTotalPages) pages to read)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                } else {
                    Text("\(progressInPages) of \(bet.book.effectiveTotalPages) pages")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
            }

            // FIXED: Custom progress bar that handles reading range
            CustomRangeProgressBar(
                progressInPages: progressInPages,
                totalEffectivePages: bet.book.effectiveTotalPages,
                currentPagePosition: currentPage,
                readingStartPage: bet.book.readingStartPage,
                readingEndPage: bet.book.readingEndPage,
                targetPage: currentDayTarget,
                progressColor: statusColor,
                isCompleted: isCompleted
            )

            // FIXED: Show actual page position and total pages read
            HStack {
                if currentPage >= bet.book.readingStartPage {
                    Text("Current Position: Page \(currentPage)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                } else {
                    Text("Ready to start at page \(bet.book.readingStartPage)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                }
                Spacer()
                Text("\(totalPagesRead) total pages read")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsBrown.opacity(0.8))
            }
        }
    }

    // MARK: - Daily Goal Section
    private var dailyGoalSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Goal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Text("\(bet.pagesPerDay) pages/day")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
            }

            Spacer()

            // Show if user can get ahead
            if canGetAheadCheck {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Can Get Ahead!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Today's goal completed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Started")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text(bet.formattedStartDate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Custom Progress Bar for Reading Range
struct CustomRangeProgressBar: View {
    let progressInPages: Int
    let totalEffectivePages: Int
    let currentPagePosition: Int
    let readingStartPage: Int
    let readingEndPage: Int
    let targetPage: Int
    let progressColor: Color
    let isCompleted: Bool
    
    private var progressPercentage: Double {
        guard totalEffectivePages > 0 else { return 0.0 }
        return Double(progressInPages) / Double(totalEffectivePages)
    }
    
    private var targetPercentage: Double {
        guard totalEffectivePages > 0 else { return 0.0 }
        let targetProgress = max(0, targetPage - readingStartPage + 1)
        return Double(targetProgress) / Double(totalEffectivePages)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.goodreadsAccent.opacity(0.2))
                .frame(height: 8)
            
            // Target marker
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.orange.opacity(0.3))
                .frame(width: max(0, CGFloat(targetPercentage) * 200), height: 8)
            
            // Progress fill
            RoundedRectangle(cornerRadius: 4)
                .fill(progressColor)
                .frame(width: max(0, CGFloat(progressPercentage) * 200), height: 8)
        }
        .frame(maxWidth: 200)
    }
}
