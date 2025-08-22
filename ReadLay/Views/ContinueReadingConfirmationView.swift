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
    let nextPage: Int  // This is the suggested next page (lastReadPage + 1)
    let onConfirm: () -> Void
    
    @State private var pageText: String = ""
    @State private var showError: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    // The actual last read page (one before nextPage)
    private var lastReadPage: Int {
        return max(nextPage - 1, book.readingStartPage)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isTextFieldFocused = false
                }

            VStack(spacing: 20) {
                // Book info
                VStack(spacing: 12) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.goodreadsBrown)

                    Text("Continue Reading")
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

                // Progress info
                VStack(spacing: 8) {
                    Text("You last read up to page \(lastReadPage)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.goodreadsBrown)
                    
                    Text("What page will you start from?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.goodreadsAccent)
                }

                // Page input field
                VStack(spacing: 8) {
                    TextField("Page \(nextPage)", text: $pageText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.goodreadsBrown)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($isTextFieldFocused)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.goodreadsBeige)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            showError ? Color.red.opacity(0.6) :
                                            isTextFieldFocused ? Color.goodreadsBrown.opacity(0.7) :
                                            Color.goodreadsAccent.opacity(0.3),
                                            lineWidth: isTextFieldFocused ? 2 : 1
                                        )
                                )
                        )
                        .onChange(of: pageText) { _ in
                            showError = false
                        }
                    
                    if showError {
                        Text("Page must be between \(book.readingStartPage) and \(book.readingEndPage)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)

                // Quick select buttons
                HStack(spacing: 12) {
                    Button(action: {
                        pageText = String(nextPage)
                        isTextFieldFocused = false
                    }) {
                        Text("Next page (\(nextPage))")
                            .font(.system(size: 13, weight: .medium))
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
                    
                    Button(action: {
                        pageText = String(lastReadPage)
                        isTextFieldFocused = false
                    }) {
                        Text("Same page (\(lastReadPage))")
                            .font(.system(size: 13, weight: .medium))
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

                // Action buttons
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

                    Button(action: confirmAndStart) {
                        Text("Start Reading")
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
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Pre-fill with suggested next page
            pageText = String(nextPage)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTextFieldFocused = false
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.goodreadsBrown)
            }
        }
    }
    
    private func confirmAndStart() {
        let page: Int
        
        if pageText.isEmpty {
            // Use suggested page if empty
            page = nextPage
        } else if let inputPage = Int(pageText) {
            // Validate the input
            if inputPage < book.readingStartPage || inputPage > book.readingEndPage {
                showError = true
                return
            }
            page = inputPage
        } else {
            showError = true
            return
        }
        
        // Hide keyboard
        isTextFieldFocused = false
        
        // Instead of calling confirmStartingPage (which expects the view model flow),
        // we use the direct method since we're bypassing the normal flow
        if let betId = sessionViewModel.currentSession?.betId {
            sessionViewModel.startReadingSessionDirect(
                for: betId,
                book: book,
                startingPage: page
            )
        }
        
        onConfirm()
    }
}
