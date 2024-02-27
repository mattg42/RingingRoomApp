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
    
    @GestureState private var location = CGPoint.zero
        
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(opacity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ gesture in
                        if !disabled && location == .zero {
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
                    })
                    .updating($location) { value, state, transaction in
                        state = value.location
                    }
            )
    }
}

extension PrimitiveButtonStyle where Self == BellTouchdownButtonStyle {
    static var bellTouchdown: BellTouchdownButtonStyle { BellTouchdownButtonStyle() }
}
