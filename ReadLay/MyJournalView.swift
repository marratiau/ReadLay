//
//  MyJournalView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

//import SwiftUI
//
//struct MyJournalView: View {
//    @ObservedObject var readSlipViewModel: ReadSlipViewModel
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                if readSlipViewModel.journalEntries.isEmpty {
//                    emptyState
//                } else {
//                    LazyVStack(spacing: 16) {
//                        ForEach(readSlipViewModel.journalEntries.reversed()) { entry in
//                            JournalEntryRowView(entry: entry)
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 16)
//                }
//            }
//            .background(backgroundGradient)
//            .navigationTitle("My Journal")
//            .navigationBarTitleDisplayMode(.large)
//        }
//    }
//    
//    private var emptyState: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            Image(systemName: "book.pages")
//                .font(.system(size: 64))
//                .foregroundColor(.goodreadsAccent.opacity(0.5))
//            
//            VStack(spacing: 8) {
//                Text("Your Reading Journal")
//                    .font(.system(size: 24, weight: .bold))
//                    .foregroundColor(.goodreadsBrown)
//                
//                Text("Your reading insights and takeaways will appear here")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.goodreadsAccent)
//                    .multilineTextAlignment(.center)
//            }
//            
//            Spacer()
//        }
//        .padding(.horizontal, 32)
//    }
//    
//    private var backgroundGradient: some View {
//        LinearGradient(
//            gradient: Gradient(colors: [
//                Color.goodreadsBeige,
//                Color.goodreadsWarm.opacity(0.5)
//            ]),
//            startPoint: .top,
//            endPoint: .bottom
//        )
//        .ignoresSafeArea()
//    }
//}
//
//struct JournalEntryRowView: View {
//    let entry: JournalEntry
//    @State private var isExpanded = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Header
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(entry.bookTitle)
//                        .font(.system(size: 16, weight: .bold))
//                        .foregroundColor(.goodreadsBrown)
//                        .lineLimit(2)
//                    
//                    if let author = entry.bookAuthor {
//                        Text("by \(author)")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(.goodreadsAccent)
//                    }
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .trailing, spacing: 2) {
//                    Text(entry.formattedDate)
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(.goodreadsAccent.opacity(0.8))
//                    
//                    Text("\(entry.takeaways.count) takeaway\(entry.takeaways.count > 1 ? "s" : "")")
//                        .font(.system(size: 11, weight: .medium))
//                        .foregroundColor(.goodreadsBrown)
//                }
//            }
//            
//            // Session info
//            HStack(spacing: 16) {
//                HStack(spacing: 4) {
//                    Image(systemName: "book.pages")
//                        .font(.system(size: 12))
//                        .foregroundColor(.goodreadsAccent)
//                    Text("\(entry.pagesRead) pages")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(.goodreadsAccent)
//                }
//                
//                HStack(spacing: 4) {
//                    Image(systemName: "clock")
//                        .font(.system(size: 12))
//                        .foregroundColor(.goodreadsAccent)
//                    Text(entry.formattedDuration)
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(.goodreadsAccent)
//                }
//                
//                HStack(spacing: 4) {
//                    Image(systemName: "bookmark")
//                        .font(.system(size: 12))
//                        .foregroundColor(.goodreadsAccent)
//                    Text("pp. \(entry.startingPage)-\(entry.endingPage)")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundColor(.goodreadsAccent)
//                }
//                
//                Spacer()
//            }
//            
//            // Takeaways preview/full
//            VStack(alignment: .leading, spacing: 8) {
//                if isExpanded {
//                    ForEach(Array(entry.takeaways.enumerated()), id: \.offset) { index, takeaway in
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Takeaway \(index + 1)")
//                                .font(.system(size: 12, weight: .semibold))
//                                .foregroundColor(.goodreadsAccent)
//                            
//                            Text(takeaway)
//                                .font(.system(size: 14, weight: .medium))
//                                .foregroundColor(.goodreadsBrown)
//                                .lineLimit(nil)
//                        }
//                        .padding(12)
//                        .background(
//                            RoundedRectangle(cornerRadius: 8)
//                                .fill(Color.goodreadsBeige.opacity(0.7))
//                        )
//                    }
//                } else {
//                    Text(entry.takeaways.first ?? "")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.goodreadsBrown)
//                        .lineLimit(3)
//                        .padding(12)
//                        .background(
//                            RoundedRectangle(cornerRadius: 8)
//                                .fill(Color.goodreadsBeige.opacity(0.7))
//                        )
//                }
//                
//                if entry.takeaways.count > 1 || (entry.takeaways.first?.count ?? 0) > 150 {
//                    Button(action: {
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            isExpanded.toggle()
//                        }
//                    }) {
//                        Text(isExpanded ? "Show less" : "Show more")
//                            .font(.system(size: 12, weight: .medium))
//                            .foregroundColor(.goodreadsBrown)
//                            .underline()
//                    }
//                }
//            }
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.goodreadsWarm)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
//                )
//                .shadow(color: Color.goodreadsBrown.opacity(0.1), radius: 4, x: 0, y: 2)
//        )
//    }
//}
