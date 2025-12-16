//
//  LoadingView.swift
//  ReadLay
//
//  Loading screen shown during authentication state check
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.goodreadsBeige
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "book.pages")
                    .font(.system(size: 64))
                    .foregroundColor(.goodreadsBrown)

                Text("ReadLay")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.goodreadsBrown)

                ProgressView()
                    .tint(.goodreadsBrown)
                    .scaleEffect(1.2)
            }
        }
    }
}

#Preview {
    LoadingView()
}
