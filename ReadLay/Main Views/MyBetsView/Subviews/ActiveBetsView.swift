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


// MARK: - Updated ActiveBetsView.swift
//  Enhanced to show both reading and engagement bets

import SwiftUI

struct ActiveBetsView: View {
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    
    var body: some View {
        ScrollView {
            if readSlipViewModel.placedBets.isEmpty && readSlipViewModel.placedEngagementBets.isEmpty {
                emptyStateView
            } else {
                activeBetsContent
            }
        }
    }
    
    private var emptyStateView: some View {
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
    }
    
    private var activeBetsContent: some View {
        LazyVStack(spacing: 16) {
            // Reading bets
            ForEach(readSlipViewModel.placedBets) { bet in
                ActiveReadingBetRowView(bet: bet, readSlipViewModel: readSlipViewModel)
            }
            
            // Engagement bets
            ForEach(readSlipViewModel.placedEngagementBets) { bet in
                ActiveEngagementBetRowView(bet: bet, readSlipViewModel: readSlipViewModel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
