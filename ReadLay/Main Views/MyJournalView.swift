
//  MyJournalView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.


import SwiftUI

struct MyJournalView: View {
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                if readSlipViewModel.journalEntries.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(readSlipViewModel.journalEntries.reversed()) { entry in
                            JournalEntryRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(backgroundGradient)
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.pages")
                .font(.system(size: 64))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Your Reading Journal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                
                Text("Your reading insights and takeaways will appear here")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
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
    
    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
    
    private var expandedEngagements: some View {
        ForEach(Array(entry.engagementEntries.enumerated()), id: \.element.id) { index, engagement in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(engagement.type.rawValue.capitalized) \(index + 1)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsAccent)
                
                Text(engagement.content)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(nil)
            }
            .padding(12)
            .background(engagementBackground)
        }
    }
    
    private var collapsedEngagement: some View {
        Text(entry.engagementEntries.first?.content ?? "")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.goodreadsBrown)
            .lineLimit(3)
            .padding(12)
            .background(engagementBackground)
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
        entry.engagementEntries.count > 1 || (entry.engagementEntries.first?.content.count ?? 0) > 150
    }
}
