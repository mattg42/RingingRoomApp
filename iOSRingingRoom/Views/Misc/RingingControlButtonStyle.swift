//
//  RingingControlButtonStyle.swift
//  NewRingingRoom
//
//  Created by Matthew on 27/11/2022.
//

import SwiftUI

struct RingingControlButtonStyleModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        ZStack {
            Color.main
                .cornerRadius(5)
            
            content
                .font(.body.bold())
                .padding(.horizontal, 3.5)
                .foregroundColor(.white)
                .padding(2)
                .minimumScaleFactor(0.7)
        }
        .fixedSize()
    }
}

extension View {
    func ringingControlButtonStyle() -> some View {
        self
            .modifier(RingingControlButtonStyleModifier())
    }
}
