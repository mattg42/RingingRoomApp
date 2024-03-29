//
//  CallView.swift
//  NewRingingRoom
//
//  Created by Matthew on 10/09/2022.
//

import SwiftUI

struct CallView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    @State private var callTextOpacity = 0.0
    @State private var callText = ""
    @State private var callTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            Color(.ringingRoomBackground)
                .cornerRadius(15)
                .blur(radius: 15, opaque: false)
                .shadow(color: Color(.ringingRoomBackground), radius: 10, x: 0.0, y: 0.0)
                .opacity(0.9)
            
            Text(callText)
                .font(.largeTitle)
                .bold()
                .padding()
        }
        .onReceive(viewModel.callPublisher, perform: { call in
            callTextOpacity = 1
            callText = call
            
            if let callTimer {
                callTimer.invalidate()
            }
            
            callTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
                withAnimation {
                    callTextOpacity = 0
                }
            })
            
        })
        .opacity(callTextOpacity)
        .fixedSize()
    }
}
