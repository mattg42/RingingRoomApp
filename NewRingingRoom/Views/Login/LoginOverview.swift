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
    
    init(apiService: APIServiceable, router: AppRouter) {
        self._loginModel = StateObject(wrappedValue: LoginViewModel(apiService: apiService, router: router))
    }
    
    @State var loginState: LoginState = .welcome
    
    @StateObject var loginModel: LoginViewModel
    
    var body: some View {
        Group {
            switch loginState {
            case .welcome:
                WelcomeLoginView()
            case .auto:
                AutoLoginView()
            }
        }
        .environmentObject(loginModel)
    }
}

protocol Loginable {
    func login(email: String, password: String, withTowerID towerID: Int?) async
}

extension Loginable {
    
}
