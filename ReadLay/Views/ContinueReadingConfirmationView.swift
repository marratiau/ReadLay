//
//  ContinueReadingConfirmationView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//


import SwiftUI

struct ContinueReadingConfirmationView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    let book: Book
    let nextPage: Int
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Book info
                VStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 40))
                        .foregroundColor(.goodreadsBrown)
                    
                    Text("Continue Reading?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    
                    Text(book.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.goodreadsBrown)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if let author = book.author {
                        Text("by \(author)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                    }
                }
                
                // Next page indicator
                VStack(spacing: 8) {
                    if nextPage == 1 {
                        Text("Start from the beginning")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.goodreadsBrown)
                    } else {
                        Text("Continue from page \(nextPage)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.goodreadsBrown)
                        
                        Text("Last read: page \(nextPage - 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.goodreadsBeige.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        sessionViewModel.cancelSession()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.goodreadsAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.goodreadsBeige)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // CHANGED: Reordered to call sessionViewModel.confirmStartingPage first, then onConfirm
                    Button(action: {
                        sessionViewModel.confirmStartingPage(nextPage)
                        onConfirm()
                    }) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.goodreadsBrown)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.goodreadsWarm)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 60)
        }
    }
}
