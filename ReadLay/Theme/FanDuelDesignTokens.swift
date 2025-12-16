//
//  FanDuelDesignTokens.swift
//  ReadLay
//
//  Created by Claude Code on 12/15/25.
//  Design system constants for FanDuel-style components
//

import SwiftUI

/// Design tokens for FanDuel-style components
/// Centralizes design values for consistency across the app
struct FanDuelDesignTokens {

    // MARK: - Progress Bar Design
    struct ProgressBar {
        /// Height of the thin progress bar
        static let barHeight: CGFloat = 10

        /// Size of the large dots positioned on top of the bar
        static let dotSize: CGFloat = 18

        /// Size of the moving current progress indicator
        static let currentDotSize: CGFloat = 14

        /// Vertical spacing between numbers and dots
        static let numberOffset: CGFloat = 4

        /// Animation duration for progress changes
        static let animationDuration: Double = 0.3

        /// Threshold for showing moving indicator (5% to 95%)
        static let movingIndicatorMinThreshold: Double = 0.05
        static let movingIndicatorMaxThreshold: Double = 0.95
    }

    // MARK: - Parlay Design
    struct Parlay {
        /// Width of the vertical connecting line between parlay legs
        static let connectorWidth: CGFloat = 2

        /// Size of dots at each parlay leg connection point
        static let dotSize: CGFloat = 10

        /// Left padding for parlay leg content (to clear connector)
        static let legIndent: CGFloat = 48

        /// Spacing between parlay legs
        static let legSpacing: CGFloat = 16

        /// Corner radius for parlay container
        static let containerRadius: CGFloat = 12

        /// Border width for parlay container
        static let containerBorderWidth: CGFloat = 2

        /// Padding inside parlay container
        static let containerPadding: CGFloat = 16
    }

    // MARK: - Status Colors
    struct Colors {
        /// Color for on-track progress (Goodreads accent brown)
        static let onTrack = Color.goodreadsAccent

        /// Color for ahead-of-schedule progress
        static let ahead = Color.blue

        /// Color for behind-schedule progress
        static let behind = Color.orange

        /// Color for overdue progress
        static let overdue = Color.red

        /// Color for completed progress
        static let completed = Color.green

        /// Color for active parlay elements (Goodreads brown)
        static let parlayActive = Color.goodreadsBrown

        /// Color for parlay connector when all legs complete
        static let parlayCompleted = Color.green

        /// Color for parlay connector when in progress
        static let parlayInProgress = Color.blue

        /// Background colors (Goodreads palette)
        static let background = Color.goodreadsBeige
        static let cardBackground = Color.goodreadsWarm
        static let trackBackground = Color.goodreadsBeige
    }

    // MARK: - Animation
    struct Animation {
        /// Standard easing animation for progress updates
        static let progressUpdate: SwiftUI.Animation = .easeInOut(duration: ProgressBar.animationDuration)

        /// Spring animation for dot fills and expansions
        static let dotFill: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.7)

        /// Pulse animation for active parlay connectors
        static let parlayPulse: SwiftUI.Animation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)

        /// Sheet presentation animation
        static let sheetPresentation: SwiftUI.Animation = .easeInOut(duration: 0.25)
    }

    // MARK: - Typography
    struct Typography {
        /// Font size for progress bar numbers
        static let progressNumber: CGFloat = 10

        /// Font size for current progress indicator
        static let currentProgressNumber: CGFloat = 8

        /// Font size for parlay combined odds
        static let parlayOdds: CGFloat = 20

        /// Font size for parlay header text
        static let parlayHeader: CGFloat = 14

        /// Font size for parlay leg details
        static let parlayLegDetails: CGFloat = 12
    }

    // MARK: - Spacing
    struct Spacing {
        /// Standard padding for cards
        static let cardPadding: CGFloat = 16

        /// Standard section spacing
        static let sectionSpacing: CGFloat = 12

        /// Standard element spacing within a group
        static let elementSpacing: CGFloat = 8

        /// Tight spacing for closely related elements
        static let tightSpacing: CGFloat = 4
    }

    // MARK: - Helper Methods

    /// Get status color based on progress state
    /// - Parameters:
    ///   - current: Current progress value
    ///   - target: Target/goal value
    ///   - isOverdue: Whether the goal is overdue
    ///   - isCompleted: Whether the goal is completed
    /// - Returns: Appropriate status color
    static func statusColor(current: Int, target: Int, isOverdue: Bool, isCompleted: Bool) -> Color {
        if isCompleted {
            return Colors.completed
        } else if isOverdue {
            return Colors.overdue
        } else if current > target {
            return Colors.ahead
        } else if Double(current) < Double(target) * 0.75 {
            return Colors.behind
        } else {
            return Colors.onTrack
        }
    }

    /// Get parlay connector color based on completion state
    /// - Parameters:
    ///   - completedLegs: Number of completed legs
    ///   - totalLegs: Total number of legs
    /// - Returns: Appropriate connector color
    static func parlayConnectorColor(completedLegs: Int, totalLegs: Int) -> Color {
        if completedLegs == totalLegs {
            return Colors.parlayCompleted
        } else if completedLegs > 0 {
            return Colors.parlayInProgress
        } else {
            return Colors.parlayActive
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Apply FanDuel progress bar animation
    func fanDuelProgressAnimation<V: Equatable>(value: V) -> some View {
        self.animation(FanDuelDesignTokens.Animation.progressUpdate, value: value)
    }

    /// Apply FanDuel dot fill animation
    func fanDuelDotFillAnimation<V: Equatable>(value: V) -> some View {
        self.animation(FanDuelDesignTokens.Animation.dotFill, value: value)
    }
}
