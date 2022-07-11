//
//  LoginViewModel.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/08/2021.
//

import Foundation
import Combine
import SwiftUI

class LoginViewModel: ObservableObject {
    
    init(apiService: APIServiceable, router: AppRouter) {
        self.apiService = apiService
        self.appRouter = router
    }
    
    var apiService: APIServiceable
    let appRouter: AppRouter
    
    func login(email: String, password: String, withTowerID towerID: Int? = nil) async {
        
        apiService.region = .uk
        let utf8str = "\(email.lowercased()):\(password)".data(using: .utf8)
        
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            let result = await apiService.login(base64Encoded: base64Encoded)
            switch result {
            case .success(let token):
                apiService.token = token
                // navigate to main module
                print("success")
                appRouter.moveTo(.main)
            case .failure(let error):
                AlertHandler.handle(error: error)
            }
        } else {
            AlertHandler.handle(error: APIError.encode)
        }
    }
}
