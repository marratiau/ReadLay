//
//  ReadSlipView.swift
//  ReadLay
//
//  Created by Mateo Arratia on 6/4/25.
//

import SwiftUI

struct ReadSlipView: View {
    @ObservedObject var viewModel: ReadSlipViewModel

    var body: some View {
        VStack {
            if viewModel.betSlip.totalBets > 0 {
                if viewModel.betSlip.isExpanded {
                    ExpandedReadSlipView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    CompactReadSlipView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}
