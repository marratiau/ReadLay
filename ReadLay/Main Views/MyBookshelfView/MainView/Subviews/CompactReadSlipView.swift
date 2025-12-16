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
            HStack(spacing: 8) {

                // Bet count circle
                if viewModel.betSlip.totalBets > 0 {
                    Text("\(viewModel.betSlip.totalBets)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.readlayDarkBrown)
                        )
                }

                // ReadSlip title
                Text("ReadSlip")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.readlayDarkBrown)

            }

            Spacer()

            // Expand arrow
            Button(action: {
                viewModel.toggleExpanded()
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.readlayDarkBrown)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(Color.readlayCream.opacity(0.3))
                            .overlay(
                                Circle()
                                    .stroke(Color.readlayTan.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.readlayTan.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.readlayDarkBrown.opacity(0.1), radius: 8, x: 0, y: -4)
        )
    }
}
