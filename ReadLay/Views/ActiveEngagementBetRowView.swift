//
//  ActiveEngagementBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//


//
//  ActiveEngagementBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//
import SwiftUI

// MARK: - ActiveEngagementBetRowView.swift
//  NEW: Active bet row for engagement bets

struct ActiveEngagementBetRowView: View {
    let bet: EngagementBet
    let readSlipViewModel: ReadSlipViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                            .foregroundColor(.goodreadsBrown)
                        
                        Text("Engagement Goals")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.goodreadsBrown)
                    }
                    
                    Text(bet.book.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)
                    
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
                    
                    Text("\(Int(bet.progressPercentage * 100))% complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                }
            }
            
            // Goals progress
            VStack(spacing: 8) {
                ForEach(bet.goals) { goal in
                    HStack(spacing: 12) {
                        Image(systemName: goal.type.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.goodreadsAccent)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.type.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsBrown)
                            
                            Text("\(goal.currentCount)/\(goal.targetCount) completed")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                        }
                        
                        Spacer()
                        
                        // Progress indicator
                        Circle()
                            .stroke(
                                goal.isCompleted ? Color.green : Color.goodreadsAccent.opacity(0.3),
                                lineWidth: 2
                            )
                            .fill(goal.isCompleted ? Color.green.opacity(0.1) : Color.clear)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: goal.isCompleted ? "checkmark" : "")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(goal.isCompleted ? Color.green.opacity(0.1) : Color.goodreadsBeige.opacity(0.5))
                    )
                }
            }
            
            // Overall progress
            HStack {
                Text("Overall Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                
                Spacer()
                
                Text("\(bet.completedGoalsCount)/\(bet.goals.count) goals complete")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
            }
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