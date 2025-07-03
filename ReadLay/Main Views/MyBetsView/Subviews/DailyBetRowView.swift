//
//  DailyBetRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//

import SwiftUI


struct DailyBetRowView: View {
    let bet: DailyBet
    let onStartReading: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            headerRow
            progressSection
            actionButton
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
    
    // ADDED: Extracted components for better organization
    private var headerRow: some View {
        HStack(spacing: 12) {
            // TC Badge
            Text("TC")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.goodreadsBrown)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Towards Completion")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                
                HStack(spacing: 8) {
                    progressCircle
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bet.book.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.goodreadsBrown)
                            .lineLimit(1)
                        
                        Text("to read \(bet.dailyGoal) pages")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                    }
                }
            }
            
            Spacer()
            
            dayIndicator
        }
    }
    
    private var progressCircle: some View {
        Circle()
            .stroke(
                bet.isCompleted ? Color.green : Color.goodreadsAccent.opacity(0.3),
                lineWidth: 2
            )
            .fill(bet.isCompleted ? Color.green.opacity(0.1) : Color.clear)
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: bet.isCompleted ? "checkmark" : "")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
            )
    }
    
    private var dayIndicator: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Day \(bet.dayNumber)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.goodreadsAccent)
            Text("of \(bet.totalDays)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Spacer()
                Text("\(bet.currentProgress)/\(bet.dailyGoal) pages")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
            }
            
            progressBar
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let progressWidth = totalWidth * bet.progressPercentage
            let targetPosition = totalWidth * 0.85
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.goodreadsBeige)
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                bet.isCompleted ? .green : .goodreadsBrown,
                                bet.isCompleted ? .green.opacity(0.8) : .goodreadsAccent
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth, height: 8)
                
                // Start marker (0)
                VStack(spacing: 2) {
                    Text("0")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.goodreadsAccent)
                    Circle()
                        .fill(Color.goodreadsAccent.opacity(0.7))
                        .frame(width: 10, height: 10)
                        .offset(y: 4)
                }
                .offset(x: -5, y: -8)
                
                // Target marker
                VStack(spacing: 2) {
                    Text("\(bet.dailyGoal)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(bet.isCompleted ? .green : .goodreadsBrown)
                    Circle()
                        .fill(bet.isCompleted ? Color.green : Color.goodreadsBrown)
                        .frame(width: 10, height: 10)
                        .offset(y: 4)
                }
                .offset(x: targetPosition - 5, y: -8)
            }
        }
        .frame(height: 24)
    }
    
    private var actionButton: some View {
        Button(action: onStartReading) {
            HStack(spacing: 8) {
                Image(systemName: bet.isCompleted ? "checkmark" : "book.fill")
                    .font(.system(size: 16, weight: .medium))
                Text(bet.isCompleted ? "Completed" : "Read")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(bet.isCompleted ? .goodreadsAccent : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        bet.isCompleted
                        ? Color.goodreadsBeige.opacity(0.8)
                        : Color.goodreadsBrown
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                bet.isCompleted ? Color.goodreadsAccent.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .disabled(bet.isCompleted)
    }
}
