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

            // ADDED: Starting Page Input Overlay (THIS WAS MISSING - this is why the button wasn't working!)
            if sessionViewModel.showingStartPageInput,
               let session = sessionViewModel.currentSession,
               let bet = dailyBetsViewModel.dailyBets.first(where: { $0.betId == session.betId }) {
                StartingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book,
                    lastReadPage: readSlipViewModel.getLastReadPage(for: bet.betId)
                ) { startingPage in
                    // onStart callback - start the timer view
                    print("DEBUG: Starting reading from page \(startingPage)")
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
                    handleSessionCompletion(endingPage: endingPage)
                }
                .transition(.opacity)
            }

            // Comment Input Overlay
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
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingStartPageConfirmation)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingStartPageInput)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.isReading)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingEndPageInput)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingCommentInput)
    }

    // MARK: - Session Completion Handler
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

    // MARK: - Bets List (ENHANCED for Multi-Day with Better Logic)
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

                    // UPDATED: Show days in correct order and handle progression
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
                        .onAppear {
                            // TEMPORARY DEBUG: Print what's happening with DailyBets
                            print("🔍 DailyBet Debug:")
                            print("  Book: \(bet.book.title)")
                            print("  Reading range: \(bet.book.readingStartPage)-\(bet.book.readingEndPage)")
                            print("  Effective pages: \(bet.book.effectiveTotalPages)")
                            print("  Day \(bet.dayNumber) range: \(bet.dayStartPage)-\(bet.dayEndPage)")
                            print("  Daily goal: \(bet.dailyGoal)")
                            print("  Current progress: \(bet.currentProgress)")
                            print("  Current page position: \(readSlipViewModel.getCurrentPagePosition(for: bet.betId))")
                            print("  Last read page: \(readSlipViewModel.getLastReadPage(for: bet.betId))")
                            print("  Page range text: \(bet.pageRange)")
                            print("---")
                        }
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

    // UPDATED: Handle starting reading for any day
    private func handleStartReading(for bet: DailyBet) {
        let lastReadPage = readSlipViewModel.getLastReadPage(for: bet.betId)
        print("DEBUG: handleStartReading called for bet \(bet.betId), lastReadPage: \(lastReadPage)")
        sessionViewModel.startReadingSession(
            for: bet.betId,
            book: bet.book,
            lastReadPage: lastReadPage
        )
    }

    // UPDATED: Handle starting next day - just reveals next day, doesn't force reading
    private func handleStartNextDay(for bet: DailyBet) {
        print("DEBUG: Starting next day for bet \(bet.betId)")

        // Find the reading bet
        guard let readingBet = readSlipViewModel.placedBets.first(where: { $0.id == bet.betId }) else {
            print("DEBUG: No reading bet found")
            return
        }

        // Check if current day is completed
        let currentPage = readSlipViewModel.getCurrentPagePosition(for: bet.betId)
        let currentDayTarget = readingBet.pagesPerDay * readingBet.currentDay

        guard currentPage >= currentDayTarget else {
            print("DEBUG: Current day not completed, cannot start next day")
            return
        }

        // Check if there are more days
        guard readingBet.currentDay < readingBet.totalDays else {
            print("DEBUG: Already on final day")
            return
        }

        // This should trigger the ViewModel to reveal the next day
        // The actual day progression logic should be handled in the ViewModel
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
