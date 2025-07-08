//
//  ActiveReadingBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//

import SwiftUI

// MARK: - ActiveReadingBetRowView (Enhanced with day tracking)
struct ActiveReadingBetRowView: View {
    let bet: ReadingBet
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    
    // ADDED: Progress status and day tracking
    private var progressStatus: ReadingBet.ProgressStatus {
        return readSlipViewModel.getProgressStatus(for: bet.id)
    }
    
    private var progressInfo: (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        return readSlipViewModel.getProgressInfo(for: bet.id)
    }
    
    private var currentPage: Int {
        return readSlipViewModel.getTotalProgress(for: bet.id)
    }
    
    private var progressPercentage: Double {
        guard bet.book.totalPages > 0 else { return 0.0 }
        let percentage = Double(currentPage) / Double(bet.book.totalPages)
        return min(max(percentage, 0.0), 1.0)
    }
    
    private var isCompleted: Bool {
        return readSlipViewModel.isBookCompleted(for: bet.id)
    }
    
    // ADDED: Status-based styling
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
            // ADDED: Day tracking section
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
                
                // ADDED: Status indicator
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
    
    // MARK: - Day Tracking Section (NEW)
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
                    Text("\(bet.currentDay) of \(bet.totalDays)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
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
                
                // Expected vs actual progress
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expected Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text("\(progressInfo.expected) pages")
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
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reading Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Spacer()
                Text("\(currentPage)/\(bet.book.totalPages) pages")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
            }
            
            progressBar
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let progressWidth = totalWidth * progressPercentage
            let targetPosition = totalWidth - 10
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.goodreadsBeige)
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                statusColor,
                                statusColor.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(progressWidth, 0), height: 8)
                
                // Start marker (0)
                VStack(spacing: 2) {
                    Text("0")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.goodreadsAccent)
                    Circle()
                        .fill(Color.goodreadsAccent.opacity(0.7))
                        .frame(width: 10, height: 10)
                        .offset(y: 4)
                }
                .offset(x: -5, y: -8)
                
                // End marker (total pages)
                VStack(spacing: 2) {
                    Text("\(bet.book.totalPages)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isCompleted ? .green : statusColor)
                    Circle()
                        .fill(isCompleted ? Color.green : statusColor)
                        .frame(width: 10, height: 10)
                        .offset(y: 4)
                }
                .offset(x: targetPosition - 5, y: -8)
                
                // Current progress marker
                if progressPercentage > 0.02 && !isCompleted {
                    VStack(spacing: 2) {
                        Text("\(currentPage)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(statusColor)
                            )
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(statusColor, lineWidth: 2)
                            )
                            .offset(y: 4)
                    }
                    .offset(x: min(progressWidth - 5, totalWidth - 15), y: -12)
                }
                
                // ADDED: Expected progress marker (where you should be)
                if !isCompleted {
                    let expectedPercentage = Double(progressInfo.expected) / Double(bet.book.totalPages)
                    let expectedPosition = totalWidth * expectedPercentage
                    
                    VStack(spacing: 2) {
                        Text("Target")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.gray)
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .fill(Color.clear)
                            .frame(width: 8, height: 8)
                            .offset(y: 4)
                    }
                    .offset(x: min(expectedPosition - 5, totalWidth - 15), y: -12)
                }
            }
        }
        .frame(height: 26)
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
            
            // ADDED: Show if user can get ahead
            if readSlipViewModel.canGetAhead(for: bet.id) {
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
