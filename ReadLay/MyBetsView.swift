//
//  MyBetsView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//


import SwiftUI

struct MyBetsView: View {
    @State private var selectedTab = 0
    private let tabs = ["DAILY", "ACTIVE", "SETTLED"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("My Bets")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.goodreadsBrown)
                
                Text("Track your reading progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            
            // Tab selector
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedTab == index ? .goodreadsBrown : .goodreadsAccent.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .background(Color.goodreadsBeige.opacity(0.5))
            .overlay(
                // Active tab indicator
                Rectangle()
                    .fill(Color.goodreadsBrown)
                    .frame(height: 3)
                    .offset(x: CGFloat(selectedTab) * (UIScreen.main.bounds.width / 3) - UIScreen.main.bounds.width/3, y: 0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab),
                alignment: .bottom
            )
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                DailyBetsView()
                    .tag(0)
                
                ActiveBetsView()
                    .tag(1)
                
                SettledBetsView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
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