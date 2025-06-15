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
                .frame(width: 32, height: 155)
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
                    // Left edge highlight
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1.5)
                        .offset(x: -14.5),
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
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 2)
    }
}
