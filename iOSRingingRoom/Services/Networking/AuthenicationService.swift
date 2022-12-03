//
//  LoginService.swift
//  NewRingingRoom
//
//  Created by Matthew on 11/07/2022.
//

import Foundation

struct AuthenticationService: UnauthenticatedClient {
    
    var region: Region = Region(server: UserDefaults.standard.string(forKey: UserDefaults.Keys.Server) ?? "") ?? .uk {
        didSet {
            UserDefaults.standard.set(region.server, forKey: UserDefaults.Keys.Server)
        }
    }
    
    var retryAction: (() async -> Void)? = nil
    
    @discardableResult func registerUser(username: String, email: String, password: String) async throws -> APIModel.User {
        try await request(
            path: "user",
            method: .post,
            json: ["password": password,
            "username": username,
            "email": email],
            model: APIModel.User.self
        )
    }
    
    @discardableResult func resetPassword(email: String) async throws -> JSON {
        try await request(
            path: "user/reset_password",
            method: .post,
            json: ["email": email],
            model: JSON.self
        )
    }
    
    func getToken(email: String, password: String) async throws -> String {
        let utf8str = "\(email.lowercased()):\(password)".data(using: .utf8)
        
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            return try await request(
                path: "tokens",
                method: .post,
                headers: ["Authorization":"Basic \(base64Encoded)"],
                model: APIModel.Login.self
            )
                .token
        } else {
            throw APIError.encode
        }
    }
    
    func login(email: String, password: String) async throws -> (User, APIService) {
        let token = try await getToken(email: email.lowercased(), password: password)
        let apiService = APIService(token: token, region: region)
        
        let towers = try await apiService.getTowers()
        let userDetails = try await apiService.getUserDetails()
        let user = User(email: email, password: password, username: userDetails.username, towers: towers)
        return (user, apiService)
    }
}
