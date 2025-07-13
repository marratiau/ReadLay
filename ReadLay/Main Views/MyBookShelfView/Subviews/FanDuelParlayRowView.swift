//
//  FanDuelParlayRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//
//  FanDuelParlayRowView.swift - UPDATED WITH READING PREFERENCES
//  Key changes: Added reading preferences setup before betting

import SwiftUI

struct FanDuelParlayRowView: View {
    let book: Book
    var onClose: () -> Void
    var onNavigateToActiveBets: (() -> Void)?
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var selectedOdds: String? = nil
    
    // ADDED: Reading preferences state
    @State private var showingReadingPreferences = false
    @State private var currentBook: Book // Make book mutable for preferences
    
    // Custom timeframe state
    @State private var dayText: String = "1"
    @State private var weekText: String = "1"
    @State private var monthText: String = "1"
    
    @State private var dayCount: Int = 1
    @State private var weekCount: Int = 1
    @State private var monthCount: Int = 1
    
    @FocusState private var dayFieldFocused: Bool
    @FocusState private var weekFieldFocused: Bool
    @FocusState private var monthFieldFocused: Bool
    
    // Initialize with mutable book
    init(book: Book, onClose: @escaping () -> Void, onNavigateToActiveBets: (() -> Void)? = nil, readSlipViewModel: ReadSlipViewModel) {
        self.book = book
        self._currentBook = State(initialValue: book)
        self.onClose = onClose
        self.onNavigateToActiveBets = onNavigateToActiveBets
        self.readSlipViewModel = readSlipViewModel
    }
    
    private var hasActiveBets: Bool {
        return readSlipViewModel.hasActiveBets(for: currentBook.id)
    }
    
    private var activeReadingBet: ReadingBet? {
        return readSlipViewModel.getActiveReadingBet(for: currentBook.id)
    }
    
    private var activeEngagementBet: EngagementBet? {
        return readSlipViewModel.getActiveEngagementBet(for: currentBook.id)
    }
    
    private var isAnyFieldFocused: Bool {
        return dayFieldFocused || weekFieldFocused || monthFieldFocused
    }

    var body: some View {
        HStack(spacing: 12) {
            bookCoverView
            
            if hasActiveBets {
                bookInProgressView
            } else {
                VStack(spacing: 8) {
                    bookDetailsView
                    
                    // ADDED: Reading preferences summary and setup button
                    if currentBook.hasCustomReadingPreferences {
                        readingPreferencesSummary
                    }
                    
                    Spacer()
                    customOddsSection
                }
            }
            
            closeButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardBackground)
        .frame(height: hasActiveBets ? 72 : (currentBook.hasCustomReadingPreferences ? 120 : 72))
        .onAppear {
            dayText = String(dayCount)
            weekText = String(weekCount)
            monthText = String(monthCount)
        }
        .onTapGesture {
            if isAnyFieldFocused {
                hideKeyboard()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsBrown)
            }
        }
        .sheet(isPresented: $showingReadingPreferences) {
            QuickPageSetupView(book: $currentBook)
        }
    }
    
    // MARK: - Book Cover (unchanged)
    private var bookCoverView: some View {
        Group {
            if let coverURL = currentBook.coverImageURL, let url = URL(string: coverURL) {
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
        .onTapGesture {
            // Don't dismiss keyboard when tapping book cover
        }
    }
    
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(currentBook.spineColor.opacity(0.8))
            .overlay(
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            )
    }
    
    private var defaultCoverView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(currentBook.spineColor.opacity(0.8))
            .frame(width: 40, height: 60)
            .overlay(
                VStack(spacing: 2) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    Text(currentBook.title.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Book Details (updated to use currentBook)
    private var bookDetailsView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(currentBook.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                // ADDED: Setup button
                Spacer()
                
                Button(action: {
                    hideKeyboard()
                    showingReadingPreferences = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.goodreadsAccent)
                }
            }
            
            if let author = currentBook.author {
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
                Text("\(currentBook.effectiveTotalPages) pages") // UPDATED: Use effective pages
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.goodreadsAccent.opacity(0.8))
            }
        }
        .frame(maxWidth: 120, alignment: .leading)
        .onTapGesture {
            // Don't dismiss keyboard when tapping book details
        }
    }
    
    // ADDED: Reading preferences summary
    private var readingPreferencesSummary: some View {
        Button(action: {
            hideKeyboard()
            showingReadingPreferences = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: currentBook.readingPreferences.pageCountingStyle.icon)
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
                
                Text(currentBook.readingPreferenceSummary)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Image(systemName: "pencil")
                    .font(.system(size: 8))
                    .foregroundColor(.blue.opacity(0.7))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .frame(maxWidth: 120, alignment: .leading)
    }
    
    // MARK: - Book In Progress View (updated to use currentBook)
    private var bookInProgressView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentBook.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let author = currentBook.author {
                    Text(author)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                
                if let readingBet = activeReadingBet {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                        Text(readingBet.formattedTimeRemaining)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                    }
                } else if activeEngagementBet != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                        Text("Engagement Goals")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: 120, alignment: .leading)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("IN PROGRESS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                    )
                
                Button(action: {
                    hideKeyboard()
                    onNavigateToActiveBets?()
                }) {
                    Text("View Bet")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .onTapGesture {
            // Don't dismiss keyboard when tapping progress view
        }
    }
    
    // MARK: - Custom Odds Section (updated to use effective pages for calculations)
    private var customOddsSection: some View {
        HStack(spacing: 6) {
            timeframeColumn(
                textBinding: $dayText,
                focusState: $dayFieldFocused,
                count: dayCount,
                unit: dayCount == 1 ? "day" : "days",
                totalDays: dayCount,
                index: 0
            )
            
            timeframeColumn(
                textBinding: $weekText,
                focusState: $weekFieldFocused,
                count: weekCount,
                unit: weekCount == 1 ? "week" : "weeks",
                totalDays: weekCount * 7,
                index: 1
            )
            
            timeframeColumn(
                textBinding: $monthText,
                focusState: $monthFieldFocused,
                count: monthCount,
                unit: monthCount == 1 ? "month" : "months",
                totalDays: monthCount * 30,
                index: 2
            )
        }
        .onTapGesture {
            // Don't dismiss keyboard when tapping odds section
        }
    }
    
    private func timeframeColumn(
        textBinding: Binding<String>,
        focusState: FocusState<Bool>.Binding,
        count: Int,
        unit: String,
        totalDays: Int,
        index: Int
    ) -> some View {
        VStack(spacing: 3) {
            TextField("1", text: textBinding)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.goodreadsBrown)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused(focusState)
                .frame(width: 20, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.goodreadsBeige.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(
                                    focusState.wrappedValue ?
                                        Color.goodreadsBrown.opacity(0.7) :
                                        Color.goodreadsAccent.opacity(0.4),
                                    lineWidth: focusState.wrappedValue ? 1.5 : 0.5
                                )
                        )
                )
                .onChange(of: textBinding.wrappedValue) { newValue in
                    updateCount(newValue, for: index)
                }
                .onTapGesture {
                    focusState.wrappedValue = true
                }
            
            Text(unit)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
                .textCase(.uppercase)
                .lineLimit(1)
            
            Button(action: {
                hideKeyboard()
                
                let odds = calculateOdds(totalDays: totalDays)
                let timeframe = formatTimeframe(count: count, unit: unit)
                
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedOdds = selectedOdds == odds ? nil : odds
                    // UPDATED: Pass currentBook with preferences
                    readSlipViewModel.addBet(book: currentBook, timeframe: timeframe, odds: odds)
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
        Button(action: {
            hideKeyboard()
            onClose()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.goodreadsAccent.opacity(0.6))
                .background(Circle().fill(Color.goodreadsBeige))
        }
        .padding(.leading, 4)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(hasActiveBets ? Color.blue.opacity(0.1) : Color.goodreadsWarm)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hasActiveBets ? Color.blue.opacity(0.3) : Color.goodreadsAccent.opacity(0.2),
                        lineWidth: hasActiveBets ? 2 : 1
                    )
            )
            .shadow(color: Color.goodreadsBrown.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func hideKeyboard() {
        dayFieldFocused = false
        weekFieldFocused = false
        monthFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func updateCount(_ text: String, for index: Int) {
        let filteredText = text.filter { $0.isNumber }
        
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
            switch index {
            case 0: dayText = ""
            case 1: weekText = ""
            case 2: monthText = ""
            default: break
            }
        } else {
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
    
    // UPDATED: Use effective pages for odds calculation
    private func calculateOdds(totalDays: Int) -> String {
        let baseMultiplier = currentBook.difficulty.multiplier
        let pagesPerDay = Double(currentBook.effectiveTotalPages) / Double(totalDays) // Use effective pages
        
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
