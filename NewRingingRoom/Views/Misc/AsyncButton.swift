//
//  AsyncButton.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import SwiftUI

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
            if isPerformingTask {
                ProgressView()
                    .progressViewStyle(.circular)
                    .foregroundColor(.white)
                    .tint(.white)
            } else {
                label()
            }

//            .opacity(isPerformingTask ? 0.35 : 1)

        }
        .disabled(isPerformingTask)
        .contentShape(RoundedRectangle(cornerRadius: 5))
    }
}

extension AsyncButton where Label == Text {
    init(_ label: String, action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}
