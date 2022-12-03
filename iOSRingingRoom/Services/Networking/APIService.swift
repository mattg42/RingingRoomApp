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
    
    var retryAction: (() async -> ())? = nil
    
    func getTowers() async throws -> [Tower] {
        try await request(path: "my_towers", method: .get, model: [String: APIModel.Tower].self)
            .values
            .map { tower in
                Tower(towerModel: tower)
            }
            .sorted(by: {
                $0.visited > $1.visited
            })
    }
    
    func getUserDetails() async throws -> APIModel.User {
        try await request(path: "user", method: .get, model: APIModel.User.self)
    }
    
    func getTowerDetails(towerID: Int) async throws -> APIModel.TowerDetails {
        try await request(path: "tower/\(towerID)", method: .get, model: APIModel.TowerDetails.self)
    }
    
    func createTower(called name: String) async throws -> APIModel.TowerCreationDetails {
        try await request(path: "tower", method: .post, json: ["tower_name": name], model: APIModel.TowerCreationDetails.self)
    }
}
