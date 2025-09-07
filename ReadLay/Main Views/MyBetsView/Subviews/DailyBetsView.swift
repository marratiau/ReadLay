//
//  DailyBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

import SwiftUI

struct DailyBetsView: View {
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    @StateObject private var dailyBetsViewModel = DailyBetsViewModel()
    @StateObject private var sessionViewModel = ReadingSessionViewModel()  // SINGLE INSTANCE
    @State private var selectedFilter: FilterOption = .all
    @State private var showingReader = false
    @State private var selectedBet: DailyBet?
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case incomplete = "To Do"
        case complete = "Done"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .incomplete: return "circle"
            case .complete: return "checkmark.circle.fill"
            }
        }
    }
    
    private var filteredDailyBets: [DailyBet] {
        switch selectedFilter {
        case .all: return dailyBetsViewModel.dailyBets
        case .incomplete: return dailyBetsViewModel.incompleteDailyBets
        case .complete: return dailyBetsViewModel.completedDailyBets
        }
    }
    
    private var dailyProgressSummary: (completed: Int, total: Int, percentage: Double) {
        dailyBetsViewModel.getDailyProgressSummary()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !readSlipViewModel.placedBets.isEmpty { progressSummaryCard }
                if !dailyBetsViewModel.dailyBets.isEmpty { filterSection }
                if filteredDailyBets.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDailyBets) { dailyBet in
                            DailyBetRowView(
                                dailyBet: dailyBet,
                                onStartReading: {
                                    openReader(for: dailyBet)
                                }
                            )
                            .environmentObject(readSlipViewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            dailyBetsViewModel.updateDailyBetsWithMultiDay(
                from: readSlipViewModel.placedBets,
                readSlipViewModel: readSlipViewModel
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BetsPlaced"))) { _ in
            dailyBetsViewModel.updateDailyBetsWithMultiDay(
                from: readSlipViewModel.placedBets,
                readSlipViewModel: readSlipViewModel
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReadingSessionCompleted"))) { _ in
            dailyBetsViewModel.updateDailyBetsWithMultiDay(
                from: readSlipViewModel.placedBets,
                readSlipViewModel: readSlipViewModel
            )
        }
        .fullScreenCover(isPresented: $showingReader) {
            if let bet = selectedBet {
                ReadingSessionFlow(
                    bet: bet,
                    sessionViewModel: sessionViewModel,
                    readSlipViewModel: readSlipViewModel,
                    isPresented: $showingReader
                )
            }
        }
    }
    
    private func openReader(for bet: DailyBet) {
        selectedBet = bet
        let lastReadPage = readSlipViewModel.getLastReadPage(for: bet.betId)
        sessionViewModel.startReadingSession(
            for: bet.betId,
            book: bet.book,
            lastReadPage: lastReadPage
        )
        showingReader = true
    }
    
    // ... rest of your existing code (progressSummaryCard, filterSection, emptyStateView, etc.)
    private var progressSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    Text(dailyBetsViewModel.getMotivationalMessage(
                        from: readSlipViewModel.placedBets,
                        readSlipViewModel: readSlipViewModel
                    ))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: dailyProgressSummary.percentage)
                        .stroke(
                            dailyProgressSummary.percentage == 1.0 ? Color.green : Color.goodreadsBrown,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(dailyProgressSummary.percentage * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                }
            }
            HStack(spacing: 20) {
                StatItem(label: "Completed", value: "\(dailyProgressSummary.completed)", color: .green)
                StatItem(label: "Remaining", value: "\(dailyProgressSummary.total - dailyProgressSummary.completed)", color: .orange)
                StatItem(label: "Total Goals", value: "\(dailyProgressSummary.total)", color: .goodreadsBrown)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.goodreadsWarm)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var filterSection: some View {
        HStack(spacing: 12) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                FilterPill(
                    option: option,
                    isSelected: selectedFilter == option,
                    action: { selectedFilter = option }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter == .complete ? "checkmark.seal.fill" : "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            Text(emptyStateMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsBrown)
                .multilineTextAlignment(.center)
            if readSlipViewModel.placedBets.isEmpty && selectedFilter == .all {
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToBookshelf"),
                        object: nil
                    )
                }) {
                    Text("Browse Books")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.goodreadsBrown)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return readSlipViewModel.placedBets.isEmpty ? "No active reading goals.\nPlace a bet to get started!" : "No daily goals for today"
        case .incomplete:
            return "All daily goals completed!"
        case .complete:
            return "No completed goals yet today"
        }
    }
}

// NEW: Complete reading session flow view
struct ReadingSessionFlow: View {
    let bet: DailyBet
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            if sessionViewModel.showingStartPageInput {
                StartingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book,
                    lastReadPage: readSlipViewModel.getLastReadPage(for: bet.betId),
                    onStart: { _ in }
                )
            } else if sessionViewModel.showingStartPageConfirmation {
                ContinueReadingConfirmationView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book,
                    nextPage: sessionViewModel.calculatedNextPage,
                    onConfirm: { }
                )
            } else if sessionViewModel.isReading {
                ReadingTimerView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book
                )
            } else if sessionViewModel.showingEndPageInput {
                EndingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book,
                    onComplete: { endingPage in
                        // Process will continue to comment input
                    }
                )
            } else if sessionViewModel.showingCommentInput {
                CommentInputView(
                    sessionViewModel: sessionViewModel,
                    readSlipViewModel: readSlipViewModel,
                    book: bet.book,
                    onComplete: {
                        isPresented = false
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ReadingSessionCompleted"),
                            object: nil
                        )
                    }
                )
            }
        }
    }
}

// Keep your existing StatItem and FilterPill structs as they are

struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsAccent)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterPill: View {
    let option: DailyBetsView.FilterOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 12))
                Text(option.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .goodreadsBrown)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.goodreadsBrown : Color.goodreadsBeige)
            )
        }
    }
}
