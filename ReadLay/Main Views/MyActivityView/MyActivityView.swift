//
//  MyActivityView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/8/25.
//

import SwiftUI

struct MyActivityView: View {
    @ObservedObject var readSlipViewModel: ReadSlipViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection

                if readSlipViewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    activityList
                }
            }
            .background(backgroundGradient)
            .navigationTitle("My Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Stats row
            HStack(spacing: 24) {
                statCard(
                    title: "Total Sessions",
                    value: "\(readSlipViewModel.journalEntries.count)",
                    icon: "book.pages"
                )

                statCard(
                    title: "Total Time",
                    value: totalReadingTime,
                    icon: "clock"
                )

                statCard(
                    title: "Pages Read",
                    value: "\(totalPagesRead)",
                    icon: "doc.text"
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.goodreadsBrown)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Activity List
    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // FIXED: Sort by date and show all journal entries
                ForEach(readSlipViewModel.journalEntries.sorted { $0.date > $1.date }) { entry in
                    ReadingSessionRowView(entry: entry)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.goodreadsAccent.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Reading Sessions Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.goodreadsBrown)

                Text("Complete reading sessions to track your activity")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.goodreadsBeige,
                Color.goodreadsWarm.opacity(0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Computed Properties
    private var totalReadingTime: String {
        let totalSeconds = readSlipViewModel.journalEntries.reduce(0) { $0 + $1.sessionDuration }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var totalPagesRead: Int {
        return readSlipViewModel.journalEntries.reduce(0) { $0 + $1.pagesRead }
    }
}

// MARK: - Reading Session Row View (RENAMED AND ENHANCED)
struct ReadingSessionRowView: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with book info and date/time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.bookTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)

                    if let author = entry.bookAuthor {
                        Text("by \(author)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))

                    Text(formattedTime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.6))
                }
            }

            // ENHANCED: Session metrics with better layout
            HStack(spacing: 0) {
                // Duration
                metricItem(
                    icon: "clock.fill",
                    value: entry.formattedDuration,
                    label: "Duration",
                    color: .blue
                )

                Spacer()

                // Pages read
                metricItem(
                    icon: "book.pages.fill",
                    value: "\(entry.pagesRead)",
                    label: "Pages",
                    color: .green
                )

                Spacer()

                // Page range
                metricItem(
                    icon: "bookmark.fill",
                    value: "\(entry.startingPage)-\(entry.endingPage)",
                    label: "Range",
                    color: .orange
                )

                Spacer()

                // Engagement indicator
                if entry.hasEngagementContent {
                    metricItem(
                        icon: "brain.head.profile",
                        value: "\(entry.engagementEntries.count)",
                        label: "Notes",
                        color: .purple
                    )
                } else {
                    // Placeholder to maintain layout
                    VStack(spacing: 4) {
                        Text("")
                            .font(.system(size: 12))
                        Text("")
                            .font(.system(size: 10))
                    }
                    .frame(width: 50)
                }
            }

            // ENHANCED: Comment/takeaway section
            if !entry.comment.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Takeaway")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsAccent)

                    Text(entry.comment)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsBrown.opacity(0.8))
                        .lineLimit(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.goodreadsBeige.opacity(0.7))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.goodreadsBrown.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // ENHANCED: Better metric display
    private func metricItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            // Icon and value row
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
            }

            // Label
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.8))
        }
        .frame(width: 60)
    }

    // ADDED: Date and time formatting
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.date)
    }
}
