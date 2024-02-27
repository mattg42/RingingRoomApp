//
//  RingingButtonsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 20/08/2022.
//

import SwiftUI

enum Call {
    case bob, single, thatsAll, stand, go, lookTo
    
    var string: String {
        switch self {
        case .bob:
            return "Bob"
        case .single:
            return "Single"
        case .thatsAll:
            return "That's all"
        case .stand:
            return "Stand next"
        case .go:
            return "Go"
        case .lookTo:
            return "Look to"
        }
    }
    
    var display: String {
        if self == .stand {
            return "Stand"
        } else {
            return string
        }
    }
}
 
struct RingButton:View {
    let number: Int
    let height: CGFloat
    
    var body: some View {
        ZStack {
            Color(.ringingButtonBackground)
                .cornerRadius(5)
            Text(String(number))
                .foregroundColor(.primary)
                .font(.title3)
                .bold()
        }
        .frame(height: height)
    }
}

struct RingingButtonsView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    let wide: Bool

    var body: some View {
        if !wide {
            VStack(spacing: 5) {
                AssignedButtons(height: 70)
                
                HStack(spacing: 5) {
                    CallButton(call: .bob, height: 30)
                    CallButton(call: .single, height: 30)
                    CallButton(call: .thatsAll, height: 30)
                }
                
                HStack(spacing: 5) {
                    CallButton(call: .lookTo, height: 30)
                    CallButton(call: .go, height: 30)
                    CallButton(call: .stand, height: 30)
                }
            }
        } else {
            HStack(spacing: 5) {
                VStack(spacing: 5) {
                    CallButton(call: .bob, height: 45)
                    CallButton(call: .single, height: 45)
                    CallButton(call: .thatsAll, height: 45)
                }
                .frame(maxWidth: state.ringer != nil ? state.assignments.contains(viewModel.unwrappedRinger.ringerID) ? 150 : .infinity : .infinity)
                
                
                VStack(spacing: 5) {
                    CallButton(call: .lookTo, height: 45)
                    CallButton(call: .go, height: 45)
                    CallButton(call: .stand, height: 45)
                }
                .frame(maxWidth: state.ringer != nil ? state.assignments.contains(viewModel.unwrappedRinger.ringerID) ? 150 : .infinity : .infinity)

                AssignedButtons(height: 145)
            }
        }
    }
}

struct AssignedButtons: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    let height: CGFloat
    
    var body: some View {
        if state.ringer != nil {
            if state.assignments.contains(viewModel.unwrappedRinger.ringerID) {
                HStack(spacing: 5) {
                    ForEach(0..<state.size, id: \.self) { i in
                        if state.assignments[state.size - 1 - i] == viewModel.unwrappedRinger.ringerID {
                            Button {
                                viewModel.ringBell(number: state.size - i)
                            } label: {
                                RingButton(number: state.size - i, height: height)
                            }
                            .buttonStyle(.bellTouchdown)
                        }
                    }
                }
            }
        }
    }
}

struct CallButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    var call: Call
    let height: CGFloat
    
    var body: some View {
        Button {
            viewModel.send(.call(call.string))
        } label: {
            ZStack {
                Color(.ringingButtonBackground)
                    .cornerRadius(5)
                Text(call.display)
                    .foregroundColor(.primary)
                
            }
            .frame(height: height)
        }
        .buttonStyle(.callTouchdown)
        .disabled(state.hostMode && !viewModel.towerInfo.isHost && !state.assignments.contains(where: { $0 == viewModel.unwrappedRinger.ringerID }))
    }
}
