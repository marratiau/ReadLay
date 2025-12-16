//
//  BookJournalDetailView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/8/25.
//

import SwiftUI
// MARK: - Book Journal Detail View (NEW VIEW)
struct BookJournalDetailView: View {
    let bookSummary: BookJournalSummary
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Book header
                    bookHeader

                    // Stats overview
                    statsOverview

                    // Journal entries
                    journalEntriesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(backgroundGradient)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.goodreadsBrown)
                }
            }
        }
    }

    private var bookHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsBrown)
                .frame(width: 80, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.goodreadsBeige)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                        )
                )

            VStack(spacing: 6) {
                Text(bookSummary.bookTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if let author = bookSummary.bookAuthor {
                    Text("by \(author)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }
            }
        }
        .padding(.vertical, 16)
    }

    private var statsOverview: some View {
        HStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("\(bookSummary.totalSessions)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                Text("Sessions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }

            VStack(spacing: 6) {
                Text(bookSummary.formattedTotalTime)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                Text("Total Time")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }

            VStack(spacing: 6) {
                Text("\(bookSummary.totalPages)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                Text("Pages Read")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var journalEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reading Sessions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                Spacer()
            }

            LazyVStack(spacing: 16) {
                ForEach(bookSummary.entries) { entry in
                    JournalEntryRowView(entry: entry)
                }
            }
        }
    }

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
}

// MARK: - Journal Entry Row View (FIXED TO SHOW SESSION COMMENTS)
struct JournalEntryRowView: View {
    let entry: JournalEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            sessionInfoSection
            engagementSection
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Extracted View Components

    private var headerSection: some View {
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
                }
            }

            Spacer()
        }
    }

    private var sessionInfoSection: some View {
        HStack(spacing: 16) {
            pagesReadInfo
            durationInfo
            bookmarkInfo
            Spacer()
        }
    }

    private var pagesReadInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "book.pages")
                .font(.system(size: 12))
                .foregroundColor(.goodreadsAccent)
            Text("\(entry.pagesRead) pages")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsAccent)
        }
    }

    private var durationInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundColor(.goodreadsAccent)
            Text(entry.formattedDuration)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsAccent)
        }
    }

    private var bookmarkInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "bookmark")
                .font(.system(size: 12))
                .foregroundColor(.goodreadsAccent)
            Text("pp. \(entry.startingPage)-\(entry.endingPage)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsAccent)
        }
    }

    // FIXED: Show session comments/takeaways properly
    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ALWAYS show session comment/takeaway first
            if !entry.comment.isEmpty {
                sessionCommentView
            }

            // Then show engagement entries if any
            if !entry.engagementEntries.isEmpty {
                if isExpanded {
                    expandedEngagements
                } else {
                    collapsedEngagement
                }

                if shouldShowToggleButton {
                    toggleButton
                }
            }
        }
    }

    // NEW: Session comment/takeaway view
    private var sessionCommentView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Session Takeaway")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.goodreadsAccent)

            Text(entry.comment)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsBrown)
                .lineLimit(nil)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.goodreadsBeige.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }

    private var expandedEngagements: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !entry.engagementEntries.isEmpty {
                Text("Engagement Notes")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsAccent)

                ForEach(Array(entry.engagementEntries.enumerated()), id: \.element.id) { index, engagement in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(engagement.type.rawValue.capitalized) \(index + 1)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))

                        Text(engagement.content)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsBrown)
                            .lineLimit(nil)
                    }
                    .padding(10)
                    .background(engagementBackground)
                }
            }
        }
    }

    private var collapsedEngagement: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !entry.engagementEntries.isEmpty {
                Text("Engagement Notes")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsAccent)

                Text(entry.engagementEntries.first?.content ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(3)
                    .padding(10)
                    .background(engagementBackground)
            }
        }
    }

    private var engagementBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.goodreadsBeige.opacity(0.7))
    }

    private var toggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            Text(isExpanded ? "Show less" : "Show more")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsBrown)
                .underline()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.goodreadsWarm)
            .overlay(cardBorder)
            .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
    }

    // MARK: - Helper Properties

    private var shouldShowToggleButton: Bool {
        // Only show toggle for engagement entries, not for session comments
        return !entry.engagementEntries.isEmpty && (
            entry.engagementEntries.count > 1 ||
            (entry.engagementEntries.first?.content.count ?? 0) > 150
        )
    }
}
