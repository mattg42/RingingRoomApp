//
//  AsyncButton.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import SwiftUI

fileprivate struct AsyncButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.35 : 1)
            .animation(nil, value: configuration.isPressed)
            .foregroundColor(.main)
    }
}

struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label
    
    @State private var isPerformingTask = false
    
    var body: some View {
        Button {
            isPerformingTask = true
            
            Task {
                await action()
                isPerformingTask = false
                print("set button ksjdfhaskldjfl;djsakhlkadsjh")
            }
        } label: {
            ZStack {
                label()
                    .opacity(isPerformingTask ? 0.35 : 1)
            }
        }
        .disabled(isPerformingTask)
        .buttonStyle(AsyncButtonStyle())
    }
}

extension AsyncButton where Label == Text {
    init(_ label: String, action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}
