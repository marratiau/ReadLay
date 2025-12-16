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
    @State private var parlayWagerText: String = ""  // ADDED: Single wager input for parlay

    // ADDED: Computed property for balance validation
    private var hasInsufficientFunds: Bool {
        return !viewModel.canAffordWager(viewModel.betSlip.totalWager)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .background(Color.readlayTan.opacity(0.2))

            betsScrollView

            if viewModel.betSlip.totalBets > 0 {
                placeBetSection
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        .background(Color.white)
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.readlayDarkBrown)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("ReadSlip")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.readlayDarkBrown)

                if viewModel.betSlip.totalBets > 0 {
                    Text("\(viewModel.betSlip.totalBets)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.readlayDarkBrown)
                        )
                }
            }

            Spacer()

            // Balance display
            VStack(alignment: .trailing, spacing: 2) {
                Text("Balance")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.readlayTan)
                Text("$\(viewModel.currentBalance, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(hasInsufficientFunds ? .red : .readlayDarkBrown)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var betsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.betSlip.isParlay {
                    // FanDuel-style parlay layout with vertical connectors
                    parlayLayoutView
                } else {
                    // Single bet - standard layout
                    standardBetsLayout
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Parlay Layout (FanDuel Style)
    private var parlayLayoutView: some View {
        VStack(spacing: 0) {
            // Parlay header with combined odds
            parlayHeader

            Divider()
                .background(Color.readlayTan.opacity(0.3))
                .padding(.vertical, 8)

            // Parlay legs with vertical connector
            ZStack(alignment: .topLeading) {
                // Vertical connecting line
                verticalConnector

                // Individual legs
                VStack(spacing: 16) {
                    ForEach(Array(viewModel.betSlip.readingBets.enumerated()), id: \.element.id) { index, bet in
                        parlayLegRow(bet: bet, index: index, isLast: index == viewModel.betSlip.readingBets.count - 1)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.readlayMediumBlue.opacity(0.3), lineWidth: 2)
                )
        )
    }

    // Parlay header showing combined odds and wager input
    private var parlayHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.readlayMediumBlue)

                Text(viewModel.betSlip.parlayDescription.uppercased())
                    .font(.nunitoBold(size: 14))
                    .foregroundColor(.readlayDarkBrown)

                Spacer()

                // Combined odds badge
                Text(viewModel.betSlip.calculateParlayOdds())
                    .font(.nunitoBold(size: 20))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.readlayMediumBlue)
                    )
            }

            // Parlay wager input
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wager")
                        .font(.nunitoMedium(size: 11))
                        .foregroundColor(.readlayTan)

                    HStack {
                        Text("$")
                            .font(.nunitoMedium(size: 16))
                            .foregroundColor(.readlayDarkBrown)

                        TextField("0", text: $parlayWagerText)
                            .font(.nunitoBold(size: 16))
                            .foregroundColor(.readlayDarkBrown)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .onChange(of: parlayWagerText) { newValue in
                                if let wager = Double(newValue) {
                                    let adjustedWager = min(wager, viewModel.currentBalance)
                                    // Update all bets in parlay with same wager
                                    for bet in viewModel.betSlip.readingBets {
                                        viewModel.updateWager(for: bet.id, wager: adjustedWager)
                                    }
                                    for bet in viewModel.betSlip.engagementBets {
                                        viewModel.updateEngagementWager(for: bet.id, wager: adjustedWager)
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.readlayCream.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.readlayTan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("To Win")
                        .font(.nunitoMedium(size: 11))
                        .foregroundColor(.readlayTan)

                    Text("$\(viewModel.betSlip.totalPotentialWin, specifier: "%.2f")")
                        .font(.nunitoBold(size: 16))
                        .foregroundColor(.green)
                }
            }
        }
    }

    // Vertical connecting line for parlay legs
    private var verticalConnector: some View {
        VStack(spacing: 0) {
            ForEach(0..<viewModel.betSlip.readingBets.count, id: \.self) { index in
                Rectangle()
                    .fill(Color.readlayMediumBlue.opacity(0.4))
                    .frame(width: 2)
                    .frame(height: index == viewModel.betSlip.readingBets.count - 1 ? 0 : 60)
            }
        }
        .padding(.leading, 9)
        .padding(.top, 10)
    }

    // Individual parlay leg row
    private func parlayLegRow(bet: ReadingBet, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Connection dot
            Circle()
                .fill(Color.readlayMediumBlue)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.readlayMediumBlue, lineWidth: 2)
                )

            // Leg details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bet.book.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.readlayDarkBrown)
                        .lineLimit(1)

                    Spacer()

                    // Individual leg odds
                    Text(bet.odds)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.readlayTan)
                }

                Text("\(bet.timeframe) • \(bet.pagesPerDay) pages/day")
                    .font(.system(size: 12))
                    .foregroundColor(.readlayTan.opacity(0.8))

                // Remove button
                Button(action: {
                    viewModel.removeBet(id: bet.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Remove")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.red.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Standard Bets Layout (Non-Parlay)
    private var standardBetsLayout: some View {
        Group {
            // Reading bets
            ForEach(viewModel.betSlip.readingBets) { bet in
                ReadingBetRowView(
                    bet: bet,
                    wagerText: Binding(
                        get: { wagerText[bet.id] ?? "" },  // Start blank
                        set: { newValue in
                            wagerText[bet.id] = newValue
                            if let wager = Double(newValue) {
                                let adjustedWager = min(wager, viewModel.currentBalance)
                                viewModel.updateWager(for: bet.id, wager: adjustedWager)
                                // Update the text field if wager was adjusted
                                if adjustedWager != wager {
                                    wagerText[bet.id] = String(format: "%.0f", adjustedWager)
                                }
                            } else if newValue.isEmpty {
                                // If empty, set wager to 0
                                viewModel.updateWager(for: bet.id, wager: 0)
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
                        get: { wagerText[bet.id] ?? "" },  // Start blank
                        set: { newValue in
                            wagerText[bet.id] = newValue
                            if let wager = Double(newValue) {
                                let adjustedWager = min(wager, viewModel.currentBalance)
                                viewModel.updateEngagementWager(for: bet.id, wager: adjustedWager)
                                // Update the text field if wager was adjusted
                                if adjustedWager != wager {
                                    wagerText[bet.id] = String(format: "%.0f", adjustedWager)
                                }
                            } else if newValue.isEmpty {
                                // If empty, set wager to 0
                                viewModel.updateEngagementWager(for: bet.id, wager: 0)
                            }
                        }
                    ),
                    onRemove: {
                        viewModel.removeEngagementBet(id: bet.id)
                    }
                )
            }
        }
    }

    private var placeBetSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.readlayTan.opacity(0.2))

            // Insufficient funds warning
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
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Wager")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.readlayTan)
                    Text("$\(viewModel.betSlip.totalWager, specifier: "%.2f")")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(hasInsufficientFunds ? .red : .readlayDarkBrown)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Potential Win")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.readlayTan)
                    Text("$\(viewModel.betSlip.totalPotentialWin, specifier: "%.2f")")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 24)

            Button(action: {
                viewModel.placeBets()
            }) {
                Text(hasInsufficientFunds ? "Insufficient Funds" : "Place ReadSlip")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasInsufficientFunds ? Color.gray : Color.readlayMediumBlue)
                    )
            }
            .disabled(hasInsufficientFunds)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color.readlayCream.opacity(0.2))
    }

    private func initializeWagerText() {
        // Initialize wager text with empty strings (user enters amount manually)
        for bet in viewModel.betSlip.readingBets {
            if wagerText[bet.id] == nil {
                wagerText[bet.id] = ""  // Start blank
            }
        }
        for bet in viewModel.betSlip.engagementBets {
            if wagerText[bet.id] == nil {
                wagerText[bet.id] = ""  // Start blank
            }
        }
        // Parlay wager also starts blank
        if parlayWagerText.isEmpty {
            parlayWagerText = ""
        }
    }
}
