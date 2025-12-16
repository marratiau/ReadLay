//
//  DailyBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

//  DailyBetRowView.swift - FIXED WITH TRUE FANDUEL-STYLE PROGRESS
//  Key changes: Thinner progress bar + bigger dots on top + numbers hovering above + dynamic daily views

import SwiftUI

struct DailyBetRowView: View {
    let bet: DailyBet
    let onStartReading: () -> Void
    let onStartNextDay: (() -> Void)? // Optional callback for starting next day
    
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    
    private var progressStatus: ReadingBet.ProgressStatus {
        return readSlipViewModel.getProgressStatus(for: bet.betId)
    }
    
    private var canGetAhead: Bool {
        return readSlipViewModel.canGetAhead(for: bet.betId)
    }
    
    // FIXED: Removed $ prefix - this is a computed property, not a binding
    private var progressInfo: (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        // Assuming getProgressInfo returns the tuple directly
        guard let readingBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.betId }) else {
            return (actual: 0, expected: 0, status: .onTrack)
        }
        let actual = readSlipViewModel.getCurrentPagePosition(for: bet.betId)
        let expected = readingBet.book.readingStartPage + (readingBet.pagesPerDay * readingBet.currentDay) - 1
        let status = readSlipViewModel.getProgressStatus(for: bet.betId)
        return (actual: actual, expected: expected, status: status)
    }
    
    // UPDATED: More precise day completion logic
    private var isDailyGoalCompleted: Bool {
        return bet.isCompleted || bet.currentProgress >= bet.dailyGoal
    }
    
    // UPDATED: Check if this is a completed previous day
    private var isPreviousCompletedDay: Bool {
        guard let readingBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.betId }) else { return false }
        return bet.dayNumber < readingBet.currentDay && isDailyGoalCompleted
    }
    
    // UPDATED: Check if this is the current active day
    private var isCurrentDay: Bool {
        guard let readingBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.betId }) else { return false }
        return bet.dayNumber == readingBet.currentDay
    }
    
    // UPDATED: Check if this is a future day that can be started
    private var canStartThisDay: Bool {
        return bet.isNextDay && isDailyGoalCompleted
    }
    
    // ADDED: Check if should show overall progress (hide for completed days)
    private var shouldShowOverallProgress: Bool {
        return !isPreviousCompletedDay
    }
    
    var body: some View {
        VStack(spacing: 16) {
            headerRow
            progressSection
            actionButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColorForDayState)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColorForDayState, lineWidth: 1)
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .opacity(isPreviousCompletedDay ? 0.85 : 1.0) // Slight fade for completed days
    }
    
    // UPDATED: Dynamic background based on day state
    private var backgroundColorForDayState: Color {
        if isPreviousCompletedDay {
            return Color.green.opacity(0.1)
        } else if isCurrentDay && isDailyGoalCompleted {
            return Color.blue.opacity(0.1)
        } else if canStartThisDay {
            return Color.orange.opacity(0.1)
        } else {
            return Color.goodreadsWarm
        }
    }
    
    private var borderColorForDayState: Color {
        if isPreviousCompletedDay {
            return Color.green.opacity(0.4)
        } else if isCurrentDay && isDailyGoalCompleted {
            return Color.blue.opacity(0.4)
        } else if canStartThisDay {
            return Color.orange.opacity(0.4)
        } else {
            return statusBorderColor
        }
    }
    
    // MARK: - Status-based styling
    private var statusBorderColor: Color {
        switch progressStatus {
        case .completed:
            return Color.green.opacity(0.4)
        case .ahead:
            return Color.blue.opacity(0.4)
        case .behind:
            return Color.orange.opacity(0.4)
        case .overdue:
            return Color.red.opacity(0.4)
        case .onTrack:
            return Color.goodreadsAccent.opacity(0.2)
        }
    }
    
    private var statusColor: Color {
        if isPreviousCompletedDay {
            return .green
        } else if isDailyGoalCompleted && canGetAhead {
            return .blue
        }
        
        switch progressStatus {
        case .completed: return .green
        case .ahead: return .blue
        case .behind: return .orange
        case .overdue: return .red
        case .onTrack: return .goodreadsAccent
        }
    }
    
    private var statusText: String {
        if isPreviousCompletedDay {
            return "COMPLETED"
        } else if isDailyGoalCompleted && canGetAhead {
            return "CAN START NEXT"
        }
        
        switch progressStatus {
        case .completed: return "COMPLETED"
        case .ahead: return "AHEAD"
        case .behind: return "BEHIND"
        case .overdue: return "OVERDUE"
        case .onTrack: return "ON TRACK"
        }
    }
    
    // MARK: - Header Row
    private var headerRow: some View {
        HStack(spacing: 12) {
            // Day status indicator
            dayStatusIndicator
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(bet.dayNumber) Goal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                
                HStack(spacing: 8) {
                    progressCircle
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bet.book.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.goodreadsBrown)
                            .lineLimit(1)
                        
                        Text("Read \(bet.dailyGoal) pages (\(bet.pageRange))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text(statusText)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor)
                    )
                
                dayIndicator
            }
        }
    }
    
    // NEW: Day status indicator (TC badge equivalent)
    private var dayStatusIndicator: some View {
        Text("\(bet.dayNumber)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(dayIndicatorColor)
            )
    }
    
    private var dayIndicatorColor: Color {
        if isPreviousCompletedDay {
            return .green
        } else if isCurrentDay {
            return .goodreadsBrown
        } else if canStartThisDay {
            return .orange
        } else {
            return .goodreadsAccent.opacity(0.6)
        }
    }
    
    private var progressCircle: some View {
        Circle()
            .stroke(
                isDailyGoalCompleted ? Color.green : statusColor.opacity(0.6),
                lineWidth: 2
            )
            .fill(isDailyGoalCompleted ? Color.green.opacity(0.1) : Color.clear)
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: isDailyGoalCompleted ? "checkmark" : "")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            )
    }
    
    private var dayIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("of \(bet.totalDays) days")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
        }
    }
    
    // MARK: - Progress Section (UPDATED WITH TRUE FANDUEL-STYLE + CONDITIONAL OVERALL PROGRESS)
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Daily progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Spacer()
                    Text("\(bet.currentProgress)/\(bet.dailyGoal) pages")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
                
                // UPDATED: True FanDuel-style daily progress bar
                trueFanDuelStyleDailyProgressBar
            }
            
            // CONDITIONAL: Only show overall progress if not a completed previous day
            if shouldShowOverallProgress {
                HStack {
                    Text("Overall Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Spacer()
                    Text("\(progressInfo.actual)/\(bet.book.totalPages) pages")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
            }
        }
    }
    
    // MARK: - TRUE FANDUEL-STYLE DAILY PROGRESS BAR (THIN BAR + BIG DOTS ON TOP + NUMBERS ABOVE)
    private var trueFanDuelStyleDailyProgressBar: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let progressPercentage = bet.progressPercentage
            let fillWidth = barWidth * progressPercentage
            let barHeight: CGFloat = 10 // Thinner progress bar
            let dotSize: CGFloat = 18 // Bigger dots
            
            VStack(spacing: 0) {
                // Numbers hovering above dots
                HStack {
                    // Start number (0 pages)
                    Text("0")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.goodreadsAccent)
                    
                    Spacer()
                    
                    // Goal number (daily goal)
                    Text("\(bet.dailyGoal)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isDailyGoalCompleted ? .green : statusColor)
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
                                    isDailyGoalCompleted ? .green : statusColor,
                                    isDailyGoalCompleted ? .green.opacity(0.8) : statusColor.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(fillWidth, 0), height: barHeight)
                        .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                    
                    // Dots positioned ON TOP of the progress bar
                    HStack {
                        // Start dot (0 pages)
                        Circle()
                            .fill(Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.goodreadsAccent, lineWidth: 2)
                            )
                        
                        Spacer()
                        
                        // Goal dot (daily goal)
                        Circle()
                            .fill(isDailyGoalCompleted ? .green : Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .overlay(
                                Circle()
                                    .stroke(isDailyGoalCompleted ? .green : statusColor, lineWidth: 2)
                            )
                            .overlay(
                                Group {
                                    if isDailyGoalCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                    .padding(.horizontal, dotSize/2)
                    
                    // Current progress indicator (moving dot with number above)
                    if bet.currentProgress > 0 && !isDailyGoalCompleted && progressPercentage > 0.05 {
                        let progressPosition = (barWidth - dotSize) * progressPercentage + dotSize/2
                        
                        VStack(spacing: 4) {
                            // Current progress number above
                            Text("\(bet.currentProgress)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(statusColor)
                            
                            // Moving progress dot
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(statusColor, lineWidth: 2)
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
    
    // MARK: - Action Button (UPDATED LOGIC)
    private var actionButton: some View {
        Button(action: buttonAction) {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 16, weight: .medium))
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(buttonTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(buttonBorderColor, lineWidth: 1)
                    )
            )
        }
        .disabled(buttonIsDisabled)
    }
    
    // UPDATED: Button action logic
    private func buttonAction() {
        if isPreviousCompletedDay {
            // Do nothing - completed days are inactive
            return
        } else if isCurrentDay && isDailyGoalCompleted && canGetAhead {
            // Start next day
            onStartNextDay?()
        } else {
            // Start reading for this day
            onStartReading()
        }
    }
    
    // UPDATED: Button styling based on state
    private var buttonIcon: String {
        if isPreviousCompletedDay {
            return "checkmark"
        } else if isCurrentDay && isDailyGoalCompleted && canGetAhead {
            return "arrow.right.circle.fill"
        } else if canStartThisDay {
            return "play.circle.fill"
        } else {
            return "book.fill"
        }
    }
    
    private var buttonText: String {
        if isPreviousCompletedDay {
            return "Completed"
        } else if isCurrentDay && isDailyGoalCompleted && canGetAhead {
            let nextDay = bet.dayNumber + 1
            return nextDay <= bet.totalDays ? "Start Day \(nextDay)" : "All Days Complete"
        } else if canStartThisDay {
            return "Start Day \(bet.dayNumber)"
        } else {
            return "Read"
        }
    }
    
    private var buttonTextColor: Color {
        if isPreviousCompletedDay {
            return .goodreadsAccent
        } else {
            return .white
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isPreviousCompletedDay {
            return Color.goodreadsBeige.opacity(0.8)
        } else if isCurrentDay && isDailyGoalCompleted && canGetAhead {
            return Color.blue
        } else if canStartThisDay {
            return Color.orange
        } else {
            return Color.goodreadsBrown
        }
    }
    
    private var buttonBorderColor: Color {
        if isPreviousCompletedDay {
            return Color.goodreadsAccent.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var buttonIsDisabled: Bool {
        return isPreviousCompletedDay || progressStatus == .completed
    }
}
