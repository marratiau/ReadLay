//
//  QuickPageSetupView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//



import SwiftUI

// MARK: - Quick Page Setup View
struct QuickPageSetupView: View {
    @Binding var book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var preferences: ReadingPreferences
    @FocusState private var startPageFocused: Bool
    @FocusState private var endPageFocused: Bool

    init(book: Binding<Book>) {
        self._book = book
        self._preferences = State(initialValue: book.wrappedValue.readingPreferences)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    quickOptionsSection

                    if preferences.pageCountingStyle == .custom {
                        customRangeSection
                    }

                    summarySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(backgroundGradient)
            .navigationTitle("Reading Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.goodreadsAccent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        hideKeyboard()
                        book.readingPreferences = preferences
                        dismiss()
                    }
                    .foregroundColor(.goodreadsBrown)
                    .fontWeight(.semibold)
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
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.goodreadsBeige,
                Color.goodreadsWarm.opacity(0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.pages")
                .font(.system(size: 40))
                .foregroundColor(.goodreadsBrown)

            Text("How do you want to read this book?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.goodreadsBrown)
                .multilineTextAlignment(.center)

            Text(book.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.goodreadsAccent)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(book.totalPages) total pages")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.8))
        }
    }

    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Style")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)

            VStack(spacing: 12) {
                ForEach(ReadingPreferences.PageCountingStyle.allCases, id: \.self) { style in
                    QuickOptionCard(
                        style: style,
                        isSelected: preferences.pageCountingStyle == style,
                        effectivePages: calculateEffectivePages(for: style),
                        onSelect: {
                            preferences.pageCountingStyle = style
                            updatePreferencesForStyle(style)
                        }
                    )
                }
            }
        }
    }

    private var customRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Page Range")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.goodreadsBrown)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Page")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsBrown)

                    TextField("1", value: $preferences.customStartPage, format: .number)
                        .font(.system(size: 16))
                        .focused($startPageFocused)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            startPageFocused ?
                                                Color.goodreadsBrown.opacity(0.7) :
                                                Color.goodreadsAccent.opacity(0.3),
                                            lineWidth: startPageFocused ? 2 : 1
                                        )
                                )
                        )
                        .onTapGesture {
                            startPageFocused = true
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("End Page")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsBrown)

                    TextField("\(book.totalPages)", value: $preferences.customEndPage, format: .number)
                        .font(.system(size: 16))
                        .focused($endPageFocused)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            endPageFocused ?
                                                Color.goodreadsBrown.opacity(0.7) :
                                                Color.goodreadsAccent.opacity(0.3),
                                            lineWidth: endPageFocused ? 2 : 1
                                        )
                                )
                        )
                        .onTapGesture {
                            endPageFocused = true
                        }
                }
            }

            Button("Reset to Auto-Detect") {
                preferences.customStartPage = nil
                preferences.customEndPage = nil
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.goodreadsBrown)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var summarySection: some View {
        VStack(spacing: 12) {
            Text("Your Reading Goal")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)

            let effectivePages = calculateEffectivePages(for: preferences.pageCountingStyle)
            let startPage = calculateStartPage(for: preferences.pageCountingStyle)
            let endPage = calculateEndPage(for: preferences.pageCountingStyle)

            HStack {
                VStack {
                    Text("\(effectivePages)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    Text("Pages to Read")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }

                Spacer()

                VStack {
                    Text("\(startPage) - \(endPage)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    Text("Page Range")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsBrown.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.goodreadsBrown.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }

    // MARK: - Helper Methods

    private func hideKeyboard() {
        startPageFocused = false
        endPageFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func updatePreferencesForStyle(_ style: ReadingPreferences.PageCountingStyle) {
        switch style {
        case .inclusive:
            preferences.includeFrontMatter = true
            preferences.includeBackMatter = true
            preferences.customStartPage = nil
            preferences.customEndPage = nil
        case .mainOnly:
            preferences.includeFrontMatter = false
            preferences.includeBackMatter = false
            preferences.customStartPage = nil
            preferences.customEndPage = nil
        case .custom:
            preferences.customStartPage = preferences.customStartPage ?? 1
            preferences.customEndPage = preferences.customEndPage ?? book.totalPages
        }
    }

    private func calculateEffectivePages(for style: ReadingPreferences.PageCountingStyle) -> Int {
        switch style {
        case .inclusive:
            return book.totalPages
        case .mainOnly:
            return book.totalPages - preferences.estimatedFrontMatterPages - preferences.estimatedBackMatterPages
        case .custom:
            guard let start = preferences.customStartPage,
                  let end = preferences.customEndPage else {
                return book.totalPages
            }
            return max(0, end - start + 1)
        }
    }

    private func calculateStartPage(for style: ReadingPreferences.PageCountingStyle) -> Int {
        switch style {
        case .inclusive:
            return 1
        case .mainOnly:
            return preferences.estimatedFrontMatterPages + 1
        case .custom:
            return preferences.customStartPage ?? 1
        }
    }

    private func calculateEndPage(for style: ReadingPreferences.PageCountingStyle) -> Int {
        switch style {
        case .inclusive:
            return book.totalPages
        case .mainOnly:
            return book.totalPages - preferences.estimatedBackMatterPages
        case .custom:
            return preferences.customEndPage ?? book.totalPages
        }
    }
}

// MARK: - Quick Option Card
struct QuickOptionCard: View {
    let style: ReadingPreferences.PageCountingStyle
    let isSelected: Bool
    let effectivePages: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .goodreadsBrown)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .goodreadsBrown)

                    Text(style.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .goodreadsAccent)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(effectivePages)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .white : .goodreadsBrown)

                    Text("pages")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .goodreadsAccent)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .goodreadsAccent.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.goodreadsBrown : Color.goodreadsWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
