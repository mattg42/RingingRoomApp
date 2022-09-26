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
    
    @State var opacity = 1.0
    
    @State var disabled = false
    
    @GestureState var location = CGPoint.zero
    
    @State var timer: Timer? = nil
    
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
            .onChange(of: scenePhase) { newValue in
                if newValue != .active {
                    timer?.invalidate()
                } else {
                    disabled = false
                }
            }
    }
    
    func isPressed(configuration: Configuration) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: false) { _ in
            configuration.trigger()
            opacity = 0.35
            withAnimation(.linear(duration: cooldown)) {
                opacity = 1
            }
            ThreadUtil.runInMain(after: cooldown) {
                disabled = false
            }
        }
    }
    
    
}

extension PrimitiveButtonStyle where Self == CallTouchdownButtonStyle {
    static var callTouchdown: CallTouchdownButtonStyle { CallTouchdownButtonStyle() }
}
