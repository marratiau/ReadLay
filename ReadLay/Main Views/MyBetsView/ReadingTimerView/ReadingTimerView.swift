//
//  ReadingTimerView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct ReadingTimerView: View {
    @ObservedObject var sessionViewModel: ReadingSessionViewModel
    let book: Book

    var body: some View {
        ZStack {
            Color.goodreadsBrown
                .ignoresSafeArea(.all)

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 12) {
                    Text("Reading")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.goodreadsBeige)

                    Text(book.title)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    if let author = book.author {
                        Text("by \(author)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.goodreadsBeige.opacity(0.8))
                    }

                    if let session = sessionViewModel.currentSession {
                        Text("Started on page \(session.startingPage)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.goodreadsBeige.opacity(0.7))
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 16) {
                    Text("Time Elapsed")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.goodreadsBeige.opacity(0.7))

                    // FIXED: Use displayTime instead of recalculating
                    Text(sessionViewModel.displayTime)
                        .font(.system(size: 72, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }

                Spacer()

                Button(action: {
                    sessionViewModel.stopReadingSession()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Stop Reading")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.goodreadsBrown)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.goodreadsBeige)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
}
