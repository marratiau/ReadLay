//
//  ActiveBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

/// EXPLANATION
//
// A value-type instance is an independent initialization of a struct.
// Whenever this instance is assigned to another variable or constant, passed into a function, or returned from a function, a copy of the instance is made, meaning the original remains unchanged.
// This allows us to create many instances from the same struct and use them as independent values, without worrying about modifying previous ones.


import SwiftUI

struct ActiveBetsView: View {
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    
    var body: some View {
        ScrollView {
            if $readSlipViewModel.placedBets.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer().frame(height: 80)
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.goodreadsAccent.opacity(0.5))
                    Text("No Active Bets")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    Text("Your ongoing reading challenges will appear here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(readSlipViewModel.placedBets) { bet in
                        ActiveBetRowView(bet: bet, readSlipViewModel: readSlipViewModel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

struct ActiveBetRowView: View {
    let bet: ReadingBet
    let readSlipViewModel: ReadSlipViewModel
    
    // FIXED: Get current progress from the view model
    private var currentPage: Int {
        return readSlipViewModel.totalProgress[bet.id] ?? 0
    }
    
    private var progressPercentage: Double {
        guard bet.book.totalPages > 0 else { return 0.0 }
        let percentage = Double(currentPage) / Double(bet.book.totalPages)
        return min(max(percentage, 0.0), 1.0) // Clamp between 0 and 1
    }
    
    private var isCompleted: Bool {
        return currentPage >= bet.book.totalPages
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bet.book.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)
                    
                    Text("to complete in \(bet.timeframe)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    
                    HStack(spacing: 8) {
                        Text("$\(bet.wager, specifier: "%.0f") bet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsBrown.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.goodreadsAccent.opacity(0.5))
                        
                        Text("Win $\(bet.potentialWin, specifier: "%.2f")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(bet.odds)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    
                    Text("\(Int(progressPercentage * 100))% complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                }
            }
            
            // FIXED Progress tracking
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reading Progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Spacer()
                    Text("\(currentPage)/\(bet.book.totalPages) pages")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
                
                // FIXED Progress bar with proper calculations
                GeometryReader { geometry in
                    let totalWidth = geometry.size.width
                    let progressWidth = totalWidth * progressPercentage
                    let targetPosition = totalWidth - 10 // Target near the end
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.goodreadsBeige)
                            .frame(height: 8)
                        
                        // Progress fill - FIXED calculation
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isCompleted ? .green : .goodreadsBrown,
                                        isCompleted ? .green.opacity(0.8) : .goodreadsAccent
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(progressWidth, 0), height: 8) // Ensure non-negative width
                        
                        // Start marker (0) - FIXED positioning
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
                        
                        // End marker (total pages) - FIXED positioning
                        VStack(spacing: 2) {
                            Text("\(bet.book.totalPages)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isCompleted ? .green : .goodreadsBrown)
                            Circle()
                                .fill(isCompleted ? Color.green : Color.goodreadsBrown)
                                .frame(width: 10, height: 10)
                                .offset(y: 4)
                        }
                        .offset(x: targetPosition - 5, y: -8)
                        
                        // ADDED: Current progress marker (if progress > 0)
                        if progressPercentage > 0.02 && !isCompleted { // Show if more than 2% progress
                            VStack(spacing: 2) {
                                Text("\(currentPage)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.goodreadsBrown)
                                    )
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.goodreadsBrown, lineWidth: 2)
                                    )
                                    .offset(y: 4)
                            }
                            .offset(x: min(progressWidth - 5, totalWidth - 15), y: -12)
                        }
                    }
                }
                .frame(height: 26)
            }
            
            // ADDED: Days remaining info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text("\(bet.pagesPerDay) pages/day")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time Remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text("\(bet.totalDays) days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCompleted ? Color.green.opacity(0.3) : Color.goodreadsAccent.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
