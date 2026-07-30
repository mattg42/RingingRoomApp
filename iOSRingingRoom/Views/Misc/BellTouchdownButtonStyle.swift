//
//  TouchdownButtonStyle.swift
//  NewRingingRoom
//
//  Created by Matthew on 20/08/2022.
//

import SwiftUI

struct BellTouchdownButtonStyle: PrimitiveButtonStyle {
    
    private let cooldown = 0.25
    
    @State private var opacity = 1.0
    
    @State private var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(opacity)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: 10,
                perform: {},
                onPressingChanged: { isPressing in
                    guard isPressing else { return }
                    guard !disabled else { return }
                    disabled = true
                    configuration.trigger()
                    opacity = 0.35
                    withAnimation(.linear(duration: cooldown)) {
                        opacity = 1
                    }

                    ThreadUtil.runInMain(after: cooldown) {
                        disabled = false
                    }
                }
            )
    }
}

extension PrimitiveButtonStyle where Self == BellTouchdownButtonStyle {
    static var bellTouchdown: BellTouchdownButtonStyle { BellTouchdownButtonStyle() }
}
