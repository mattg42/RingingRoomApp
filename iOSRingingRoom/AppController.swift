//
//  AppController.swift
//  iOSRingingRoom
//
//  Created by Matthew on 14/02/2021.
//  Copyright © 2021 Matthew Goodship. All rights reserved.
//

import Foundation

class AppController:ObservableObject {
    
    static var shared = AppController()
    
    @Published var loginState = UserDefaults.standard.bool(forKey: "keepMeLoggedIn") ? LoginState.auto : LoginState.standard
    
    @Published var selectedTab = TabViewType.ring
    
    @Published var state = AppState.login {
        didSet {
            if !User.shared.loggedIn {
                state = .login
            }
        }
    }
}


enum AppState {
    case login
    case main
    case ringing
}

enum LoginState {
    case auto
    case standard
}
