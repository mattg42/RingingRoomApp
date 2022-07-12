//
//  LoginOverview.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/08/2021.
//

import Foundation
import SwiftUI

enum LoginState {
    case auto
    case welcome
}

struct LoginOverview: View {
    
    @State var loginState: LoginState = .welcome
    
    var body: some View {
        Group {
            switch loginState {
            case .welcome:
                WelcomeLoginView()
            case .auto:
                AutoLoginView()
            }
        }
    }
}
