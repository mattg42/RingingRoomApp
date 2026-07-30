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
    @State private var callTask: Task<Void, Never>?
    
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
            
            callTask?.cancel()
            callTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                withAnimation {
                    callTextOpacity = 0
                }
            }
            
        })
        .opacity(callTextOpacity)
        .fixedSize()
        .onDisappear {
            callTask?.cancel()
        }
    }
}
