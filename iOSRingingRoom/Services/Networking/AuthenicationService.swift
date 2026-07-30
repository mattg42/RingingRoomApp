//
//  LoginService.swift
//  NewRingingRoom
//
//  Created by Matthew on 11/07/2022.
//

import Foundation

@MainActor
struct AuthenticationService: UnauthenticatedClient, Sendable {
    init(region: Region? = nil, urlSession: URLSession = .shared) {
        self.region = region ?? Region(server: UserDefaults.standard.string(forKey: UserDefaults.Keys.Server) ?? "") ?? .uk
        self.urlSession = urlSession
    }

    var region: Region {
        didSet {
            UserDefaults.standard.set(region.server, forKey: UserDefaults.Keys.Server)
        }
    }
    
    var retryAction: AsyncAction? = nil
    let urlSession: URLSession
    
    @discardableResult func registerUser(username: String, email: String, password: String) async throws -> APIModel.User {
        AppLogger.auth.info("Starting account registration")
        return try await request(
            path: "user",
            method: .post,
            json: ["password": password,
            "username": username,
            "email": email],
            model: APIModel.User.self
        )
    }
    
    @discardableResult func resetPassword(email: String) async throws -> JSON {
        AppLogger.auth.info("Starting password reset request")
        return try await request(
            path: "user/reset_password",
            method: .post,
            json: ["email": email],
            model: JSON.self
        )
    }
    
    func getToken(email: String, password: String) async throws -> String {
        AppLogger.auth.info("Starting authentication request")
        let utf8str = "\(email.lowercased()):\(password)".data(using: .utf8)
        
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            let token = try await request(
                path: "tokens",
                method: .post,
                headers: ["Authorization":"Basic \(base64Encoded)"],
                model: APIModel.Login.self
            )
                .token
            AppLogger.auth.info("Authentication request succeeded")
            return token
        } else {
            throw APIError.encode
        }
    }

    static func getToken(email: String, password: String, region: Region, urlSession: URLSession = .shared) async throws -> String {
        try await AuthenticationService(region: region, urlSession: urlSession).getToken(email: email, password: password)
    }
    
    func login(email: String, password: String) async throws -> (User, APIService) {
        AppLogger.auth.info("Starting login flow")
        let credentials = SessionCredentials(email: email, password: password)
        let token = try await getToken(email: credentials.email, password: credentials.password)
        let apiService = APIService(token: token, region: region, credentials: credentials, urlSession: urlSession)
        
        let towers = try await apiService.getTowers()
        let userDetails = try await apiService.getUserDetails()
        let user = User(email: userDetails.email, username: userDetails.username, towers: towers)
        AppLogger.auth.info("Login flow succeeded")
        return (user, apiService)
    }
}
