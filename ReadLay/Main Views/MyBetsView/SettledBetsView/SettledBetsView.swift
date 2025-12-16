//
//  SettledBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct SettledBetsView: View {
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel

    var body: some View {
        ScrollView {
            if readSlipViewModel.completedBets.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer().frame(height: 80)
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.goodreadsAccent.opacity(0.5))
                    Text("No Settled Bets")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    Text("Your completed reading challenges will appear here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(readSlipViewModel.completedBets) { completedBet in
                        SettledBetRowView(completedBet: completedBet)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

struct SettledBetRowView: View {
    let completedBet: CompletedBet

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: completedBet.completedDate)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(completedBet.originalBet.book.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)

                    Text("Completed in \(completedBet.originalBet.timeframe)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsAccent)

                    Text("Finished on \(formattedDate)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(completedBet.wasSuccessful ? "WON" : "LOST")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(completedBet.wasSuccessful ? Color.green : Color.red)
                        )

                    if completedBet.wasSuccessful {
                        Text("+$\(completedBet.payout, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("-$\(completedBet.originalBet.wager, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }

            // Stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pages Read")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text("\(completedBet.totalPagesRead)/\(completedBet.originalBet.book.totalPages)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Original Odds")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text(completedBet.originalBet.odds)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            completedBet.wasSuccessful ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
