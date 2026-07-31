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
    private let isUITestingAutomaticLogin: Bool
    
    init(_ loginState: LoginState? = nil, isUITestingAutomaticLogin: Bool = false) {
        self.isUITestingAutomaticLogin = isUITestingAutomaticLogin
        if let loginState {
            self.loginState = loginState
        } else {
            self.loginState = SessionCredentialStore.standard.keepMeLoggedIn ? .auto : .welcome
        }
    }
    
    @State var loginState: LoginState
    
    var body: some View {
        Group {
            switch loginState {
            case .welcome:
                WelcomeLoginView()
            case .auto:
                AutoLoginView(loginState: $loginState, isUITesting: isUITestingAutomaticLogin)
            }
        }
    }
}
