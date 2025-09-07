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
            return 24 // Thin books
        case 200..<400:
            return 30 // Medium books
        case 400..<600:
            return 36 // Thick books
        default:
            return 42 // Very thick books
        }
    }

    // ADDED: Dynamic font size based on title length
    private var titleFontSize: CGFloat {
        let titleLength = book.title.count
        switch titleLength {
        case 0..<15:
            return 9 // Short titles
        case 15..<25:
            return 8 // Medium titles
        case 25..<35:
            return 7 // Long titles
        default:
            return 6 // Very long titles
        }
    }

    var body: some View {
        ZStack {
            // Main spine background
            RoundedRectangle(cornerRadius: 3)
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
                .frame(width: spineWidth, height: 155) // DYNAMIC: Width varies, height fixed

            // Title text - IMPROVED: Better scaling for long titles
            Text(book.title)
                .font(.system(size: titleFontSize, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(5) // INCREASED: More lines for very long titles
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5) // INCREASED: Can shrink up to 50%
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: spineWidth - 4) // CONSTRAINED: Height matches spine width
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .frame(width: spineWidth, height: 155) // ENFORCED: Exact dimensions
        .clipped() // CRITICAL: Prevents any overflow that could change height
    }
}
