//
//  FullScreenBettingView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct FullScreenBettingView: View {
    let book: Book
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    let onClose: () -> Void
    @State private var selectedReadingOdds: String?
    @State private var selectedJournalOdds: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Book header
                    bookHeader

                    // Reading Completion section
                    readingCompletionSection

                    // Journal Actions section
                    journalActionsSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(backgroundGradient)
            .navigationTitle("Place Your Bets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                    .foregroundColor(.goodreadsBrown)
                }
            }
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

    private var bookHeader: some View {
        HStack(spacing: 16) {
            bookCoverView
            bookInfoView
            Spacer()
        }
        .padding(20)
        .background(headerBackground)
    }

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
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            } else {
                defaultCoverView
            }
        }
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(book.spineColor.opacity(0.8))
            .overlay(
                ProgressView()
                    .tint(.white)
            )
    }

    private var defaultCoverView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(book.spineColor.opacity(0.8))
            .frame(width: 80, height: 120)
            .overlay(
                VStack {
                    Image(systemName: "book.closed.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.9))
                    Text(book.title.prefix(1))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }

    private var bookInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(book.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.goodreadsBrown)
                .lineLimit(3)

            if let author = book.author {
                Text("by \(author)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .lineLimit(2)
            }

            Text("\(book.totalPages) pages")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.8))
        }
    }

    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.goodreadsWarm)
            .shadow(color: .goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Reading Completion Section

    private var readingCompletionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            readingCompletionHeader
            readingOddsGrid
        }
        .padding(20)
        .background(sectionBackground)
    }

    private var readingCompletionHeader: some View {
        Text("Reading Completion")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.goodreadsBrown)
    }

    private var readingOddsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(book.odds, id: \.0) { label, odd in
                readingOddsButton(label: label, odd: odd)
            }
        }
    }

    private func readingOddsButton(label: String, odd: String) -> some View {
        let isSelected = selectedReadingOdds == odd

        return Button(action: {
            readingButtonAction(label: label, odd: odd)
        }) {
            readingButtonContent(label: label, odd: odd, isSelected: isSelected)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }

    private func readingButtonAction(label: String, odd: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedReadingOdds = selectedReadingOdds == odd ? nil : odd
            readSlipViewModel.addBet(book: book, timeframe: label, odds: odd)
        }
    }

    private func readingButtonContent(label: String, odd: String, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.goodreadsAccent.opacity(0.8))
                .textCase(.uppercase)

            Text(odd)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .goodreadsBrown)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(buttonBackground(isSelected: isSelected))
    }

    // MARK: - Journal Actions Section

    private var journalActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            journalActionsHeader
            journalOddsGrid
        }
        .padding(20)
        .background(sectionBackground)
    }

    private var journalActionsHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Journal Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.goodreadsBrown)

            Text("Bet on the number of takeaways you'll write")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsAccent)
        }
    }

    private var journalOddsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(book.journalOdds, id: \.0) { label, odd in
                journalOddsButton(label: label, odd: odd)
            }
        }
    }

    private func journalOddsButton(label: String, odd: String) -> some View {
        let isSelected = selectedJournalOdds == odd

        return Button(action: {
            journalButtonAction(label: label, odd: odd)
        }) {
            journalButtonContent(label: label, odd: odd, isSelected: isSelected)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }

    private func journalButtonAction(label: String, odd: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedJournalOdds = selectedJournalOdds == odd ? nil : odd
            // TODO: Add journal bet method to ReadSlipViewModel
            // Journal betting functionality not implemented in ViewModel yet
        }
    }

    private func journalButtonContent(label: String, odd: String, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.goodreadsAccent.opacity(0.8))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)

            Text(odd)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .goodreadsBrown)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(buttonBackground(isSelected: isSelected))
    }

    // MARK: - Shared Components

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }

    private func buttonBackground(isSelected: Bool) -> some View {
        let fillColor = isSelected ? Color.goodreadsBrown : Color.goodreadsBeige
        let strokeColor = isSelected ? Color.clear : Color.goodreadsAccent.opacity(0.3)

        return RoundedRectangle(cornerRadius: 12)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: 2)
            )
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.goodreadsWarm)
            .shadow(color: .goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
