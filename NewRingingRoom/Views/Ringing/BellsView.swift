//
//  BellsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/09/2022.
//

import SwiftUI

struct BellsView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    let bellPositions: [CGPoint]
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    
    var body: some View {
        ForEach(1...viewModel.size, id: \.self) { bellNumber in
            if bellPositions.count == viewModel.size {
                Button {
                    viewModel.ringBell(number: bellNumber)
                } label: {
                    HStack {
                        if !isLeft(bellNumber) {
                            Text(String(bellNumber))
                                .font(.body)
                        }
                        ropeImage(number: bellNumber)
                        if isLeft(bellNumber) {
                            Text(String(bellNumber))
                                .font(.body)
                        }
                    }
                }
                .buttonStyle(.touchdown)
                .position(bellPositions[bellNumber - 1])
            }
        }
    }
    
    @ViewBuilder
    func ropeImage(number: Int) -> some View {
        Image(
            (viewModel.bellType == .tower ? "t-" : "h-") +
            (viewModel.bellStates[number - 1] == .hand ? number == 1 ? "handstroke-treble" : "handstroke" : "backstroke")
        )
        .resizable()
        .frame(width: imageWidth, height: imageHeight)
        .rotation3DEffect(
            .degrees((viewModel.bellType == .tower) ? 0 : isLeft(number) ? 180 : 0),
            axis: (x: 0.0, y: 1.0, z: 0.0),
            anchor: .center,
            perspective: 1.0
        )
        
    }
    
    private func isLeft(_ num: Int) -> Bool {
        if viewModel.perspective <= Int(viewModel.size/2) {
            return num > viewModel.perspective && num <= (viewModel.perspective + Int(viewModel.size/2))
        } else {
            return !(num > viewModel.perspective + Int(viewModel.size/2) && num <= viewModel.perspective)
        }
    }
}
