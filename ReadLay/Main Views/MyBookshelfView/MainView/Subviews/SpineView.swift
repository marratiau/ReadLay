//
//  SpineView 2.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct SpineView: View {
    let book: Book

    // ADDED: Dynamic width based on page count (like real books!)
    private var spineWidth: CGFloat {
        switch book.totalPages {
        case 0..<200:
            return 28 // Thin books
        case 200..<400:
            return 36 // Medium books
        case 400..<600:
            return 44 // Thick books
        default:
            return 50 // Very thick books
        }
    }

    // ADDED: Dynamic font size based on title length
    private var titleFontSize: CGFloat {
        let titleLength = book.title.count
        switch titleLength {
        case 0..<15:
            return 10 // Short titles
        case 15..<25:
            return 9 // Medium titles
        case 25..<35:
            return 8 // Long titles
        default:
            return 7 // Very long titles
        }
    }

    var body: some View {
        ZStack {
            // Main spine background - more rounded and minimalistic
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            book.spineColor.opacity(0.9),
                            book.spineColor.opacity(0.75),
                            book.spineColor.opacity(0.9)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: spineWidth, height: 155)

            // Title text
            Text(book.title)
                .font(.nunitoSemiBold(size: titleFontSize))
                .foregroundColor(.white)
                .lineLimit(5)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: spineWidth - 6)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
        }
        .frame(width: spineWidth, height: 155)
        .clipped()
    }
}
