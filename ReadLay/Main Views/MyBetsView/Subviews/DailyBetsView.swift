//
//  DailyBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//
//  DailyBetsView.swift - UPDATED EXISTING FILE
//  Key changes: Fixed day progression flow to show next day without forcing reading session

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
                    betsListView
                }
            }

            // NOTE: StartingPageInputView and ContinueReadingConfirmationView are REMOVED
            // We go directly to the timer when "Start Reading" is clicked

            // Reading Timer Overlay - Shows immediately after clicking "Start Reading"
            if sessionViewModel.isReading,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                ReadingTimerView(sessionViewModel: sessionViewModel, book: bet.book)
                    .transition(.opacity)
                    .zIndex(1000)
            }

            // Ending Page Input Overlay - Shows after stopping the timer
            if sessionViewModel.showingEndPageInput,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                EndingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book
                ) { endingPage in
                    handleSessionCompletion(endingPage: endingPage)
                }
                .transition(.opacity)
            }

            // Comment Input Overlay - Optional comments after ending page
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
        .onReceive(readSlipViewModel.$placedBets.combineLatest(readSlipViewModel.$dailyProgress)) { placedBets, _ in
            dailyBetsViewModel.updateDailyBetsWithMultiDay(from: placedBets, readSlipViewModel: readSlipViewModel)
        }
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.isReading)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingEndPageInput)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingCommentInput)
    }

    // MARK: - Session Completion Handler
    private func handleSessionCompletion(endingPage: Int) {
        guard let session = sessionViewModel.currentSession else { return }

        // Update reading progress
        readSlipViewModel.updateReadingProgress(
            for: session.betId,
            startingPage: session.startingPage,
            endingPage: endingPage
        )

        // Set ending page in session
        sessionViewModel.setEndingPage(endingPage)

        print("DEBUG: Session completed - Starting: \(session.startingPage), Ending: \(endingPage)")
        
        // Transition to comment input
    }

    // MARK: - Bets List
    private var betsListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(groupedDailyBets, id: \.0) { bookTitle, betsForBook in
                VStack(spacing: 12) {
                    if betsForBook.count > 1 {
                        HStack {
                            Text(bookTitle)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.goodreadsBrown)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }

                    ForEach(betsForBook.sorted { $0.dayNumber < $1.dayNumber }) { bet in
                        DailyBetRowView(
                            bet: bet,
                            onStartReading: {
                                handleStartReading(for: bet)
                            },
                            onStartNextDay: {
                                handleStartNextDay(for: bet)
                            }
                        )
                        .environmentObject(readSlipViewModel)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // Group daily bets by book
    private var groupedDailyBets: [(String, [DailyBet])] {
        let grouped = Dictionary(grouping: dailyBetsViewModel.dailyBets) { $0.book.title }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    // UPDATED: Direct start without page input
    private func handleStartReading(for bet: DailyBet) {
        let lastReadPage = readSlipViewModel.getLastReadPage(for: bet.betId)
        
        // Automatically determine the starting page
        let startingPage: Int
        if lastReadPage <= bet.book.readingStartPage {
            // First session - use the book's configured starting page
            startingPage = bet.book.readingStartPage
            print("DEBUG: First reading session, starting at page \(startingPage)")
        } else {
            // Continuing - use the next page after last read
            startingPage = lastReadPage + 1
            print("DEBUG: Continuing from page \(startingPage)")
        }
        
        // Use the new direct start method - timer starts immediately
        sessionViewModel.startReadingSessionDirect(
            for: bet.betId,
            book: bet.book,
            startingPage: startingPage
        )
    }

    // Handle starting next day
    private func handleStartNextDay(for bet: DailyBet) {
        print("DEBUG: Starting next day for bet \(bet.betId)")

        guard let readingBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.betId }) else {
            print("DEBUG: No reading bet found")
            return
        }

        let currentPage = readSlipViewModel.getCurrentPagePosition(for: bet.betId)
        let currentDayTarget = readingBet.pagesPerDay * readingBet.currentDay

        guard currentPage >= currentDayTarget else {
            print("DEBUG: Current day not completed, cannot start next day")
            return
        }

        guard readingBet.currentDay < readingBet.totalDays else {
            print("DEBUG: Already on final day")
            return
        }

        readSlipViewModel.startNextDay(for: bet.betId)
        print("DEBUG: Next day revealed for bet \(bet.betId)")
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
