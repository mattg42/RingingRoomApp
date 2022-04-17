//
//  APIService.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

protocol APIServiceable {
    var region: Region { get set }
    var token: String? { get set }
    
    func login(base64Encoded: String) async -> Result<String, APIError>
    func getTowers() async -> Result<[Tower], APIError>
    func getUserDetails() async -> Result<APIModel.User, APIError>
    func getTowerDetails(towerID: Int) async -> Result<APIModel.TowerInfo, APIError>
    func registerUser(username: String, email: String, password: String) async -> Result<APIModel.User, APIError>
    func resetPassword(email: String) async -> Result<JSON, APIError>
}

class APIService: HTTPClient, APIServiceable {
    
    var region: Region = Region(server: UserDefaults.standard.string(forKey: UserDefaults.Keys.Server) ?? "") ?? .uk {
        didSet {
            UserDefaults.standard.set(region.server, forKey: UserDefaults.Keys.Server)
        }
    }
    
    var token: String?
    
    func login(base64Encoded: String) async -> Result<String, APIError> {
        await request(endpoint: "tokens", method: .post, json: nil, headers: ["Authorization":"Basic \(base64Encoded)"], auth: false, model: APIModel.Login.self)
            .map(\.token)
    }
    
    func getTowers() async -> Result<[Tower], APIError> {
        await request(endpoint: "my_towers", method: .get, model: [String: APIModel.Tower].self)
            .map {
                $0.values.map {
                    Tower(towerModel: $0)
                }
            }
    }
    
    func getUserDetails() async -> Result<APIModel.User, APIError> {
        await request(endpoint: "user", method: .get, model: APIModel.User.self)
    }
    
    func getTowerDetails(towerID: Int) async -> Result<APIModel.TowerInfo, APIError> {
        
        await request(endpoint: "tower/\(towerID)", method: .get, model: APIModel.TowerInfo.self)
    }
    
    func registerUser(username: String, email: String, password: String) async -> Result<APIModel.User, APIError> {
        await request(endpoint: "user", method: .post, json: ["password": password, "username": username, "email": email], auth: false, model: APIModel.User.self)
    }
    
    func resetPassword(email: String) async -> Result<JSON, APIError> {
        await request(endpoint: "user/reset_password", method: .post, json: ["email": email], auth: false, model: JSON.self)
    }
}
