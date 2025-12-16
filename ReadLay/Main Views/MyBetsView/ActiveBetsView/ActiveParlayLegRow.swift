//
//  ActiveParlayLegRow.swift
//  ReadLay
//
//  Created by Mateo Arratia on 9/9/25.
//


//
//  ActiveParlayRows.swift
//  ReadLay
//
//  Lightweight rows for parlay legs used in ActiveBetsView.
//

import SwiftUI

struct ActiveParlayLegRow: View {
    let readingBet: ReadingBet
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    let isLastLeg: Bool
    
    private var isComplete: Bool {
        readSlipViewModel.isBookCompleted(for: readingBet.id)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isComplete ? Color.green : Color.goodreadsAccent)
                    .frame(width: 10, height: 10)
                if !isLastLeg {
                    Rectangle()
                        .fill((isComplete ? Color.green : Color.goodreadsAccent).opacity(0.3))
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(readingBet.book.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(readingBet.odds)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.goodreadsBeige)
                        )
                    
                    Text("\(readSlipViewModel.getProgressInPages(for: readingBet.id))/\(readingBet.book.totalPages) pages")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }
            }
            Spacer()
            
            Image(systemName: isComplete ? "checkmark.seal.fill" : "clock.fill")
                .foregroundColor(isComplete ? .green : .goodreadsAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.goodreadsBeige.opacity(0.35))
    }
}

struct ActiveParlayEngagementRow: View {
    let engagementBet: EngagementBet
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    let isLastLeg: Bool
    
    private var completedGoals: Int {
        engagementBet.goals.filter { goal in
            let progress = readSlipViewModel.engagementProgress[engagementBet.id]?[goal.id] ?? 0
            return progress >= goal.targetCount
        }.count
    }
    
    private var isComplete: Bool {
        completedGoals == engagementBet.goals.count
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isComplete ? Color.green : Color.goodreadsAccent)
                    .frame(width: 10, height: 10)
                if !isLastLeg {
                    Rectangle()
                        .fill((isComplete ? Color.green : Color.goodreadsAccent).opacity(0.3))
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(engagementBet.book.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(engagementBet.odds)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.goodreadsBeige)
                        )
                    
                    Text("\(completedGoals)/\(engagementBet.goals.count) goals")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }
            }
            Spacer()
            
            Image(systemName: isComplete ? "checkmark.seal.fill" : "clock.fill")
                .foregroundColor(isComplete ? .green : .goodreadsAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.goodreadsBeige.opacity(0.35))
    }
}
