//
//  DailyBet.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct DailyBet: Identifiable {
    let id = UUID()
    let book: Book
    let dailyGoal: Int // pages to read today
    let currentProgress: Int // pages read so far today
    let totalDays: Int
    let dayNumber: Int
    let betId: UUID // Reference to original bet
    
    var progressPercentage: Double {
        return min(Double(currentProgress) / Double(dailyGoal), 1.0)
    }
    
    var isCompleted: Bool {
        return currentProgress >= dailyGoal
    }
}

struct DailyBetsView: View {
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    @StateObject private var sessionViewModel = ReadingSessionViewModel()
    
    // Convert placed bets to daily bets
    private var dailyBets: [DailyBet] {
        return readSlipViewModel.placedBets.map { placedBet in
            let currentProgress = readSlipViewModel.dailyProgress[placedBet.id] ?? 0
            return DailyBet(
                book: placedBet.book,
                dailyGoal: placedBet.pagesPerDay,
                currentProgress: currentProgress,
                totalDays: placedBet.totalDays,
                dayNumber: 1, // Start at day 1
                betId: placedBet.id
            )
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                if dailyBets.isEmpty {
                    // Empty state
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
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(dailyBets) { bet in
                            DailyBetRowView(
                                bet: bet,
                                onStartReading: {
                                    sessionViewModel.startReadingSession(for: bet.betId)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            
            // Starting Page Input Overlay
            if sessionViewModel.showingStartPageInput, let session = sessionViewModel.currentSession,
               let bet = readSlipViewModel.placedBets.first(where: { $0.id == session.betId }) {
                StartingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book,
                    lastReadPage: readSlipViewModel.getLastReadPage(for: session.betId)
                ) { startingPage in
                    // Starting page is handled by the sessionViewModel
                }
                .transition(.opacity)
            }
            
            // Reading Timer Overlay - UPDATED: Cover entire screen
            if sessionViewModel.isReading, let session = sessionViewModel.currentSession,
               let bet = readSlipViewModel.placedBets.first(where: { $0.id == session.betId }) {
                ReadingTimerView(sessionViewModel: sessionViewModel, book: bet.book)
                    .transition(.opacity)
                    .zIndex(1000) // ADDED: Ensure it's on top
            }
            
            // Ending Page Input Overlay
            if sessionViewModel.showingEndPageInput, let session = sessionViewModel.currentSession,
               let bet = readSlipViewModel.placedBets.first(where: { $0.id == session.betId }) {
                EndingPageInputView(
                    sessionViewModel: sessionViewModel,
                    book: bet.book
                ) { endingPage in
                    // FIXED: Pass both starting and ending pages
                    readSlipViewModel.updateReadingProgress(
                        for: session.betId,
                        startingPage: session.startingPage,
                        endingPage: endingPage
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingStartPageInput)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.isReading)
        .animation(.easeInOut(duration: 0.3), value: sessionViewModel.showingEndPageInput)
    }
}

// DailyBetRowView remains the same...
struct DailyBetRowView: View {
    let bet: DailyBet
    let onStartReading: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack(spacing: 12) {
                // TC Badge (like SGP in FanDuel)
                Text("TC")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 16)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.goodreadsBrown)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Towards Completion")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                    
                    HStack(spacing: 8) {
                        // Progress circle
                        Circle()
                            .stroke(
                                bet.isCompleted ? Color.green : Color.goodreadsAccent.opacity(0.3),
                                lineWidth: 2
                            )
                            .fill(bet.isCompleted ? Color.green.opacity(0.1) : Color.clear)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: bet.isCompleted ? "checkmark" : "")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.green)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bet.book.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.goodreadsBrown)
                                .lineLimit(1)
                            
                            Text("to read \(bet.dailyGoal) pages")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                        }
                    }
                }
                
                Spacer()
                
                // Day indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Day \(bet.dayNumber)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.goodreadsAccent)
                    Text("of \(bet.totalDays)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.7))
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Spacer()
                    Text("\(bet.currentProgress)/\(bet.dailyGoal) pages")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
                
                // Custom progress bar
                GeometryReader { geometry in
                    let totalWidth = geometry.size.width
                    let progressWidth = totalWidth * bet.progressPercentage
                    let targetPosition = totalWidth * 0.85
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.goodreadsBeige)
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        bet.isCompleted ? .green : .goodreadsBrown,
                                        bet.isCompleted ? .green.opacity(0.8) : .goodreadsAccent
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressWidth, height: 8)
                        
                        // Start marker (0)
                        VStack(spacing: 2) {
                            Text("0")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.goodreadsAccent)
                            Circle()
                                .fill(Color.goodreadsAccent.opacity(0.7))
                                .frame(width: 10, height: 10)
                                .offset(y: 4)
                        }
                        .offset(x: -5, y: -8)
                        
                        // Target marker
                        VStack(spacing: 2) {
                            Text("\(bet.dailyGoal)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(bet.isCompleted ? .green : .goodreadsBrown)
                            Circle()
                                .fill(bet.isCompleted ? Color.green : Color.goodreadsBrown)
                                .frame(width: 10, height: 10)
                                .offset(y: 4)
                        }
                        .offset(x: targetPosition - 5, y: -8)
                    }
                }
                .frame(height: 24)
            }
            
            // Read/Completed button
            Button(action: onStartReading) {
                HStack(spacing: 8) {
                    Image(systemName: bet.isCompleted ? "checkmark" : "book.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(bet.isCompleted ? "Completed" : "Read")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(bet.isCompleted ? .goodreadsAccent : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            bet.isCompleted
                            ? Color.goodreadsBeige.opacity(0.8)
                            : Color.goodreadsBrown
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    bet.isCompleted ? Color.goodreadsAccent.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
            }
            .disabled(bet.isCompleted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            bet.isCompleted ? Color.green.opacity(0.3) : Color.goodreadsAccent.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
