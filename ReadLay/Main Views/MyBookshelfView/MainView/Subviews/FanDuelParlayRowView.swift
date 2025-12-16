

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
        HStack(spacing: 12) {
            // Book cover
            bookCover

            // Book info
            bookInfo

            Spacer(minLength: 4)

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
        .padding(.vertical, 10)
        .background(cardBackground)
        .frame(height: 75)
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
                .font(.nunitoSemiBold(size: 16))
                .foregroundColor(.readlayMediumBlue)
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
                        .overlay(ProgressView().scaleEffect(0.8).tint(.white))
                }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(currentBook.spineColor.opacity(0.8))
                    .overlay(
                        VStack(spacing: 1) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                            Text(currentBook.title.prefix(1))
                                .font(.nunitoBold(size: 12))
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .frame(width: 36, height: 54)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    }

    // MARK: - Book Info
    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(currentBook.title)
                    .font(.nunitoBold(size: 15))
                    .foregroundColor(.readlayDarkBrown)
                    .lineLimit(1)

                // Setup button
                Button(action: {
                    hideKeyboard()
                    onEditPreferences?()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.readlayTan.opacity(0.7))
                }
            }

            if let author = currentBook.author {
                Text(author)
                    .font(.nunitoMedium(size: 11))
                    .foregroundColor(.readlayTan)
                    .lineLimit(1)
            }

            // Page info or reading preference
            if currentBook.hasCustomReadingPreferences {
                Text(currentBook.readingPreferenceSummary)
                    .font(.nunitoMedium(size: 9))
                    .foregroundColor(.readlayLightBlue)
                    .lineLimit(1)
            } else {
                Text("\(currentBook.effectiveTotalPages) pages")
                    .font(.nunitoMedium(size: 9))
                    .foregroundColor(.readlayTan.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Active Bet Indicator
    private var activeBetIndicator: some View {
        HStack(spacing: 6) {
            VStack(alignment: .trailing, spacing: 3) {
                Text("IN PROGRESS")
                    .font(.nunitoBold(size: 9))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.readlayLightBlue)
                    )

                if let readingBet = readSlipViewModel.getActiveReadingBet(for: currentBook.id) {
                    Text(readingBet.formattedTimeRemaining)
                        .font(.nunitoSemiBold(size: 11))
                        .foregroundColor(.readlayLightBlue)
                }
            }

            Button(action: {
                hideKeyboard()
                onNavigateToActiveBets?()
            }) {
                Text("View")
                    .font(.nunitoBold(size: 12))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.readlayMediumBlue)
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
                .font(.nunitoBold(size: 11))
                .foregroundColor(.readlayDarkBrown)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused(focusState)
                .frame(width: 22, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.readlayCream.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    focusState.wrappedValue ?
                                        Color.readlayMediumBlue.opacity(0.7) :
                                        Color.readlayTan.opacity(0.4),
                                    lineWidth: focusState.wrappedValue ? 1.5 : 1
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
                .font(.nunitoSemiBold(size: 7))
                .foregroundColor(.readlayTan.opacity(0.7))
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
                    .font(.nunitoBold(size: 12))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(selectedOdds == calculateOdds(totalDays: totalDays) ? Color.readlayDarkBrown : Color.readlayMediumBlue)
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
                .font(.system(size: 18))
                .foregroundColor(.readlayTan.opacity(0.6))
                .background(Circle().fill(Color.white))
        }
    }

    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(hasActiveBets ? Color.readlayLightBlue.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hasActiveBets ? Color.readlayLightBlue.opacity(0.3) : Color.readlayTan.opacity(0.2),
                        lineWidth: hasActiveBets ? 2 : 1
                    )
            )
            .shadow(color: Color.readlayDarkBrown.opacity(0.1), radius: 6, x: 0, y: 3)
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
        // Use centralized OddsCalculator for consistency
        return OddsCalculator.calculateReadingOdds(book: currentBook, timeframeDays: totalDays)
    }
}
