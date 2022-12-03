//
//  BellsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/09/2022.
//

import SwiftUI

struct BellsView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState

    
    let bellPositions: [CGPoint]
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    
    var body: some View {
        ForEach(1...state.size, id: \.self) { bellNumber in
            if bellPositions.count == state.size {
                Button {
                    if state.bellMode == .ring {
                        viewModel.ringBell(number: bellNumber)
                    } else {
                        state.perspective = bellNumber
                        state.bellMode = .ring
                    }
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
                .buttonStyle(.bellTouchdown)
                .position(bellPositions[bellNumber - 1])
            }
        }
    }
    
    @ViewBuilder
    func ropeImage(number: Int) -> some View {
        Image(
            (state.bellType == .tower ? "t-" : "h-") +
            (state.bellStates[number - 1] == .hand ? number == 1 ? "handstroke-treble" : "handstroke" : "backstroke")
        )
        .resizable()
        .frame(width: imageWidth, height: imageHeight)
        .rotation3DEffect(
            .degrees((state.bellType == .tower) ? 0 : isLeft(number) ? 180 : 0),
            axis: (x: 0.0, y: 1.0, z: 0.0),
            anchor: .center,
            perspective: 1.0
        )
        
    }
    
    private func isLeft(_ num: Int) -> Bool {
        if state.perspective <= Int(state.size/2) {
            return num > state.perspective && num <= (state.perspective + Int(state.size/2))
        } else {
            return !(num > state.perspective + Int(state.size/2) && num <= state.perspective)
        }
    }
}
