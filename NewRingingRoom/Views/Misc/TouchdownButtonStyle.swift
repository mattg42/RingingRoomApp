//
//  TouchdownButtonStyle.swift
//  NewRingingRoom
//
//  Created by Matthew on 20/08/2022.
//

import SwiftUI

struct TouchdownButtonStyle: PrimitiveButtonStyle {
    
    @Environment(\.scenePhase) var scenePhase
        
    @State var opacity = 1.0
    @State var disabled = false
            
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onLongPressGesture(
                minimumDuration: 20,
                pressing: { isPressed in
                    if isPressed {
                        configuration.trigger()
                        opacity = 0.35
                        withAnimation(.linear(duration: 0.25)) {
                            opacity = 1
                        }
                        disabled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            disabled = false
                        }
                    }
                },
                perform: {}
            )
            .opacity(opacity)
            .disabled(disabled)
    }
}

extension PrimitiveButtonStyle where Self == TouchdownButtonStyle {
    static var touchdown: TouchdownButtonStyle { TouchdownButtonStyle() }
}
