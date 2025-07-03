//
//  FanDuelParlayRowView 2.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct FanDuelParlayRowView: View {
    let book: Book
    var onClose: () -> Void
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var selectedOdds: String? = nil
    
    // ADDED: State for custom timeframes
    @State private var dayText: String = "1"
    @State private var weekText: String = "1"
    @State private var monthText: String = "1"
    
    @State private var dayCount: Int = 1
    @State private var weekCount: Int = 1
    @State private var monthCount: Int = 1

    var body: some View {
        HStack(spacing: 12) {
            bookCoverView
            bookDetailsView
            Spacer()
            customOddsSection
            closeButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardBackground)
        .frame(height: 72)
        .onAppear {
            dayText = String(dayCount)
            weekText = String(weekCount)
            monthText = String(monthCount)
        }
    }
    
    // MARK: - Book Cover
    private var bookCoverView: some View {
        Group {
            if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(0.65, contentMode: .fit)
                } placeholder: {
                    coverPlaceholder
                }
                .frame(width: 40, height: 60)
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            } else {
                defaultCoverView
            }
        }
    }
    
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(book.spineColor.opacity(0.8))
            .overlay(
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            )
    }
    
    private var defaultCoverView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(book.spineColor.opacity(0.8))
            .frame(width: 40, height: 60)
            .overlay(
                VStack(spacing: 2) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    Text(book.title.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Book Details
    private var bookDetailsView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(book.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.goodreadsBrown)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            if let author = book.author {
                Text(author)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            
            HStack(spacing: 3) {
                Image(systemName: "doc.text")
                    .font(.system(size: 9))
                    .foregroundColor(.goodreadsAccent.opacity(0.8))
                Text("\(book.totalPages) pages")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.goodreadsAccent.opacity(0.8))
            }
        }
        .frame(maxWidth: 120, alignment: .leading)
    }
    
    // MARK: - Custom Odds Section
    private var customOddsSection: some View {
        HStack(spacing: 6) {
            // Days
            timeframeColumn(
                textBinding: $dayText,
                count: dayCount,
                unit: dayCount == 1 ? "day" : "days",
                totalDays: dayCount,
                index: 0
            )
            
            // Weeks
            timeframeColumn(
                textBinding: $weekText,
                count: weekCount,
                unit: weekCount == 1 ? "week" : "weeks",
                totalDays: weekCount * 7,
                index: 1
            )
            
            // Months
            timeframeColumn(
                textBinding: $monthText,
                count: monthCount,
                unit: monthCount == 1 ? "month" : "months",
                totalDays: monthCount * 30,
                index: 2
            )
        }
    }
    
    private func timeframeColumn(textBinding: Binding<String>, count: Int, unit: String, totalDays: Int, index: Int) -> some View {
        VStack(spacing: 3) {
            // Text input for number
            TextField("1", text: textBinding)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.goodreadsBrown)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 20, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.goodreadsBeige.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.goodreadsAccent.opacity(0.4), lineWidth: 0.5)
                        )
                )
                .onChange(of: textBinding.wrappedValue) { newValue in
                    updateCount(newValue, for: index)
                }
            
            // Unit label
            Text(unit)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
                .textCase(.uppercase)
                .lineLimit(1)
            
            // Odds button
            Button(action: {
                let odds = calculateOdds(totalDays: totalDays)
                let timeframe = formatTimeframe(count: count, unit: unit)
                
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedOdds = selectedOdds == odds ? nil : odds
                    readSlipViewModel.addBet(book: book, timeframe: timeframe, odds: odds)
                }
            }) {
                Text(calculateOdds(totalDays: totalDays))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selectedOdds == calculateOdds(totalDays: totalDays) ? .white : .goodreadsBrown)
                    .frame(width: 46, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedOdds == calculateOdds(totalDays: totalDays) ? Color.goodreadsBrown : Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedOdds == calculateOdds(totalDays: totalDays) ? Color.clear : Color.goodreadsAccent.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .scaleEffect(selectedOdds == calculateOdds(totalDays: totalDays) ? 1.05 : 1.0)
        }
        .frame(width: 46)
    }
    
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.goodreadsAccent.opacity(0.6))
                .background(Circle().fill(Color.goodreadsBeige))
        }
        .padding(.leading, 4)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.goodreadsWarm)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.goodreadsBrown.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func updateCount(_ text: String, for index: Int) {
        // Filter to numbers only
        let filteredText = text.filter { $0.isNumber }
        
        // Validate range (1-30)
        if let value = Int(filteredText), value >= 1 && value <= 30 {
            switch index {
            case 0:
                dayCount = value
                dayText = String(value)
            case 1:
                weekCount = value
                weekText = String(value)
            case 2:
                monthCount = value
                monthText = String(value)
            default:
                break
            }
        } else if filteredText.isEmpty {
            // Handle empty field temporarily
            switch index {
            case 0: dayText = ""
            case 1: weekText = ""
            case 2: monthText = ""
            default: break
            }
        } else {
            // Invalid input - reset to previous valid value
            switch index {
            case 0: dayText = String(dayCount)
            case 1: weekText = String(weekCount)
            case 2: monthText = String(monthCount)
            default: break
            }
        }
    }
    
    private func formatTimeframe(count: Int, unit: String) -> String {
        return "\(count) \(unit.capitalized)"
    }
    
    private func calculateOdds(totalDays: Int) -> String {
        let baseMultiplier = book.difficulty.multiplier
        let pagesPerDay = Double(book.totalPages) / Double(totalDays)
        
        let difficultyFactor: Double
        if totalDays <= 3 {
            difficultyFactor = min(pagesPerDay / 15.0, 10.0)
        } else if totalDays <= 7 {
            difficultyFactor = min(pagesPerDay / 20.0, 8.0)
        } else if totalDays <= 21 {
            difficultyFactor = min(pagesPerDay / 12.0, 4.0)
        } else {
            difficultyFactor = min(pagesPerDay / 8.0, 2.0)
        }
        
        let finalOdds = 100 + Int((difficultyFactor * baseMultiplier * 40))
        let clampedOdds = min(max(finalOdds, 105), 999)
        
        return "+\(clampedOdds)"
    }
}
