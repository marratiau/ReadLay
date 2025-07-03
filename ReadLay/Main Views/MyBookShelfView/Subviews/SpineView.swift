//
//  SpineView 2.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct SpineView: View {
    let book: Book
    
    var body: some View {
        ZStack {
            // Main spine background
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            book.spineColor.opacity(0.95),
                            book.spineColor.opacity(0.8),
                            book.spineColor.opacity(0.95)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 28, height: 155) // REDUCED: Even narrower for closer spacing
                .overlay(
                    // Spine highlight
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear,
                                    Color.black.opacity(0.15)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    // Left edge highlight (REMOVED separator-like elements)
                    Rectangle()
                        .fill(Color.white.opacity(0.3)) // REDUCED: Less prominent
                        .frame(width: 1)
                        .offset(x: -12.5), // ADJUSTED: Updated offset
                    alignment: .leading
                )
            
            // Title text
            Text(book.title)
                .font(.system(size: 9, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .rotationEffect(.degrees(-90))
                .frame(width: 120)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
        }
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0.5, y: 1) // REDUCED: Subtler shadow
    }
}
