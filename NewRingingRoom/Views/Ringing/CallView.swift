//
//  CallView.swift
//  NewRingingRoom
//
//  Created by Matthew on 10/09/2022.
//

import SwiftUI

struct CallView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    @State var callTextOpacity = 0.0
    @State var callText = ""
    @State var callTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            Color("ringingBackground")
                .cornerRadius(15)
                .blur(radius: 15, opaque: false)
                .shadow(color: Color("ringingBackground"), radius: 10, x: 0.0, y: 0.0)
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
                ThreadUtil.runInMain {
                    withAnimation {
                        callTextOpacity = 0
                    }
                }
            })
            
        })
        .opacity(callTextOpacity)
        .fixedSize()
    }
}
