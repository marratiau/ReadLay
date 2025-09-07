//
//  DailyBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

import SwiftUI

struct DailyBetRowView: View {
    let dailyBet: DailyBet
    @EnvironmentObject var readSlipViewModel: ReadSlipViewModel
    let onStartReading: () -> Void  // ADD THIS
    @State private var isExpanded: Bool = false
    
    private var progressInfo: (current: Int, required: Int, total: Int) {
        let current = readSlipViewModel.getDailyProgress(for: dailyBet.betId)
        return (current, dailyBet.pagesRequired, dailyBet.pagesRequired)
    }
    
    private var progressPercentage: Double {
        guard progressInfo.required > 0 else { return 0 }
        return Double(progressInfo.current) / Double(progressInfo.required)
    }
    
    private var isCompleted: Bool {
        return progressInfo.current >= progressInfo.required
    }
    
    private var progressStatus: ReadingBet.ProgressStatus {
        return readSlipViewModel.getProgressStatus(for: dailyBet.betId)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Day \(dailyBet.dayNumber)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.goodreadsAccent)
                        
                        if dailyBet.isNextDay {
                            Text("(Tomorrow)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(dailyBet.book.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                        .lineLimit(2)
                    
                    if let author = dailyBet.book.author {
                        Text("by \(author)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                    }
                }
                
                Spacer()
                
                statusBadge
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.goodreadsAccent.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCompleted ? Color.green : Color.goodreadsBrown)
                        .frame(width: max(0, geometry.size.width * progressPercentage), height: 8)
                }
            }
            .frame(height: 8)
            
            // Progress text
            HStack {
                Text("\(progressInfo.current) / \(dailyBet.pagesRequired) pages")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsBrown)
                
                Spacer()
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isCompleted ? .green : .goodreadsBrown)
            }
            
            // Action button
            if !dailyBet.isNextDay {
                Button(action: onStartReading) {  // USE THE PASSED CLOSURE
                    HStack {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "book.fill")
                            .font(.system(size: 14))
                        
                        Text(isCompleted ? "Completed" : "Start Reading")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(isCompleted ? .green : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCompleted ? Color.green.opacity(0.2) : Color.goodreadsBrown)
                    )
                }
                .disabled(isCompleted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? Color.green.opacity(0.05) : Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCompleted ? Color.green.opacity(0.3) : Color.goodreadsAccent.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var statusBadge: some View {
        Group {
            switch progressStatus {
            case .onTrack:
                Label("On Track", systemImage: "checkmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.1))
                    )
            case .ahead:
                Label("Ahead", systemImage: "arrow.up.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
            case .behind:
                Label("Behind", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.1))
                    )
            case .overdue:
                Label("Overdue", systemImage: "exclamationmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.1))
                    )
            case .completed:
                Label("Done", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.1))
                    )
            }
        }
    }
}
