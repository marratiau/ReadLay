//
//  FanDuelProgressBar.swift
//  ReadLay
//
//  Created by Claude Code on 12/15/25.
//  FanDuel-style progress bar with thin bar and large dots
//

import SwiftUI

/// FanDuel-style progress bar component
/// Features: thin bar, large dots positioned on top, numbers above dots, smooth animations
struct FanDuelProgressBar: View {
    // MARK: - Design Tokens
    private static let barHeight: CGFloat = 10
    private static let dotSize: CGFloat = 18
    private static let currentDotSize: CGFloat = 14
    private static let numberOffset: CGFloat = 4
    private static let animationDuration: Double = 0.3

    // MARK: - Properties
    let startValue: Int
    let currentValue: Int
    let goalValue: Int
    let endValue: Int?  // Optional: for overall progress (reading range)
    let statusColor: Color
    let isCompleted: Bool
    let showMovingIndicator: Bool

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let progressPercentage = calculateProgressPercentage()
            let fillWidth = barWidth * progressPercentage

            VStack(spacing: 0) {
                // Numbers floating above dots
                numbersRow(barWidth: barWidth)
                    .frame(height: 16)

                // Progress bar with dots
                progressBarWithDots(barWidth: barWidth, fillWidth: fillWidth, progressPercentage: progressPercentage)
                    .frame(height: Self.dotSize)
            }
        }
        .frame(height: 50) // Total height including numbers above
    }

    // MARK: - Numbers Row
    private func numbersRow(barWidth: CGFloat) -> some View {
        HStack {
            // Start number
            Text("\(startValue)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.goodreadsAccent)

            Spacer()

            // Goal number (or end number if no goal)
            Text("\(endValue ?? goalValue)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isCompleted ? .green : statusColor)
        }
        .padding(.horizontal, Self.dotSize/2)
    }

    // MARK: - Progress Bar with Dots
    private func progressBarWithDots(barWidth: CGFloat, fillWidth: CGFloat, progressPercentage: Double) -> some View {
        ZStack(alignment: .leading) {
            // Background track (thin)
            RoundedRectangle(cornerRadius: Self.barHeight/2)
                .fill(Color.goodreadsBeige)
                .frame(height: Self.barHeight)

            // Progress fill (thin)
            progressFill(fillWidth: fillWidth)
                .frame(height: Self.barHeight)

            // Dots positioned ON TOP of the progress bar
            dotsOverlay()

            // Current progress indicator (moving dot with number above)
            if showMovingIndicator && !isCompleted && progressPercentage > 0.05 && progressPercentage < 0.95 {
                currentProgressIndicator(barWidth: barWidth, progressPercentage: progressPercentage)
            }
        }
    }

    // MARK: - Progress Fill
    private func progressFill(fillWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Self.barHeight/2)
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
            .frame(width: max(fillWidth, 0))
            .animation(.easeInOut(duration: Self.animationDuration), value: fillWidth)
    }

    // MARK: - Dots Overlay
    private func dotsOverlay() -> some View {
        HStack {
            // Start dot
            Circle()
                .fill(Color.white)
                .frame(width: Self.dotSize, height: Self.dotSize)
                .overlay(
                    Circle()
                        .stroke(Color.goodreadsAccent, lineWidth: 2)
                )

            Spacer()

            // Goal/End dot
            Circle()
                .fill(isCompleted ? .green : Color.white)
                .frame(width: Self.dotSize, height: Self.dotSize)
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
        .padding(.horizontal, Self.dotSize/2)
    }

    // MARK: - Current Progress Indicator
    private func currentProgressIndicator(barWidth: CGFloat, progressPercentage: Double) -> some View {
        let progressPosition = (barWidth - Self.dotSize) * progressPercentage + Self.dotSize/2

        return VStack(spacing: Self.numberOffset) {
            // Current progress number above
            Text("\(currentValue)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(statusColor)

            // Moving progress dot
            Circle()
                .fill(Color.white)
                .frame(width: Self.currentDotSize, height: Self.currentDotSize)
                .overlay(
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                )
        }
        .position(x: min(max(progressPosition, Self.dotSize), barWidth - Self.dotSize), y: 0)
    }

    // MARK: - Helper Methods
    private func calculateProgressPercentage() -> Double {
        let total = Double(goalValue - startValue)
        guard total > 0 else { return 0 }
        let progress = Double(currentValue - startValue)
        return min(max(progress / total, 0), 1.0)
    }
}

// MARK: - Convenience Initializers

extension FanDuelProgressBar {
    /// Daily progress variant (0 to daily goal)
    static func daily(
        currentProgress: Int,
        dailyGoal: Int,
        statusColor: Color,
        isCompleted: Bool
    ) -> FanDuelProgressBar {
        FanDuelProgressBar(
            startValue: 0,
            currentValue: currentProgress,
            goalValue: dailyGoal,
            endValue: nil,
            statusColor: statusColor,
            isCompleted: isCompleted,
            showMovingIndicator: true
        )
    }

    /// Overall progress variant (within reading range)
    static func overall(
        currentPage: Int,
        readingStartPage: Int,
        readingEndPage: Int,
        targetPage: Int,
        statusColor: Color,
        isCompleted: Bool
    ) -> FanDuelProgressBar {
        FanDuelProgressBar(
            startValue: readingStartPage,
            currentValue: currentPage,
            goalValue: targetPage,
            endValue: readingEndPage,
            statusColor: statusColor,
            isCompleted: isCompleted,
            showMovingIndicator: true
        )
    }
}

// MARK: - Preview
struct FanDuelProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Daily progress example
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Progress (On Track)")
                    .font(.caption)
                FanDuelProgressBar.daily(
                    currentProgress: 15,
                    dailyGoal: 30,
                    statusColor: .goodreadsAccent,
                    isCompleted: false
                )
            }

            // Daily progress completed
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Progress (Completed)")
                    .font(.caption)
                FanDuelProgressBar.daily(
                    currentProgress: 30,
                    dailyGoal: 30,
                    statusColor: .green,
                    isCompleted: true
                )
            }

            // Overall progress example
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Progress (Reading Range)")
                    .font(.caption)
                FanDuelProgressBar.overall(
                    currentPage: 150,
                    readingStartPage: 1,
                    readingEndPage: 300,
                    targetPage: 180,
                    statusColor: .blue,
                    isCompleted: false
                )
            }
        }
        .padding()
    }
}
