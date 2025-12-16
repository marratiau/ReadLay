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
    
    // Group active bets by parlay
    private var groupedActiveBets: [(parlayId: UUID?, readingBets: [ReadingBet], engagementBets: [EngagementBet])] {
        var groups: [(UUID?, [ReadingBet], [EngagementBet])] = []
        var processedReadingIds = Set<UUID>()
        var processedEngagementIds = Set<UUID>()
        
        // First, group parlay reading bets
        for bet in readSlipViewModel.placedBets {
            guard !processedReadingIds.contains(bet.id) else { continue }
            
            if let parlayId = bet.parlayId {
                // Find all bets in this parlay
                let parlayReadingBets = readSlipViewModel.placedBets.filter { $0.parlayId == parlayId }
                let parlayEngagementBets = readSlipViewModel.placedEngagementBets.filter { $0.parlayId == parlayId }
                
                // Mark as processed
                parlayReadingBets.forEach { processedReadingIds.insert($0.id) }
                parlayEngagementBets.forEach { processedEngagementIds.insert($0.id) }
                
                // Add parlay group
                groups.append((parlayId, parlayReadingBets, parlayEngagementBets))
            } else {
                // Single reading bet
                processedReadingIds.insert(bet.id)
                groups.append((nil, [bet], []))
            }
        }
        
        // Then add standalone engagement bets
        for bet in readSlipViewModel.placedEngagementBets {
            guard !processedEngagementIds.contains(bet.id) else { continue }
            
            if bet.parlayId == nil {
                processedEngagementIds.insert(bet.id)
                groups.append((nil, [], [bet]))
            }
        }
        
        return groups
    }

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
            ForEach(Array(groupedActiveBets.enumerated()), id: \.offset) { index, group in
                if let parlayId = group.parlayId {
                    // Parlay group
                    ActiveParlayGroup(
                        parlayId: parlayId,
                        readingBets: group.readingBets,
                        engagementBets: group.engagementBets,
                        readSlipViewModel: readSlipViewModel
                    )
                } else {
                    // Single bets
                    ForEach(group.readingBets) { bet in
                        ActiveReadingBetRowView(bet: bet, readSlipViewModel: readSlipViewModel)
                    }
                    
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Active Parlay Group
struct ActiveParlayGroup: View {
    let parlayId: UUID
    let readingBets: [ReadingBet]
    let engagementBets: [EngagementBet]
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    
    private var parlayInfo: ParlayBet? {
        readSlipViewModel.activeParlays.first { $0.id == parlayId }
    }
    
    private var parlayOdds: String {
        parlayInfo?.combinedOdds ?? "+100"
    }
    
    private var legCount: Int {
        readingBets.count + engagementBets.count
    }
    
    private var completedLegs: Int {
        let completedReading = readingBets.filter { bet in
            readSlipViewModel.isBookCompleted(for: bet.id)
        }.count
        
        let completedEngagement = engagementBets.filter { bet in
            // Check if all engagement goals are completed
            bet.goals.allSatisfy { goal in
                let progress = readSlipViewModel.engagementProgress[bet.id]?[goal.id] ?? 0
                return progress >= goal.targetCount
            }
        }.count
        
        return completedReading + completedEngagement
    }
    
    private var parlayStatus: ParlayBet.ParlayStatus {
        if completedLegs == legCount {
            return .won
        } else if let info = parlayInfo, !info.isActive {
            return .lost
        } else {
            return .inProgress
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Parlay header
            parlayHeader
            
            // Parlay legs with connecting line
            ZStack(alignment: .leading) {
                // Vertical connecting line
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: 24, y: 0))
                        path.addLine(to: CGPoint(x: 24, y: geometry.size.height))
                    }
                    .stroke(
                        parlayStatus.color.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2)
                    )
                }
                .frame(width: 48)
                
                // Parlay legs
                VStack(spacing: 0) {
                    // Reading bets
                    ForEach(Array(readingBets.enumerated()), id: \.element.id) { index, bet in
                        ActiveParlayLegRow(
                            readingBet: bet,
                            readSlipViewModel: readSlipViewModel,
                            isLastLeg: index == readingBets.count - 1 && engagementBets.isEmpty
                        )
                    }
                    
                    // Engagement bets
                    ForEach(Array(engagementBets.enumerated()), id: \.element.id) { index, bet in
                        ActiveParlayEngagementRow(
                            engagementBet: bet,
                            readSlipViewModel: readSlipViewModel,
                            isLastLeg: index == engagementBets.count - 1
                        )
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(parlayStatus.color.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var parlayHeader: some View {
        HStack {
            // Parlay badge
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 12, weight: .bold))
                Text("\(legCount) LEG PARLAY")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.goodreadsBrown)
            )
            
            Spacer()
            
            // Progress
            Text("\(completedLegs)/\(legCount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.goodreadsBrown)
            
            // Combined odds
            Text(parlayOdds)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.goodreadsBrown)
            
            // Status
            HStack(spacing: 4) {
                Image(systemName: parlayStatus == .won ? "checkmark.circle.fill" :
                                  parlayStatus == .lost ? "xmark.circle.fill" :
                                  "clock.fill")
                    .font(.system(size: 16))
                Text(parlayStatus.displayText)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(parlayStatus.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(parlayStatus.color.opacity(0.1))
            )
        }
        .padding(16)
        .background(Color.goodreadsBeige.opacity(0.5))
    }
}

