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
    
    init(apiService: APIServiceable) {
        self._loginModel = StateObject(wrappedValue: LoginViewModel(apiService: apiService, errorHandler: ErrorHandler()))
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
