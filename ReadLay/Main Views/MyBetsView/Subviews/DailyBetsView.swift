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
                    LazyVStack(spacing: 16) {
                        ForEach(dailyBetsViewModel.dailyBets) { bet in
                            DailyBetRowView(
                                bet: bet,
                                onStartReading: {
                                    let lastReadPage = readSlipViewModel.getLastReadPage(for: bet.betId)
                                    sessionViewModel.startReadingSession(
                                        for: bet.betId,
                                        book: bet.book,
                                        lastReadPage: lastReadPage
                                    )
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
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
                    readSlipViewModel.updateReadingProgress(
                        for: session.betId,
                        startingPage: session.startingPage,
                        endingPage: endingPage
                    )
                }
                .transition(.opacity)
            }
        }
        // CHANGED: Use the new ViewModel method for better MVVM
        .onReceive(readSlipViewModel.$placedBets.combineLatest(readSlipViewModel.$dailyProgress)) { placedBets, dailyProgress in
            dailyBetsViewModel.updateDailyBets(from: placedBets, readSlipViewModel: readSlipViewModel)
        }
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingStartPageConfirmation)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.isReading)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingEndPageInput)
    }
    
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
