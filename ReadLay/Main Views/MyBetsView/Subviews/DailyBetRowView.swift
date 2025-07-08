//
//  DailyBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

import SwiftUI

struct DailyBetRowView: View {
    let bet: DailyBet
    let onStartReading: () -> Void
    
    // ADDED: Get progress status from ReadSlipViewModel
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    
    private var progressStatus: ReadingBet.ProgressStatus {
        return readSlipViewModel.getProgressStatus(for: bet.betId)
    }
    
    private var canGetAhead: Bool {
        return readSlipViewModel.canGetAhead(for: bet.betId)
    }
    
    private var progressInfo: (actual: Int, expected: Int, status: ReadingBet.ProgressStatus) {
        return readSlipViewModel.getProgressInfo(for: bet.betId)
    }
    
    // ADDED: Check if daily goal is completed (for green bar)
    private var isDailyGoalCompleted: Bool {
        return bet.isCompleted
    }
    
    // ADDED: Get next day number for "Start Day X" functionality
    private var nextDayNumber: Int {
        return bet.dayNumber + 1
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
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Status-based styling
    private var statusBorderColor: Color {
        if isDailyGoalCompleted && canGetAhead {
            return Color.green.opacity(0.4)
        }
        
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
        if isDailyGoalCompleted && canGetAhead {
            return .green
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
        if isDailyGoalCompleted && canGetAhead {
            return "CAN GET AHEAD"
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
            // TC Badge
            Text("TC")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.goodreadsBrown)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Towards Completion")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                
                HStack(spacing: 8) {
                    progressCircle
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bet.book.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.goodreadsBrown)
                            .lineLimit(1)
                        
                        Text("to read \(bet.dailyGoal) pages")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                    }
                }
            }
            
            Spacer()
            
            // UPDATED: Enhanced day indicator with status
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
    
    private var progressCircle: some View {
        Circle()
            .stroke(
                isDailyGoalCompleted ? Color.green : statusColor.opacity(0.6),
                lineWidth: 2
            )
            .fill(isDailyGoalCompleted ? Color.green.opacity(0.1) : Color.clear)
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: isDailyGoalCompleted ? "checkmark" : "")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
            )
    }
    
    private var dayIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Day \(bet.dayNumber)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.goodreadsAccent)
            Text("of \(bet.totalDays)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
        }
    }
    
    // MARK: - Progress Section
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
                
                dailyProgressBar
            }
            
            // ADDED: Overall progress indicator
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
    
    private var dailyProgressBar: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let progressWidth = totalWidth * bet.progressPercentage
            let targetPosition = totalWidth * 0.85
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.goodreadsBeige)
                    .frame(height: 8)
                
                // FIXED: Progress fill - green when daily goal completed
                RoundedRectangle(cornerRadius: 4)
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
                    .frame(width: progressWidth, height: 8)
                
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
                
                // Target marker
                VStack(spacing: 2) {
                    Text("\(bet.dailyGoal)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isDailyGoalCompleted ? .green : statusColor)
                    Circle()
                        .fill(isDailyGoalCompleted ? .green : statusColor)
                        .frame(width: 10, height: 10)
                        .offset(y: 4)
                }
                .offset(x: targetPosition - 5, y: -8)
            }
        }
        .frame(height: 24)
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: onStartReading) {
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
        .disabled(progressStatus == .completed)
    }
    
    // MARK: - Button styling based on status
    private var buttonIcon: String {
        if isDailyGoalCompleted && canGetAhead && nextDayNumber <= bet.totalDays {
            return "arrow.right.circle.fill"
        }
        
        switch progressStatus {
        case .completed:
            return "checkmark"
        case .ahead:
            return "star.fill"
        case .behind, .overdue:
            return "exclamationmark.triangle.fill"
        case .onTrack:
            return "book.fill"
        }
    }
    
    // FIXED: Button text for "Start Day X" functionality
    private var buttonText: String {
        if isDailyGoalCompleted && canGetAhead && nextDayNumber <= bet.totalDays {
            return "Start Day \(nextDayNumber)"
        } else if isDailyGoalCompleted && nextDayNumber > bet.totalDays {
            return "Goal Complete!"
        }
        
        switch progressStatus {
        case .completed:
            return "Completed"
        case .ahead:
            return canGetAhead ? "Get Ahead" : "Read More"
        case .behind:
            return "Catch Up"
        case .overdue:
            return "Urgent"
        case .onTrack:
            return "Read"
        }
    }
    
    private var buttonTextColor: Color {
        if isDailyGoalCompleted && canGetAhead {
            return .white
        }
        
        switch progressStatus {
        case .completed:
            return .goodreadsAccent
        case .ahead:
            return .white
        case .behind:
            return .white
        case .overdue:
            return .white
        case .onTrack:
            return .white
        }
    }
    
    // FIXED: Button background color for daily goal completion
    private var buttonBackgroundColor: Color {
        if isDailyGoalCompleted && canGetAhead && nextDayNumber <= bet.totalDays {
            return Color.green
        } else if isDailyGoalCompleted && nextDayNumber > bet.totalDays {
            return Color.goodreadsBeige.opacity(0.8)
        }
        
        switch progressStatus {
        case .completed:
            return Color.goodreadsBeige.opacity(0.8)
        case .ahead:
            return Color.blue
        case .behind:
            return Color.orange
        case .overdue:
            return Color.red
        case .onTrack:
            return Color.goodreadsBrown
        }
    }
    
    private var buttonBorderColor: Color {
        if isDailyGoalCompleted && nextDayNumber > bet.totalDays {
            return Color.goodreadsAccent.opacity(0.3)
        }
        
        switch progressStatus {
        case .completed:
            return Color.goodreadsAccent.opacity(0.3)
        default:
            return Color.clear
        }
    }
}
