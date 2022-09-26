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
            return self.string
        }
    }
}

struct RingButton:View {
    var number: Int
    
    var body: some View {
        ZStack {
            Color("ringingButtonBackground")
                .cornerRadius(5)
            Text(String(number))
                .foregroundColor(.primary)
                .font(.title3)
                .bold()
        }
        .frame(height: 70)
    }
}

struct RingingButtonsView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel

    var body: some View {
        VStack(spacing: 5) {
            if viewModel.assignments.contains(viewModel.ringer!.ringerID) {
                HStack(spacing: 5) {
                    ForEach(0..<viewModel.size, id: \.self) { i in
                        if viewModel.assignments[viewModel.size - 1 - i] == viewModel.ringer!.ringerID {
                            Button {
                                viewModel.ringBell(number: viewModel.size - i)
                            } label: {
                                RingButton(number: viewModel.size - i)
                            }
                            .buttonStyle(.bellTouchdown)
                        }
                    }
                }
            }
            
            HStack(spacing: 5) {
                CallButton(call: .bob)
                CallButton(call: .single)
                CallButton(call: .thatsAll)
            }
            
            HStack(spacing: 5) {
                CallButton(call: .lookTo)
                CallButton(call: .go)
                CallButton(call: .stand)
            }
        }
    }
}

struct CallButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
        
    var call: Call
    
    var body: some View {
        Button {
            viewModel.makeCall(call)
        } label: {
            ZStack {
                Color("ringingButtonBackground")
                    .cornerRadius(5)
                Text(call.display)
                    .foregroundColor(.primary)
                
            }
            .frame(height: 30)
        }
        .buttonStyle(.callTouchdown)
    }
}

struct RingingButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        RingingButtonsView()
    }
}
