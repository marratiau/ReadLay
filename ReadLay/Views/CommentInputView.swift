//
//  CommentInputView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/15/25.
//


import SwiftUI

struct CommentInputView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    @ObservedObject var readSlipViewModel: ReadSlipViewModel
    @State private var comment: String = ""
    let book: Book
    let onComplete: () -> Void
    
    private var isValidComment: Bool {
        return !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                headerSection
                commentInputSection
                buttonsSection
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.goodreadsWarm)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 30)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.goodreadsBrown)
            
            Text("What did you think?")
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
                
                if let session = sessionViewModel.currentSession {
                    HStack(spacing: 16) {
                        Text("\(session.pagesRead) pages read")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.goodreadsAccent.opacity(0.5))
                        
                        Text(session.formattedDuration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.goodreadsAccent.opacity(0.8))
                    }
                }
            }
            
            Text("Share one takeaway or thought from your reading session")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.goodreadsBrown.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.goodreadsBeige.opacity(0.7))
                )
        }
    }
    
    private var commentInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Takeaway")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.goodreadsBrown)
            
            TextEditor(text: $comment)
                .font(.system(size: 16))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.goodreadsBeige)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                        )
                )
                .frame(minHeight: 120)
            
            Text("Example: \"The author's point about daily habits really resonated with me...\"")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.goodreadsAccent.opacity(0.7))
                .italic()
        }
    }
    
    private var buttonsSection: some View {
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
            
            Button(action: saveComment) {
                Text("Save & Complete")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                isValidComment ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5)
                            )
                    )
            }
            .disabled(!isValidComment)
        }
    }
    
    private func saveComment() {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set the comment in the session
        sessionViewModel.setComment(trimmedComment)
        
        // Process the completed session
        if let session = sessionViewModel.currentSession {
            // Create a local reference to avoid the wrapper issue
            let viewModel = readSlipViewModel
            viewModel.processCompletedSession(session)
        }
        
        onComplete()
    }
}
