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
    @State private var currentTime: Date = .now

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            tabSelectorSection

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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveBets"))) { _ in
            DispatchQueue.main.async {
                selectedTab = 1
            }
        }
        // FIXED: Only update when app becomes active, not every 60 seconds
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            currentTime = Date()
        }
    }

    private var tabSelectorSection: some View {
        VStack(spacing: 0) {
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

            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    VStack {
                        if selectedTab == index {
                            Rectangle()
                                .fill(Color.goodreadsBrown)
                                .frame(width: CGFloat(tabs[index].count * 8), height: 3)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("My Bets")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.readlayDarkBrown)

                Text("Track your reading progress")
                    .font(.nunitoMedium(size: 14))
                    .foregroundColor(.readlayTan)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)

                Text(formattedTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.goodreadsAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: currentTime)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }
}


