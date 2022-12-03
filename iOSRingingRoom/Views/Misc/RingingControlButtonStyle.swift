//
//  RingingControlButtonStyle.swift
//  NewRingingRoom
//
//  Created by Matthew on 27/11/2022.
//

import SwiftUI

struct RingingControlButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Color.main
                .cornerRadius(5)
            
            configuration.label
                .font(.body.bold())
                .padding(.horizontal, 3.5)
                .foregroundColor(.white)
                .padding(2)
                .minimumScaleFactor(0.7)
        }
        .fixedSize()
    }
}

extension ButtonStyle where Self == RingingControlButtonStyle {
    static var ringingControlButton: RingingControlButtonStyle { RingingControlButtonStyle() }
}
