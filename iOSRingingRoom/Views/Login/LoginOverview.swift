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
    
    init(_ loginState: LoginState? = nil) {
        if let loginState {
            self.loginState = loginState
        } else {
            self.loginState = UserDefaults.standard.bool(forKey: "keepMeLoggedIn") ? .auto : .welcome
        }
    }
    
    let loginState: LoginState
    
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
