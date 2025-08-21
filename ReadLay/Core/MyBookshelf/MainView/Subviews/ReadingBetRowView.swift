//
//  ReadingBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//
import SwiftUI

// MARK: - ReadingBetRowView (existing, kept for clarity)
struct ReadingBetRowView: View {
    let bet: ReadingBet
    @Binding var wagerText: String
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book title and remove button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bet.book.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)

                    Text("to complete in \(bet.timeframe)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)

                    // Show pages per day
                    Text("\(bet.pagesPerDay) pages per day")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsBrown.opacity(0.8))
                        .padding(.top, 2)
                }

                Spacer()

                // Odds
                Text(bet.odds)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.goodreadsAccent.opacity(0.6))
                }
            }

            // Wager input and potential win
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wager")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)

                    HStack {
                        Text("$")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsBrown)

                        TextField("0", text: $wagerText)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.goodreadsBrown)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("To Win")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)

                    Text("$\(bet.potentialWin, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.goodreadsBeige)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
