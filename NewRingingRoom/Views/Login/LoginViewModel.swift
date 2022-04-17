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
    
    init(apiService: APIServiceable, errorHandler: ErrorHandleable) {
        self.apiService = apiService
        self.errorHandler = errorHandler
    }
    
    var apiService: APIServiceable
    let errorHandler: ErrorHandleable
    
    func login(email: String, password: String, withTowerID towerID: Int? = nil) async {
        
        apiService.region = .uk
        let utf8str = "\(email.lowercased()):\(password)".data(using: .utf8)
        
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            do {
                let token = try await apiService.login(base64Encoded: base64Encoded).get()
                apiService.token = token
                
                let userResult = try await apiService.getUserDetails().get()
                let towersResult = try await apiService.getTowers().get()
                
                if let towerID = towerID {
                    let towerInfo = try await apiService.getTowerDetails(towerID: towerID).get()
                    print(towerInfo)
                } else {
                    
                }
            } catch let error as APIError {
                errorHandler.handle(error: error)
            } catch {
                fatalError("Not possible")
            }
            
        } else {
            errorHandler.handle(error: APIError.encode)
        }
    }
}

