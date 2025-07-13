//
//  CleanProgressBar.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//


//
//  CleanProgressBar.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//

import SwiftUI

struct CleanProgressBar: View {
    let currentValue: Int
    let targetValue: Int
    let totalValue: Int
    let currentLabel: String
    let targetLabel: String
    let totalLabel: String
    let progressColor: Color
    let isCompleted: Bool
    
    // Simplified init for reading progress
    init(
        currentPage: Int,
        targetPage: Int,
        totalPages: Int,
        progressColor: Color = .blue,
        isCompleted: Bool = false
    ) {
        self.currentValue = currentPage
        self.targetValue = targetPage
        self.totalValue = totalPages
        self.currentLabel = "\(currentPage)"
        self.targetLabel = "D"
        self.totalLabel = "\(totalPages)"
        self.progressColor = progressColor
        self.isCompleted = isCompleted
    }
    
    // Full init for custom labels
    init(
        currentValue: Int,
        targetValue: Int,
        totalValue: Int,
        currentLabel: String,
        targetLabel: String,
        totalLabel: String,
        progressColor: Color = .blue,
        isCompleted: Bool = false
    ) {
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.totalValue = totalValue
        self.currentLabel = currentLabel
        self.targetLabel = targetLabel
        self.totalLabel = totalLabel
        self.progressColor = progressColor
        self.isCompleted = isCompleted
    }
    
    private var progressPercentage: Double {
        guard totalValue > 0 else { return 0 }
        return Double(currentValue) / Double(totalValue)
    }
    
    private var targetPercentage: Double {
        guard totalValue > 0 else { return 0 }
        return Double(targetValue) / Double(totalValue)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let trackHeight: CGFloat = 8
            let dotSize: CGFloat = 16
            
            VStack(spacing: 8) {
                // Labels above track
                labelsRow(trackWidth: trackWidth, dotSize: dotSize)
                
                // Progress track with dots
                ZStack {
                    // Background track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: trackHeight)
                    
                    // Progress fill
                    HStack {
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(
                                LinearGradient(
                                    colors: [progressColor, progressColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: trackWidth * progressPercentage, height: trackHeight)
                        
                        Spacer(minLength: 0)
                    }
                    
                    // Dots overlay
                    dotsOverlay(trackWidth: trackWidth, dotSize: dotSize)
                }
                .frame(height: dotSize)
            }
        }
        .frame(height: 40)
    }
    
    private func labelsRow(trackWidth: CGFloat, dotSize: CGFloat) -> some View {
        HStack {
            // Start label
            Text("1")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: dotSize, alignment: .center)
            
            Spacer()
            
            // Target label (only if not at start or end)
            if targetPercentage > 0.1 && targetPercentage < 0.9 {
                Text(targetLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(currentValue >= targetValue ? .green : progressColor)
                    .frame(width: dotSize, alignment: .center)
            }
            
            Spacer()
            
            // End label
            Text(totalLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isCompleted ? .green : .secondary)
                .frame(width: dotSize, alignment: .center)
        }
    }
    
    private func dotsOverlay(trackWidth: CGFloat, dotSize: CGFloat) -> some View {
        HStack {
            // Start dot
            progressDot(
                isActive: true,
                isCompleted: currentValue >= 1,
                color: .gray,
                size: dotSize
            )
            
            Spacer()
            
            // Target dot (only show if meaningful position)
            if targetPercentage > 0.1 && targetPercentage < 0.9 {
                progressDot(
                    isActive: currentValue >= targetValue,
                    isCompleted: currentValue >= targetValue,
                    color: currentValue >= targetValue ? .green : progressColor,
                    size: dotSize
                )
            }
            
            Spacer()
            
            // End dot
            progressDot(
                isActive: isCompleted,
                isCompleted: isCompleted,
                color: isCompleted ? .green : progressColor,
                size: dotSize
            )
        }
    }
    
    private func progressDot(
        isActive: Bool,
        isCompleted: Bool,
        color: Color,
        size: CGFloat
    ) -> some View {
        Circle()
            .fill(isCompleted ? color : Color.white)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
            )
            .overlay(
                Group {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.5, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            )
    }
}

// MARK: - Daily Progress Bar (Simplified)
struct DailyProgressBar: View {
    let currentProgress: Int
    let dailyGoal: Int
    let isCompleted: Bool
    
    private var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(currentProgress) / Double(dailyGoal), 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let trackHeight: CGFloat = 8
            let dotSize: CGFloat = 16
            
            VStack(spacing: 8) {
                // Simple labels
                HStack {
                    Text("0")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(dailyGoal)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isCompleted ? .green : .blue)
                }
                
                // Clean track
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: trackHeight)
                    
                    // Progress
                    HStack {
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(
                                LinearGradient(
                                    colors: isCompleted ? [.green, .green.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: trackWidth * progressPercentage, height: trackHeight)
                        
                        Spacer(minLength: 0)
                    }
                    
                    // End dots only
                    HStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        
                        Spacer()
                        
                        Circle()
                            .fill(isCompleted ? .green : Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .overlay(Circle().stroke(isCompleted ? .green : .blue, lineWidth: 2))
                            .overlay(
                                Group {
                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                }
                .frame(height: dotSize)
            }
        }
        .frame(height: 36)
    }
}