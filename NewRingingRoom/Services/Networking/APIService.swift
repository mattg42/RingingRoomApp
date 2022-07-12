//
//  APIService.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

struct APIService: AuthenticatedClient {

    let token: String
    let region: Region
    
    func getTowers() async throws -> [Tower] {
        try await request(path: "my_towers", method: .get, model: [String: APIModel.Tower].self)
            .values
            .map { tower in
                Tower(towerModel: tower)
            }
    }
    
    func getUserDetails() async throws -> APIModel.User {
        try await request(path: "user", method: .get, model: APIModel.User.self)
    }
    
    func getTowerDetails(towerID: Int) async throws -> APIModel.TowerInfo {
        try await request(path: "tower/\(towerID)", method: .get, model: APIModel.TowerInfo.self)
    }
}
