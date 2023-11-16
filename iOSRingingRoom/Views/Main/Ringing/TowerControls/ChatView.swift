//
//  ChatView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState

    @State private var currentMessage = ""

    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(spacing: 0) {
                    ScrollView {
                        ScrollViewReader { value in
                            VStack(spacing: 5) {
                                if state.messages.count > 0 {
                                    ForEach(0..<state.messages.count, id: \.self) { i in
                                        HStack {
                                            (Text(state.messages[i].sender).bold() + Text(": \(state.messages[i].message)"))
                                                .id(i)
                                            Spacer()
                                        }
                                    }
                                    .onAppear {
                                        value.scrollTo(state.messages.count - 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 5)
            
            HStack(alignment: .center) {
                TextField("Message", text: $currentMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
                    .focused($focused)
                
                Button("Send") {
                    sendMessage()
                }
                .foregroundColor(Color.main)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .onAppear {
            state.newMessages = 0
            viewModel.canSeeMessages = true
        }
        .onDisappear {
            hideKeyboard()
            viewModel.canSeeMessages = false
        }
    }
    
    func sendMessage() {
        let formatter = ISO8601DateFormatter()
        let time = formatter.string(from: Date.now)
        viewModel.send(.messageSent(message: currentMessage, time: time))
        currentMessage = ""
    }
}
