

import SwiftUI

struct FanDuelParlayRowView: View {
    let book: Book
    var onClose: () -> Void
    var onBookUpdated: ((Book) -> Void)?
    var onNavigateToActiveBets: (() -> Void)?
    var onEditPreferences: (() -> Void)?  // ADDED: Callback to edit preferences
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var selectedOdds: String?

    // REMOVED: showingReadingPreferences state - no longer needed
    @State private var currentBook: Book

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

    init(book: Book,
         onClose: @escaping () -> Void,
         onBookUpdated: ((Book) -> Void)? = nil,
         onNavigateToActiveBets: (() -> Void)? = nil,
         onEditPreferences: (() -> Void)? = nil,  // ADDED
         readSlipViewModel: ReadSlipViewModel) {
        self.book = book
        self._currentBook = State(initialValue: book)
        self.onClose = onClose
        self.onBookUpdated = onBookUpdated
        self.onNavigateToActiveBets = onNavigateToActiveBets
        self.onEditPreferences = onEditPreferences  // ADDED
        self.readSlipViewModel = readSlipViewModel
    }

    private var hasActiveBets: Bool {
        return readSlipViewModel.hasActiveBets(for: currentBook.id)
    }

    private var isAnyFieldFocused: Bool {
        return dayFieldFocused || weekFieldFocused || monthFieldFocused
    }

    var body: some View {
        HStack(spacing: 10) {
            // Book cover
            bookCover

            // Book info
            bookInfo

            Spacer()

            if hasActiveBets {
                // Active bet indicator
                activeBetIndicator
            } else {
                // Custom timeframe inputs
                customTimeframeInputs
            }

            // Close button
            closeButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackground)
        .frame(height: 72)
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
        // REMOVED: .sheet presentation - no longer needed here
    }

    // MARK: - Book Cover
    private var bookCover: some View {
        Group {
            if let coverURL = currentBook.coverImageURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(0.65, contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentBook.spineColor.opacity(0.8))
                        .overlay(ProgressView().scaleEffect(0.6).tint(.white))
                }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(currentBook.spineColor.opacity(0.8))
                    .overlay(
                        VStack(spacing: 1) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                            Text(currentBook.title.prefix(1))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .frame(width: 32, height: 48)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    // MARK: - Book Info
    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(currentBook.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                    .lineLimit(1)

                // Setup button - CHANGED: Now calls the callback instead of showing sheet
                Button(action: {
                    hideKeyboard()
                    onEditPreferences?()  // CHANGED: Call the parent's handler
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.goodreadsAccent.opacity(0.7))
                }
            }

            if let author = currentBook.author {
                Text(author)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .lineLimit(1)
            }

            // Page info or reading preference
            if currentBook.hasCustomReadingPreferences {
                Text(currentBook.readingPreferenceSummary)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.blue)
                    .lineLimit(1)
            } else {
                Text("\(currentBook.effectiveTotalPages) pages")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.goodreadsAccent.opacity(0.8))
            }
        }
        .frame(width: 120, alignment: .leading)
    }

    // MARK: - Active Bet Indicator
    private var activeBetIndicator: some View {
        HStack(spacing: 6) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("IN PROGRESS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                    )

                if let readingBet = readSlipViewModel.getActiveReadingBet(for: currentBook.id) {
                    Text(readingBet.formattedTimeRemaining)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            Button(action: {
                hideKeyboard()
                onNavigateToActiveBets?()
            }) {
                Text("View")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                    .frame(width: 44, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }

    // MARK: - Custom Timeframe Inputs (Horizontal)
    private var customTimeframeInputs: some View {
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
    }

    // MARK: - Timeframe Column (Compact)
    private func timeframeColumn(
        textBinding: Binding<String>,
        focusState: FocusState<Bool>.Binding,
        count: Int,
        unit: String,
        totalDays: Int,
        index: Int
    ) -> some View {
        VStack(spacing: 1) {
            TextField("1", text: textBinding)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.goodreadsBrown)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused(focusState)
                .frame(width: 18, height: 14)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.goodreadsBeige.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(
                                    focusState.wrappedValue ?
                                        Color.goodreadsBrown.opacity(0.7) :
                                        Color.goodreadsAccent.opacity(0.4),
                                    lineWidth: focusState.wrappedValue ? 1 : 0.5
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
                .font(.system(size: 6, weight: .semibold))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
                .textCase(.uppercase)
                .lineLimit(1)

            Button(action: {
                hideKeyboard()

                let odds = calculateOdds(totalDays: totalDays)
                let timeframe = formatTimeframe(count: count, unit: unit)

                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedOdds = selectedOdds == odds ? nil : odds
                    readSlipViewModel.addBet(book: currentBook, timeframe: timeframe, odds: odds)
                }
            }) {
                Text(calculateOdds(totalDays: totalDays))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(selectedOdds == calculateOdds(totalDays: totalDays) ? .white : .goodreadsBrown)
                    .frame(width: 44, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(selectedOdds == calculateOdds(totalDays: totalDays) ? Color.goodreadsBrown : Color.goodreadsBeige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        selectedOdds == calculateOdds(totalDays: totalDays) ? Color.clear : Color.goodreadsAccent.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .scaleEffect(selectedOdds == calculateOdds(totalDays: totalDays) ? 1.05 : 1.0)
        }
        .frame(width: 44)
    }

    // MARK: - Close Button
    private var closeButton: some View {
        Button(action: {
            hideKeyboard()
            onClose()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.goodreadsAccent.opacity(0.6))
                .background(Circle().fill(Color.goodreadsBeige))
        }
    }

    // MARK: - Card Background
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

    private func calculateOdds(totalDays: Int) -> String {
        let baseMultiplier = currentBook.difficulty.multiplier
        let pagesPerDay = Double(currentBook.effectiveTotalPages) / Double(totalDays)

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
