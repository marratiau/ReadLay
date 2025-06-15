//
//  PageInputView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI

struct EndingPageInputView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    @State private var endingPageText: String = ""
    let book: Book
    let onComplete: (Int) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Reading Session Complete!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.goodreadsBrown)
                    
                    if let session = sessionViewModel.currentSession {
                        VStack(spacing: 8) {
                            Text("Time: \(session.formattedDuration)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.goodreadsAccent)
                            
                            Text("Started on page \(session.startingPage)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.goodreadsAccent.opacity(0.8))
                        }
                    }
                    
                    Text("What page did you end on?")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.goodreadsBrown)
                        .multilineTextAlignment(.center)
                }
                
                // Ending page input
                VStack(spacing: 8) {
                    TextField("Enter ending page", text: $endingPageText)
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
                    
                    VStack(spacing: 4) {
                        Text("page number")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.goodreadsAccent)
                        
                        if let session = sessionViewModel.currentSession,
                           let endingPage = Int(endingPageText),
                           endingPage > session.startingPage {
                            let pagesRead = endingPage - session.startingPage
                            Text("= \(pagesRead) pages read")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
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
                        if let endingPage = Int(endingPageText) {
                            onComplete(endingPage)
                            sessionViewModel.setEndingPage(endingPage)
                        }
                    }) {
                        Text("Done")
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
    }
    
    private var isValidInput: Bool {
        guard let session = sessionViewModel.currentSession,
              let endingPage = Int(endingPageText) else { return false }
        return endingPage > session.startingPage && endingPage <= book.totalPages
    }
}
