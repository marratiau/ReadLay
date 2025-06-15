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

    var body: some View {
        HStack(spacing: 12) {
            // Book cover - shows actual covers
            if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(0.65, contentMode: .fit)
                } placeholder: {
                    // Fallback while loading
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    book.spineColor.opacity(0.9),
                                    book.spineColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        )
                }
                .frame(width: 40, height: 60)
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            } else if let cover = book.coverImageName, let img = UIImage(named: cover) {
                // Local image fallback
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(0.65, contentMode: .fit)
                    .frame(width: 40, height: 60)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            } else {
                // Default placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                book.spineColor.opacity(0.9),
                                book.spineColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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

            // Book details - more compact
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
            
            Spacer()

            // Odds squares - REMOVED auto-close
            HStack(spacing: 8) {
                ForEach(book.odds, id: \.0) { label, odd in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedOdds = selectedOdds == odd ? nil : odd
                            // Add bet to readslip (NO auto-close)
                            readSlipViewModel.addBet(book: book, timeframe: label, odds: odd)
                        }
                    }) {
                        VStack(spacing: 3) {
                            Text(label)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.goodreadsAccent.opacity(0.7))
                                .textCase(.uppercase)
                            
                            Text(odd)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(selectedOdds == odd ? .white : .goodreadsBrown)
                        }
                        .frame(width: 48, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedOdds == odd ? Color.goodreadsBrown : Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedOdds == odd ? Color.clear : Color.goodreadsAccent.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .scaleEffect(selectedOdds == odd ? 1.05 : 1.0)
                }
            }

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.goodreadsAccent.opacity(0.6))
                    .background(Circle().fill(Color.goodreadsBeige))
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .frame(height: 72)
    }
}
