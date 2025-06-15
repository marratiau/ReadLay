//
//  JournalEntryInputView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


//import SwiftUI
//
//struct JournalEntryInputView: View {
//    @ObservedObject var sessionViewModel: ReadingSessionViewModel
//    @ObservedObject var readSlipViewModel: ReadSlipViewModel
//    @State private var takeaways: [String] = [""]
//    let book: Book
//    let sessionDuration: TimeInterval
//    let pagesRead: Int
//    let startingPage: Int
//    let endingPage: Int
//    let onComplete: () -> Void
//    
//    private var requiredTakeaways: Int {
//        // Check if there's a journal bet for this book
//        let journalBet = readSlipViewModel.placedJournalBets.first { $0.book.id == book.id }
//        return journalBet?.takeawayCount ?? 0
//    }
//    
//    private var hasEnoughTakeaways: Bool {
//        let validTakeaways = takeaways.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//        return validTakeaways.count >= requiredTakeaways
//    }
//    
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.5)
//                .ignoresSafeArea()
//            
//            ScrollView {
//                VStack(spacing: 24) {
//                    headerSection
//                    takeawaysSection
//                    buttonsSection
//                }
//                .padding(24)
//            }
//            .background(
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(Color.goodreadsWarm)
//                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
//            )
//            .padding(.horizontal, 20)
//        }
//    }
//    
//    private var headerSection: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "book.pages.fill")
//                .font(.system(size: 48))
//                .foregroundColor(.goodreadsBrown)
//            
//            Text("Journal Entry")
//                .font(.system(size: 24, weight: .bold))
//                .foregroundColor(.goodreadsBrown)
//            
//            VStack(spacing: 8) {
//                Text(book.title)
//                    .font(.system(size: 18, weight: .semibold))
//                    .foregroundColor(.goodreadsBrown)
//                    .multilineTextAlignment(.center)
//                
//                if let author = book.author {
//                    Text("by \(author)")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.goodreadsAccent)
//                }
//                
//                HStack(spacing: 16) {
//                    Text("\(pagesRead) pages read")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(.goodreadsAccent.opacity(0.8))
//                    
//                    Text("•")
//                        .foregroundColor(.goodreadsAccent.opacity(0.5))
//                    
//                    Text(formattedDuration)
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(.goodreadsAccent.opacity(0.8))
//                }
//            }
//            
//            if requiredTakeaways > 0 {
//                Text("Write at least \(requiredTakeaways) takeaway\(requiredTakeaways > 1 ? "s" : "") for your bet")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.goodreadsBrown)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//                    .padding(.vertical, 8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 8)
//                            .fill(Color.goodreadsBeige.opacity(0.7))
//                    )
//            }
//        }
//    }
//    
//    private var takeawaysSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Your Takeaways")
//                .font(.system(size: 16, weight: .semibold))
//                .foregroundColor(.goodreadsBrown)
//            
//            ForEach(takeaways.indices, id: \.self) { index in
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack {
//                        Text("Takeaway \(index + 1)")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.goodreadsAccent)
//                        
//                        Spacer()
//                        
//                        if index > 0 || takeaways.count > 1 {
//                            Button(action: {
//                                if takeaways.count > 1 {
//                                    takeaways.remove(at: index)
//                                }
//                            }) {
//                                Image(systemName: "minus.circle.fill")
//                                    .font(.system(size: 20))
//                                    .foregroundColor(.red.opacity(0.7))
//                            }
//                        }
//                    }
//                    
//                    TextEditor(text: $takeaways[index])
//                        .font(.system(size: 14))
//                        .padding(12)
//                        .background(
//                            RoundedRectangle(cornerRadius: 8)
//                                .fill(Color.goodreadsBeige)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
//                                )
//                        )
//                        .frame(minHeight: 80)
//                }
//            }
//            
//            Button(action: {
//                takeaways.append("")
//            }) {
//                HStack(spacing: 8) {
//                    Image(systemName: "plus.circle")
//                        .font(.system(size: 16))
//                    Text("Add Another Takeaway")
//                        .font(.system(size: 14, weight: .medium))
//                }
//                .foregroundColor(.goodreadsBrown)
//                .padding(.vertical, 8)
//            }
//        }
//    }
//    
//    private var buttonsSection: some View {
//        HStack(spacing: 16) {
//            Button(action: {
//                onComplete()
//                sessionViewModel.cancelSession()
//            }) {
//                Text("Skip Journal")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.goodreadsAccent)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 48)
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color.goodreadsBeige)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
//                            )
//                    )
//            }
//            
//            Button(action: saveJournalEntry) {
//                Text("Save Entry")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 48)
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(
//                                hasEnoughTakeaways ? Color.goodreadsBrown : Color.goodreadsAccent.opacity(0.5)
//                            )
//                    )
//            }
//            .disabled(!hasEnoughTakeaways)
//        }
//    }
//    
//    private var formattedDuration: String {
//        let hours = Int(sessionDuration) / 3600
//        let minutes = Int(sessionDuration) % 3600 / 60
//        
//        if hours > 0 {
//            return "\(hours)h \(minutes)m"
//        } else {
//            return "\(minutes)m"
//        }
//    }
//    
//    private func saveJournalEntry() {
//        let validTakeaways = takeaways.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//        
//        let entry = JournalEntry(
//            id: UUID(),
//            bookId: book.id,
//            bookTitle: book.title,
//            bookAuthor: book.author,
//            date: Date(),
//            takeaways: validTakeaways,
//            sessionDuration: sessionDuration,
//            pagesRead: pagesRead,
//            startingPage: startingPage,
//            endingPage: endingPage
//        )
//        
//        readSlipViewModel.addJournalEntry(entry)
//        onComplete()
//        sessionViewModel.cancelSession()
//    }
//}
