//
//  CallTouchdownButtonStyle.swift
//  NewRingingRoom
//
//  Created by Matthew on 25/09/2022.
//

import SwiftUI

struct CallTouchdownButtonStyle: PrimitiveButtonStyle {
    
    @Environment(\.scenePhase) var scenePhase
    
    private let cooldown = 0.25
    
    @State private var opacity = 1.0
    
    @State private var disabled = false
    
    @GestureState var location = CGPoint.zero
    
    @State private var pressTask: Task<Void, Never>?
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(opacity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ gesture in
                        if !disabled && location == .zero {
                            disabled = true
                            isPressed(configuration: configuration)
                        }
                    })
                    .updating($location) { value, state, transaction in
                        state = value.location
                    }
            )
            .onChange(of: scenePhase) { _, newValue in
                if newValue != .active {
                    pressTask?.cancel()
                } else {
                    disabled = false
                }
            }
    }
    
    func isPressed(configuration: Configuration) {
        pressTask?.cancel()
        pressTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000)
            guard !Task.isCancelled else { return }
            configuration.trigger()
            opacity = 0.35
            withAnimation(.linear(duration: cooldown)) {
                opacity = 1
            }
            try? await Task.sleep(nanoseconds: UInt64(cooldown * 1_000_000_000))
            guard !Task.isCancelled else { return }
                disabled = false
        }
    }
    
    
}

extension PrimitiveButtonStyle where Self == CallTouchdownButtonStyle {
    static var callTouchdown: CallTouchdownButtonStyle { CallTouchdownButtonStyle() }
}
