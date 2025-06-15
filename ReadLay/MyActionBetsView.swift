//
//  MyActionBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI

struct MyActionBetsView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "bolt.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.goodreadsAccent.opacity(0.5))
                Text("Action Bets")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.goodreadsBrown)
                Text("Live reading challenges and competitions will appear here")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.goodreadsBeige,
                    Color.goodreadsWarm.opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    MyActionBetsView()
}
