//
//  DailyBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

//
//  DailyBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

import SwiftUI

struct DailyBetsView: View {
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    @StateObject private var sessionViewModel = ReadingSessionViewModel()
    @StateObject private var dailyBetsViewModel = DailyBetsViewModel()
    
    var body: some View {
        ZStack {
            ScrollView {
                if dailyBetsViewModel.dailyBets.isEmpty {
                    emptyStateView
                } else {
                    // REMOVED: Today's Overview section
                    betsListView
                }
            }
            
            // Continue Reading Confirmation Overlay
            if sessionViewModel.showingStartPageConfirmation,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                ContinueReadingConfirmationView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book,
                    nextPage: sessionViewModel.calculatedNextPage
                ) {
                    // onConfirm callback - no additional action needed
                }
                .transition(.opacity)
            }
            
            // Reading Timer Overlay
            if sessionViewModel.isReading,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                ReadingTimerView(sessionViewModel: sessionViewModel, book: bet.book)
                    .transition(.opacity)
                    .zIndex(1000)
            }
            
            // Ending Page Input Overlay
            if sessionViewModel.showingEndPageInput,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                EndingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book
                ) { endingPage in
                    // FIXED: Proper session completion flow
                    handleSessionCompletion(endingPage: endingPage)
                }
                .transition(.opacity)
            }
            
            // ADDED: Comment Input Overlay
            if sessionViewModel.showingCommentInput,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                CommentInputView(
                    sessionViewModel: sessionViewModel,
                    readSlipViewModel: readSlipViewModel,
                    book: bet.book
                ) {
                    // Session completion handled in CommentInputView
                    sessionViewModel.cancelSession()
                }
                .transition(.opacity)
            }
        }
        // CHANGED: Use the new ViewModel method for better MVVM
        .onReceive(readSlipViewModel.$placedBets.combineLatest(readSlipViewModel.$dailyProgress)) { placedBets, dailyProgress in
            dailyBetsViewModel.updateDailyBetsWithMultiDay(from: placedBets, readSlipViewModel: readSlipViewModel)
        }
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingStartPageConfirmation)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.isReading)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingEndPageInput)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingCommentInput)
    }
    
    // MARK: - Session Completion Handler (FIXED)
    private func handleSessionCompletion(endingPage: Int) {
        guard let session = sessionViewModel.currentSession else { return }
        
        // Update reading progress first
        readSlipViewModel.updateReadingProgress(
            for: session.betId,
            startingPage: session.startingPage,
            endingPage: endingPage
        )
        
        // Set ending page in session
        sessionViewModel.setEndingPage(endingPage)
        
        print("DEBUG: Session completed - Starting: \(session.startingPage), Ending: \(endingPage), Pages: \(session.pagesRead)")
        print("DEBUG: Journal entries before: \(readSlipViewModel.journalEntries.count)")
        
        // Transition to comment input
        // The comment input will handle final session processing
    }
    
    // MARK: - Bets List (ENHANCED for Multi-Day)
    private var betsListView: some View {
        LazyVStack(spacing: 16) {
            // Group daily bets by book
            ForEach(groupedDailyBets, id: \.0) { bookTitle, betsForBook in
                VStack(spacing: 12) {
                    // Book title header (if multiple days)
                    if betsForBook.count > 1 {
                        HStack {
                            Text(bookTitle)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.goodreadsBrown)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Show all days for this book
                    ForEach(betsForBook.sorted { $0.dayNumber < $1.dayNumber }) { bet in
                        DailyBetRowView(
                            bet: bet,
                            onStartReading: {
                                handleStartReading(for: bet)
                            }
                            // REMOVED: onStartNextDay parameter - will handle this differently
                        )
                        .environmentObject(readSlipViewModel)
                        // ADDED: Context menu for starting next day
                        .contextMenu {
                            if readSlipViewModel.canGetAhead(for: bet.betId) && !bet.isNextDay {
                                Button("Start Next Day") {
                                    handleStartNextDay(for: bet)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // ADDED: Group daily bets by book
    private var groupedDailyBets: [(String, [DailyBet])] {
        let grouped = Dictionary(grouping: dailyBetsViewModel.dailyBets) { $0.book.title }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }
    
    // ADDED: Handle starting reading for existing day
    private func handleStartReading(for bet: DailyBet) {
        let lastReadPage = readSlipViewModel.getLastReadPage(for: bet.betId)
        sessionViewModel.startReadingSession(
            for: bet.betId,
            book: bet.book,
            lastReadPage: lastReadPage
        )
    }
    
    // FIXED: Handle starting next day with proper method call
    private func handleStartNextDay(for bet: DailyBet) {
        readSlipViewModel.startNextDay(for: bet.betId)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsAccent.opacity(0.5))
            Text("No Daily Goals")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            Text("Place a bet to see your daily reading goals")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}
