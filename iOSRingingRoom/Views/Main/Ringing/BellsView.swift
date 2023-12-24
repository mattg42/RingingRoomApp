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
    
    var imagePrefix: String {
        switch state.bellType {
        case .tower: "t-"
        case .hand: "h-"
        case .cowbell: "c-"
        }
    }
    
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
                .disabled(state.hostMode && !viewModel.towerInfo.isHost && state.assignments[safe: bellNumber - 1] ?? 0 != viewModel.unwrappedRinger.ringerID)
            }
        }
    }
    
    @ViewBuilder
    func ropeImage(number: Int) -> some View {
        Image(
            (imagePrefix) +
            (state.bellStates[number - 1] == .hand ? "handstroke" : "backstroke") +
            (number == 1 ? "-treble" : "")
        )
        .resizable()
        .frame(width: imageWidth, height: imageHeight)
        .rotation3DEffect(
            .degrees((state.bellType == .hand) ? isLeft(number) ? 180 : 0 : 0),
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

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
