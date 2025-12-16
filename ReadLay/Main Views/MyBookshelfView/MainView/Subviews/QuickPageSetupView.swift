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
    @State private var showAllOptions = false

    // FIX: Add onSave callback as optional with default behavior
    var onSave: ((Book) -> Void)?

    init(book: Binding<Book>, onSave: ((Book) -> Void)? = nil) {
        self._book = book
        self._preferences = State(initialValue: book.wrappedValue.readingPreferences)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    selectedStyleCard

                    if showAllOptions {
                        quickOptionsSection
                    }

                    if preferences.pageCountingStyle == .custom {
                        customRangeSectionIfNeeded
                    }
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
                    .foregroundColor(.readlayTan)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .foregroundColor(.readlayDarkBrown)
                    .fontWeight(.semibold)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .font(.nunitoMedium(size: 16))
                    .foregroundColor(.readlayDarkBrown)
                }
            }
        }
        // FIX: Ensure proper presentation
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // FIX: Separate save logic with proper timing
    private func saveAndDismiss() {
        hideKeyboard()
        
        // Update the book's preferences
        book.readingPreferences = preferences
        
        // Save to persistent storage
        book.readingPreferences.save(for: book.id)
        
        // Clear cached values
        Book.invalidateCache(for: book.id)
        
        // Call the onSave callback if provided
        if let onSave = onSave {
            onSave(book)
        }
        
        // FIX: Delay dismiss slightly to avoid layout conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.readlayCream.opacity(0.3),
                Color.readlayPaleMint.opacity(0.5)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.pages")
                .font(.nunitoBold(size: 40))
                .foregroundColor(.readlayDarkBrown)

            Text("How do you want to read this book?")
                .font(.nunitoBold(size: 20))
                .foregroundColor(.readlayDarkBrown)
                .multilineTextAlignment(.center)

            Text(book.title)
                .font(.nunitoSemiBold(size: 16))
                .foregroundColor(.readlayTan)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(book.totalPages) total pages")
                .font(.nunitoMedium(size: 14))
                .foregroundColor(.readlayTan.opacity(0.8))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }

    private var selectedStyleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: preferences.pageCountingStyle.icon)
                    .font(.nunitoBold(size: 24))
                    .foregroundColor(.readlayMediumBlue)

                Text(preferences.pageCountingStyle.displayName)
                    .font(.nunitoBold(size: 18))
                    .foregroundColor(.readlayDarkBrown)

                Spacer()

                Button(showAllOptions ? "Hide" : "Change") {
                    withAnimation { showAllOptions.toggle() }
                }
                .font(.nunitoSemiBold(size: 14))
                .foregroundColor(.readlayLightBlue)
            }

            // Page info
            Text("Reading: Pages \(calculateStartPage(for: preferences.pageCountingStyle))-\(calculateEndPage(for: preferences.pageCountingStyle))")
                .font(.nunitoMedium(size: 14))
                .foregroundColor(.readlayTan)

            Text("\(calculateEffectivePages(for: preferences.pageCountingStyle)) pages total")
                .font(.nunitoBold(size: 16))
                .foregroundColor(.readlayDarkBrown)

            // Chapter info (if available)
            if book.hasChapters {
                Divider()
                    .background(Color.readlayTan.opacity(0.3))

                Text("Chapters: \(book.readingStartChapter)-\(book.readingEndChapter)")
                    .font(.nunitoMedium(size: 14))
                    .foregroundColor(.readlayTan)

                Text("\(book.effectiveTotalChapters) chapters total")
                    .font(.nunitoBold(size: 16))
                    .foregroundColor(.readlayDarkBrown)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.readlayPaleMint)
                .shadow(color: .readlayDarkBrown.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Options")
                .font(.nunitoBold(size: 18))
                .foregroundColor(.readlayDarkBrown)

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
                .font(.nunitoBold(size: 18))
                .foregroundColor(.readlayDarkBrown)

            HStack {
                Text("Effective Pages:")
                    .font(.nunitoMedium(size: 14))
                    .foregroundColor(.readlayTan)

                Spacer()

                Text("\(calculateEffectivePages(for: preferences.pageCountingStyle))")
                    .font(.nunitoBold(size: 16))
                    .foregroundColor(.readlayDarkBrown)
            }

            HStack {
                Text("Page Range:")
                    .font(.nunitoMedium(size: 14))
                    .foregroundColor(.readlayTan)

                Spacer()

                Text("\(calculateStartPage(for: preferences.pageCountingStyle)) - \(calculateEndPage(for: preferences.pageCountingStyle))")
                    .font(.nunitoBold(size: 16))
                    .foregroundColor(.readlayDarkBrown)
            }
        }
        .padding(20)
        .background(sectionBackground)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.readlayPaleMint)
            .shadow(color: .readlayDarkBrown.opacity(0.1), radius: 4, x: 0, y: 2)
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

// MARK: - Custom Range Section View
struct CustomRangeSectionView: View {
    @Binding var preferences: ReadingPreferences
    @FocusState var startPageFocused: Bool
    @FocusState var endPageFocused: Bool

    var body: some View {
        Group {
            if preferences.pageCountingStyle == .custom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Page Range")
                        .font(.nunitoBold(size: 18))
                        .foregroundColor(.readlayDarkBrown)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Page")
                                .font(.nunitoMedium(size: 14))
                                .foregroundColor(.readlayTan)

                            TextField("Start", text: Binding(
                                get: { preferences.customStartPage.map(String.init) ?? "" },
                                set: { text in
                                    preferences.customStartPage = Int(text.filter { $0.isNumber }) ?? 1
                                }
                            ))
                            .font(.nunitoMedium(size: 16))
                            .keyboardType(.numberPad)
                            .focused($startPageFocused)
                            .padding(12)
                            .background(Color.readlayCream)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.readlayTan.opacity(0.3), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("End Page")
                                .font(.nunitoMedium(size: 14))
                                .foregroundColor(.readlayTan)

                            TextField("End", text: Binding(
                                get: { preferences.customEndPage.map(String.init) ?? "" },
                                set: { text in
                                    preferences.customEndPage = Int(text.filter { $0.isNumber }) ?? 1
                                }
                            ))
                            .font(.nunitoMedium(size: 16))
                            .keyboardType(.numberPad)
                            .focused($endPageFocused)
                            .padding(12)
                            .background(Color.readlayCream)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.readlayTan.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }

                    Text("Effective pages: \(calculateEffectivePages(for: .custom))")
                        .font(.nunitoMedium(size: 12))
                        .foregroundColor(.readlayTan.opacity(0.8))
                        .padding(.top, 4)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.readlayPaleMint))
                .transition(.opacity)
            } else {
                EmptyView()
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
                    .font(.nunitoBold(size: 20))
                    .foregroundColor(isSelected ? .white : .readlayDarkBrown)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.displayName)
                        .font(.nunitoSemiBold(size: 16))
                        .foregroundColor(isSelected ? .white : .readlayDarkBrown)

                    Text(style.description)
                        .font(.nunitoMedium(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .readlayTan)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(effectivePages)")
                        .font(.nunitoBold(size: 20))
                        .foregroundColor(isSelected ? .white : .readlayDarkBrown)

                    Text("pages")
                        .font(.nunitoMedium(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .readlayTan)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.nunitoBold(size: 20))
                    .foregroundColor(isSelected ? .white : .readlayTan.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.readlayDarkBrown : Color.readlayPaleMint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color.readlayTan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
