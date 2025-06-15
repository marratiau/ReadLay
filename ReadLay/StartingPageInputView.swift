//
//  StartingPageInputView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI

struct StartingPageInputView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    @State private var startingPageText: String = ""
    let book: Book
    let lastReadPage: Int
    let onStart: (Int) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 48))
                        .foregroundColor(.goodreadsBrown)
                    
                    Text("Ready to Read?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    
                    VStack(spacing: 8) {
                        Text(book.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.goodreadsBrown)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        if let author = book.author {
                            Text("by \(author)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                        }
                        
                        // ADDED: Show last read page
                        if lastReadPage > 1 {
                            Text("Last read: page \(lastReadPage)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.goodreadsAccent.opacity(0.8))
                                .padding(.top, 4)
                        }
                    }
                    
                    Text("What page are you starting on?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.goodreadsBrown)
                        .multilineTextAlignment(.center)
                }
                
                // Starting page input
                VStack(spacing: 12) {
                    TextField("Enter starting page", text: $startingPageText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.goodreadsBrown)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 2)
                                )
                        )
                    
                    // ADDED: Quick select for last read page
                    if lastReadPage > 1 {
                        Button(action: {
                            startingPageText = String(lastReadPage)
                        }) {
                            Text("Continue from page \(lastReadPage)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsBrown)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.goodreadsBeige.opacity(0.7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    Text("page number")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }
                .padding(.horizontal, 20)
                
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
                    
                    Button(action: {
                        if let page = Int(startingPageText), page > 0, page <= book.totalPages {
                            onStart(page)
                            sessionViewModel.setStartingPage(page)
                        }
                    }) {
                        Text("Start Reading")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        isValidInput ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5)
                                    )
                            )
                    }
                    .disabled(!isValidInput)
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.goodreadsWarm)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Pre-fill with last read page if available
            if lastReadPage > 1 {
                startingPageText = String(lastReadPage)
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let page = Int(startingPageText) else { return false }
        return page > 0 && page <= book.totalPages
    }
}
