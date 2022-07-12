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
    
    func login(email: String, password: String) async throws -> String {
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
}
