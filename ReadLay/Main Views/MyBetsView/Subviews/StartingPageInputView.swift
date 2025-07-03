//
//  StartingPageInputView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI

struct StartingPageInputView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
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
                    
                    Text("Ready to Continue Reading?")
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
                        
                        // Show last read page
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
                    TextField("Enter starting page", text: $sessionViewModel.startingPageText)
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
                                        .stroke(
                                            sessionViewModel.validationError != nil ?
                                                Color.red.opacity(0.6) :
                                                Color.goodreadsAccent.opacity(0.3),
                                            lineWidth: 2
                                        )
                                )
                        )
                        .onChange(of: sessionViewModel.startingPageText) { newValue in
                            sessionViewModel.setStartingPageText(newValue)
                        }
                    
                    // Error message
                    if let error = sessionViewModel.validationError {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.2), value: sessionViewModel.validationError)
                    }
                    
                    // Quick select for last read page
                    if lastReadPage > 1 {
                        Button(action: {
                            sessionViewModel.setStartingPageText(String(lastReadPage))
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
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.2), value: lastReadPage)
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
                        sessionViewModel.startReading()
                        if sessionViewModel.validationError == nil,
                           let page = Int(sessionViewModel.startingPageText) {
                            onStart(page)
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
                                        sessionViewModel.isValidStartingInput ?
                                            Color.goodreadsBrown :
                                            Color.goodreadsAccent.opacity(0.5)
                                    )
                            )
                    }
                    .disabled(!sessionViewModel.isValidStartingInput)
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
            // ViewModel handles pre-filling with last read page
            // No need to set it here since it's already done in startReadingSession
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
}

