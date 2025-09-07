
//
//  QuickPageSetupView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/13/25.
//

import SwiftUI

struct QuickPageSetupView: View {
    @Binding var book: Book
    var onSave: (Book) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @State private var preferences: ReadingPreferences
    @FocusState private var startPageFocused: Bool
    @FocusState private var endPageFocused: Bool

    init(book: Binding<Book>, onSave: @escaping (Book) -> Void = { _ in }) {
        self._book = book
        self._preferences = State(initialValue: book.wrappedValue.readingPreferences)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    quickOptionsSection
                    customRangeSectionIfNeeded
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
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.goodreadsAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        hideKeyboard()
                        book.readingPreferences = preferences
                        onSave(book)
                    }
                    .foregroundColor(.goodreadsBrown)
                    .fontWeight(.semibold)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.goodreadsBrown)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.goodreadsBeige, Color.goodreadsWarm.opacity(0.5)]),
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
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
    }

    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Options")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            ForEach(ReadingPreferences.PageCountingStyle.allCases, id: \.self) { style in
                QuickOptionCard(
                    style: style,
                    isSelected: preferences.pageCountingStyle == style,
                    effectivePages: calculateEffectivePages(for: style),
                    onSelect: {
                        hideKeyboard()
                        preferences.pageCountingStyle = style
                        updatePreferences(for: style)
                    }
                )
            }
        }
        .padding(20)
        .background(sectionBackground)
    }

    private var customRangeSectionIfNeeded: some View {
        CustomRangeSectionView(
            preferences: $preferences,
            startPageFocused: _startPageFocused,
            endPageFocused: _endPageFocused
        )
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)
            HStack {
                Text("Effective Pages:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Spacer()
                Text("\(calculateEffectivePages(for: preferences.pageCountingStyle))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
            }
            HStack {
                Text("Page Range:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                Spacer()
                Text("\(calculateStartPage(for: preferences.pageCountingStyle)) - \(calculateEndPage(for: preferences.pageCountingStyle))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
            }
        }
        .padding(20)
        .background(sectionBackground)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.goodreadsWarm)
            .shadow(color: .goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func hideKeyboard() {
        startPageFocused = false
        endPageFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func updatePreferences(for style: ReadingPreferences.PageCountingStyle) {
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

struct CustomRangeSectionView: View {
    @Binding var preferences: ReadingPreferences
    @FocusState var startPageFocused: Bool
    @FocusState var endPageFocused: Bool

    var body: some View {
        Group {
            if preferences.pageCountingStyle == .custom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Page Range")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Page")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                            TextField("Start", text: Binding(
                                get: { preferences.customStartPage.map(String.init) ?? "" },
                                set: { text in
                                    preferences.customStartPage = Int(text.filter { $0.isNumber }) ?? 1
                                }
                            ))
                            .font(.system(size: 16, weight: .medium))
                            .keyboardType(.numberPad)
                            .focused($startPageFocused)
                            .padding(12)
                            .background(Color.goodreadsBeige)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Page")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                            TextField("End", text: Binding(
                                get: { preferences.customEndPage.map(String.init) ?? "" },
                                set: { text in
                                    preferences.customEndPage = Int(text.filter { $0.isNumber }) ?? 1
                                }
                            ))
                            .font(.system(size: 16, weight: .medium))
                            .keyboardType(.numberPad)
                            .focused($endPageFocused)
                            .padding(12)
                            .background(Color.goodreadsBeige)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    Text("Effective pages: \(calculateEffectivePages(for: .custom))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                        .padding(.top, 4)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.goodreadsWarm))
                .transition(.opacity)
            }
        }
    }

    private func calculateEffectivePages(for style: ReadingPreferences.PageCountingStyle) -> Int {
        switch style {
        case .inclusive:
            return preferences.estimatedFrontMatterPages + preferences.estimatedBackMatterPages
        case .mainOnly:
            return preferences.estimatedFrontMatterPages + preferences.estimatedBackMatterPages
        case .custom:
            guard let start = preferences.customStartPage,
                  let end = preferences.customEndPage else {
                return preferences.estimatedFrontMatterPages + preferences.estimatedBackMatterPages
            }
            return max(0, end - start + 1)
        }
    }
}

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
