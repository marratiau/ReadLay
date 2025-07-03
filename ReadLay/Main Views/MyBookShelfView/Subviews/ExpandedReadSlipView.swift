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
    
    // ADDED: Computed property for balance validation
    private var hasInsufficientFunds: Bool {
        return !viewModel.canAffordWager(viewModel.betSlip.totalWager)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
                .background(Color.goodreadsAccent.opacity(0.2))
            
            betsScrollView
            
            if viewModel.betSlip.totalBets > 0 {
                placeBetSection
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        .background(Color.goodreadsWarm)
        .onAppear {
            initializeWagerText()
        }
    }
    
    private var headerSection: some View {
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
            
            // ADDED: Balance display
            VStack(alignment: .trailing, spacing: 2) {
                Text("Balance")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Text("$\(viewModel.currentBalance, specifier: "%.2f")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(hasInsufficientFunds ? .red : .goodreadsBrown)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var betsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Reading bets
                ForEach(viewModel.betSlip.readingBets) { bet in
                    ReadingBetRowView(
                        bet: bet,
                        wagerText: Binding(
                            get: { wagerText[bet.id] ?? String(format: "%.0f", bet.wager) },
                            set: { newValue in
                                wagerText[bet.id] = newValue
                                if let wager = Double(newValue) {
                                    let adjustedWager = min(wager, viewModel.currentBalance)
                                    viewModel.updateWager(for: bet.id, wager: adjustedWager)
                                    // Update the text field if wager was adjusted
                                    if adjustedWager != wager {
                                        wagerText[bet.id] = String(format: "%.0f", adjustedWager)
                                    }
                                }
                            }
                        ),
                        onRemove: {
                            viewModel.removeBet(id: bet.id)
                        }
                    )
                }
                
                // Engagement bets
                ForEach(viewModel.betSlip.engagementBets) { bet in
                    EngagementBetRowView(
                        bet: bet,
                        wagerText: Binding(
                            get: { wagerText[bet.id] ?? String(format: "%.0f", bet.wager) },
                            set: { newValue in
                                wagerText[bet.id] = newValue
                                if let wager = Double(newValue) {
                                    let adjustedWager = min(wager, viewModel.currentBalance)
                                    viewModel.updateEngagementWager(for: bet.id, wager: adjustedWager)
                                    // Update the text field if wager was adjusted
                                    if adjustedWager != wager {
                                        wagerText[bet.id] = String(format: "%.0f", adjustedWager)
                                    }
                                }
                            }
                        ),
                        onRemove: {
                            viewModel.removeEngagementBet(id: bet.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: 200)
    }
    
    private var placeBetSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.goodreadsAccent.opacity(0.2))
            
            // ADDED: Insufficient funds warning
            if hasInsufficientFunds {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    Text("Insufficient funds")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Wager")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                    Text("$\(viewModel.betSlip.totalWager, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(hasInsufficientFunds ? .red : .goodreadsBrown)
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
                Text(hasInsufficientFunds ? "Insufficient Funds" : "Place ReadSlip")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasInsufficientFunds ? Color.gray : Color.goodreadsBrown)
                    )
            }
            .disabled(hasInsufficientFunds)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.goodreadsBeige.opacity(0.5))
    }
    
    private func initializeWagerText() {
        // Initialize wager text for all bets with balance-aware defaults
        for bet in viewModel.betSlip.readingBets {
            if wagerText[bet.id] == nil {
                let adjustedWager = min(bet.wager, viewModel.currentBalance)
                wagerText[bet.id] = String(format: "%.0f", adjustedWager)
            }
        }
        for bet in viewModel.betSlip.engagementBets {
            if wagerText[bet.id] == nil {
                let adjustedWager = min(bet.wager, viewModel.currentBalance)
                wagerText[bet.id] = String(format: "%.0f", adjustedWager)
            }
        }
    }
}
