//
//  ActiveReadingBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//
//  ActiveReadingBetRowView.swift - FIXED WITH TRUE FANDUEL-STYLE PROGRESS
//  Key changes: Thinner progress bar + bigger dots on top + numbers hovering above

import SwiftUI

struct ActiveReadingBetRowView: View {
    let bet: ReadingBet
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    
    // FIXED: Use current page position instead of total progress
    private var currentPage: Int {
        return readSlipViewModel.getCurrentPagePosition(for: bet.id)
    }
    
    // ADDED: Get total pages read for additional context
    private var totalPagesRead: Int {
        return readSlipViewModel.getTotalPagesRead(for: bet.id)
    }
    
    private var progressPercentage: Double {
        guard bet.book.totalPages > 0 else { return 0.0 }
        let percentage = Double(currentPage) / Double(bet.book.totalPages)
        return min(max(percentage, 0.0), 1.0)
    }
    
    private var isCompleted: Bool {
        return readSlipViewModel.isBookCompleted(for: bet.id)
    }
    
    // ADDED: Progress status and info
    private var progressStatus: ReadingBet.ProgressStatus {
        return readSlipViewModel.getProgressStatus(for: bet.id)
    }
    
    private var progressInfo: (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        return readSlipViewModel.getProgressInfo(for: bet.id)
    }
    
    // ADDED: Dynamic target calculation
    private var currentDayTarget: Int {
        return bet.pagesPerDay * bet.currentDay
    }
    
    private var nextDayTarget: Int? {
        guard bet.currentDay < bet.totalDays else { return nil }
        return bet.pagesPerDay * (bet.currentDay + 1)
    }
    
    private var isCurrentDayCompleted: Bool {
        return currentPage >= currentDayTarget
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
    
    // MARK: - Day Tracking Section (UPDATED WITH DYNAMIC TARGETS)
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
                    Text("Page \(isCurrentDayCompleted ? (nextDayTarget ?? bet.book.totalPages) : currentDayTarget)")
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
    
    // MARK: - Progress Section (UPDATED WITH TRUE FANDUEL-STYLE PROGRESS BAR)
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reading Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Spacer()
                Text("Page \(currentPage) of \(bet.book.totalPages)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
            }
            
            // UPDATED: True FanDuel-style progress bar
            trueFanDuelStyleProgressBar
            
            HStack {
                Text("Total Pages Read")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsAccent.opacity(0.8))
                Spacer()
                Text("\(totalPagesRead) pages")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsBrown.opacity(0.8))
            }
        }
    }
    
    // MARK: - TRUE FANDUEL-STYLE PROGRESS BAR (THIN BAR + BIG DOTS ON TOP + NUMBERS ABOVE)
    private var trueFanDuelStyleProgressBar: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let fillWidth = barWidth * progressPercentage
            let barHeight: CGFloat = 10 // Thinner progress bar
            let dotSize: CGFloat = 18 // Bigger dots
            
            VStack(spacing: 0) {
                // Numbers hovering above dots
                HStack {
                    // Start number (Page 1)
                    Text("1")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.goodreadsAccent)
                    
                    Spacer()
                    
                    // End number (Total pages)
                    Text("\(bet.book.totalPages)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isCompleted ? .green : statusColor)
                }
                .padding(.horizontal, dotSize/2)
                .frame(height: 16)
                
                // Progress bar with dots positioned on top
                ZStack(alignment: .leading) {
                    // Background track (thin)
                    RoundedRectangle(cornerRadius: barHeight/2)
                        .fill(Color.goodreadsBeige)
                        .frame(height: barHeight)
                    
                    // Progress fill (thin)
                    RoundedRectangle(cornerRadius: barHeight/2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isCompleted ? .green : statusColor,
                                    isCompleted ? .green.opacity(0.8) : statusColor.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(fillWidth, 0), height: barHeight)
                        .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                    
                    // Dots positioned ON TOP of the progress bar
                    HStack {
                        // Start dot (Page 1)
                        Circle()
                            .fill(Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.goodreadsAccent, lineWidth: 2)
                            )
                        
                        Spacer()
                        
                        // End dot (Total pages)
                        Circle()
                            .fill(isCompleted ? .green : Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .overlay(
                                Circle()
                                    .stroke(isCompleted ? .green : statusColor, lineWidth: 2)
                            )
                            .overlay(
                                Group {
                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                    .padding(.horizontal, dotSize/2)
                    
                    // Current day target dot with number above
                    if !isCompleted {
                        let targetPercentage = Double(currentDayTarget) / Double(bet.book.totalPages)
                        let targetPosition = (barWidth - dotSize) * targetPercentage + dotSize/2
                        
                        VStack(spacing: 4) {
                            // Number above dot
                            Text("D\(bet.currentDay)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(isCurrentDayCompleted ? .green : .orange)
                            
                            // Target dot
                            Circle()
                                .fill(isCurrentDayCompleted ? .green : Color.white)
                                .frame(width: dotSize, height: dotSize)
                                .overlay(
                                    Circle()
                                        .stroke(isCurrentDayCompleted ? .green : .orange, lineWidth: 2)
                                )
                                .overlay(
                                    Group {
                                        if isCurrentDayCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                        }
                        .position(x: min(max(targetPosition, dotSize), barWidth - dotSize), y: 0)
                    }
                    
                    // Next day target dot (only if current day is completed)
                    if isCurrentDayCompleted && !isCompleted, let nextTarget = nextDayTarget {
                        let nextTargetPercentage = Double(nextTarget) / Double(bet.book.totalPages)
                        let nextTargetPosition = (barWidth - dotSize) * nextTargetPercentage + dotSize/2
                        
                        VStack(spacing: 4) {
                            // Number above dot
                            Text("D\(bet.currentDay + 1)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.blue)
                            
                            // Next target dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: dotSize, height: dotSize)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                        .position(x: min(max(nextTargetPosition, dotSize), barWidth - dotSize), y: 0)
                    }
                    
                    // Current progress indicator (small dot)
                    if currentPage > 1 && progressPercentage > 0.05 && !isCompleted {
                        let progressPosition = (barWidth - dotSize) * progressPercentage + dotSize/2
                        
                        VStack(spacing: 4) {
                            // Current page number above
                            Text("\(currentPage)")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(statusColor)
                            
                            // Small progress dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(statusColor, lineWidth: 1.5)
                                )
                        }
                        .position(x: min(max(progressPosition, dotSize), barWidth - dotSize), y: 0)
                    }
                }
                .frame(height: dotSize)
            }
        }
        .frame(height: 50) // Total height including numbers above
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
