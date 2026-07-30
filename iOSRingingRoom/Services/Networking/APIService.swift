//
//  APIService.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

struct SessionCredentials: Sendable {
    let email: String
    let password: String

    init(email: String, password: String) {
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.password = password
    }
}

@MainActor
class APIService: AuthenticatedClient {
    init(token: String, region: Region, credentials: SessionCredentials? = nil, retryAction: AsyncAction? = nil) {
        self.token = token
        self.region = region
        self.sessionCredentials = credentials
        self.retryAction = retryAction
    }

    var token: String
    let region: Region
    let sessionCredentials: SessionCredentials?
    let tokenRefreshCoordinator = TokenRefreshCoordinator()
    
    var retryAction: AsyncAction? = nil
    var sessionExpiredAction: AsyncAction? = nil
    
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
