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

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(.ringingButtonBackground)
                    .cornerRadius(10)
                
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
                .padding()
            }
            .padding(.bottom)
            
            HStack(alignment: .center) {
                TextField("Message", text: $currentMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
                
                Button("Send") {
                    sendMessage()
                }
                .foregroundColor(Color.main)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    func sendMessage() {
        let formatter = ISO8601DateFormatter()
        let time = formatter.string(from: Date.now)
        viewModel.send(.messageSent(message: currentMessage, time: time))
        currentMessage = ""
    }
}
