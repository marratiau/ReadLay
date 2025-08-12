//
//  CompactReadSlipView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct CompactReadSlipView: View {
    @ObservedObject var viewModel: ReadSlipViewModel

    var body: some View {
        HStack {
            // Expand arrow
            Button(action: {
                viewModel.toggleExpanded()
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.goodreadsBrown)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.goodreadsBeige)
                            .overlay(
                                Circle()
                                    .stroke(Color.goodreadsAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            Spacer()

            // ReadSlip title and count
            HStack(spacing: 8) {
                Text("ReadSlip")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.goodreadsBrown)

                // Bet count circle
                if viewModel.betSlip.totalBets > 0 {
                    Text("\(viewModel.betSlip.totalBets)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.goodreadsBrown)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.goodreadsWarm)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.goodreadsAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.goodreadsBrown.opacity(0.15), radius: 8, x: 0, y: -4)
        )
    }
}
