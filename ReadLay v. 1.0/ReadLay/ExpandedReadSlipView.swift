//
//  ExpandedReadSlipView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct ExpandedReadSlipView: View {
    @ObservedObject var viewModel: ReadSlipViewModel
    @State private var wagerText: [UUID: String] = [:]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    viewModel.toggleExpanded()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("ReadSlip")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    
                    if viewModel.betSlip.totalBets > 0 {
                        Text("\(viewModel.betSlip.totalBets)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.goodreadsBrown)
                            )
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.betSlip.clearAll()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.goodreadsAccent.opacity(0.2))
            
            // Bets list - constrained height
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.betSlip.readingBets) { bet in
                        BetRowView(
                            bet: bet,
                            wagerText: Binding(
                                get: { wagerText[bet.id] ?? String(format: "%.0f", bet.wager) },
                                set: { newValue in
                                    wagerText[bet.id] = newValue
                                    if let wager = Double(newValue) {
                                        viewModel.updateWager(for: bet.id, wager: wager)
                                    }
                                }
                            ),
                            onRemove: {
                                viewModel.removeBet(id: bet.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 180) // Constrain scroll area
            
            // Place bet section
            if !viewModel.betSlip.readingBets.isEmpty {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.goodreadsAccent.opacity(0.2))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Wager")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                            Text("$\(viewModel.betSlip.totalWager, specifier: "%.2f")")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.goodreadsBrown)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Potential Win")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                            Text("$\(viewModel.betSlip.totalPotentialWin, specifier: "%.2f")")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        viewModel.placeBets()
                    }) {
                        Text("Place ReadSlip")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.goodreadsBrown)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.goodreadsBeige.opacity(0.5))
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.4) // Max 40% of screen height
        .background(Color.goodreadsWarm)
        .onAppear {
            // Initialize wager text for all bets
            for bet in viewModel.betSlip.readingBets {
                if wagerText[bet.id] == nil {
                    wagerText[bet.id] = String(format: "%.0f", bet.wager)
                }
            }
        }
    }
}

struct BetRowView: View {
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
                    
                    // NEW: Show pages per day
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
