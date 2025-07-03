//
//  EndingPageInputView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 7/2/25.
//


import SwiftUI

struct EndingPageInputView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    let book: Book
    let onComplete: (Int) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                headerSection
                pageInputSection
                buttonSection
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
            // Pre-fill ending page with starting page as default
            if let session = sessionViewModel.currentSession, session.startingPage > 0 {
                sessionViewModel.setEndingPageText(String(session.startingPage))
            }
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
    
    // MARK: - Extracted Components (Better MVVM)
    private var headerSection: some View {
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
    }
    
    private var pageInputSection: some View {
        VStack(spacing: 12) {
            TextField("Enter ending page", text: $sessionViewModel.endingPageText)
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
                .onChange(of: sessionViewModel.endingPageText) { newValue in
                    sessionViewModel.setEndingPageText(newValue)
                }
            
            // ADDED: Error message display
            if let error = sessionViewModel.validationError {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: sessionViewModel.validationError)
            }
            
            VStack(spacing: 4) {
                Text("page number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                
                // MOVED: Business logic to ViewModel
                if let session = sessionViewModel.currentSession,
                   let endingPage = Int(sessionViewModel.endingPageText),
                   sessionViewModel.isValidEndingInput {
                    let pagesRead = endingPage - session.startingPage + 1 // FIXED: Correct page counting
                    Text("= \(pagesRead) pages read")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var buttonSection: some View {
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
                // IMPROVED: Use ViewModel's validation logic
                sessionViewModel.finishReading()
                if sessionViewModel.validationError == nil,
                   let endingPage = Int(sessionViewModel.endingPageText) {
                    onComplete(endingPage)
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
                                sessionViewModel.isValidEndingInput ?
                                    Color.goodreadsBrown :
                                    Color.goodreadsAccent.opacity(0.5)
                            )
                    )
            }
            .disabled(!sessionViewModel.isValidEndingInput)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Keyboard Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}