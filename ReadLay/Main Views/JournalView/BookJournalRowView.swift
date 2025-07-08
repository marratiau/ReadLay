//
//  BookJournalRowView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/8/25.
//
import SwiftUI

// MARK: - Book Journal Row View (NEW VIEW)
struct BookJournalRowView: View {
    let bookSummary: BookJournalSummary
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Book icon
                VStack {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.goodreadsBrown)
                        .frame(width: 60, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Book details
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookSummary.bookTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.goodreadsBrown)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if let author = bookSummary.bookAuthor {
                            Text("by \(author)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                                .lineLimit(1)
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 16) {
                        statItem(
                            icon: "clock.fill",
                            value: bookSummary.formattedTotalTime,
                            label: "Total Time"
                        )
                        
                        statItem(
                            icon: "doc.text.fill",
                            value: "\(bookSummary.totalPages)",
                            label: "Pages Read"
                        )
                        
                        statItem(
                            icon: "book.pages.fill",
                            value: "\(bookSummary.totalSessions)",
                            label: "Sessions"
                        )
                    }
                    
                    Text("Last read \(bookSummary.formattedLastSession)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.goodreadsAccent.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.goodreadsAccent.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.goodreadsWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.goodreadsAccent)
                
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
            }
            
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.8))
        }
    }
}


