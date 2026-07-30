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
    init(
        token: String,
        region: Region,
        credentials: SessionCredentials? = nil,
        retryAction: AsyncAction? = nil,
        urlSession: URLSession = .shared,
        credentialStore: SessionCredentialStore = .standard
    ) {
        self.token = token
        self.region = region
        self.sessionCredentials = credentials
        self.retryAction = retryAction
        self.urlSession = urlSession
        self.credentialStore = credentialStore
    }

    var token: String
    let region: Region
    var sessionCredentials: SessionCredentials?
    let urlSession: URLSession
    let credentialStore: SessionCredentialStore
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

    @discardableResult
    func updateUser(username: String? = nil, email: String? = nil, password: String? = nil) async throws -> APIModel.User {
        var updates: JSON = [:]

        if let username {
            updates["new_username"] = username
        }
        if let email {
            updates["new_email"] = email
        }
        if let password {
            updates["new_password"] = password
        }

        let updatedUser = try await request(
            path: "user",
            method: .put,
            json: updates,
            model: APIModel.User.self
        )

        guard let oldCredentials = sessionCredentials else {
            return updatedUser
        }

        let newCredentials = SessionCredentials(
            email: updatedUser.email,
            password: password ?? oldCredentials.password
        )

        // The server has accepted the update, so the in-memory credentials must
        // change even if Keychain persistence reports a failure.
        sessionCredentials = newCredentials

        do {
            try credentialStore.updateCredentials(
                from: oldCredentials,
                to: newCredentials,
                server: domain
            )
        } catch {
            credentialStore.disableAutomaticLogin()
            throw APIError.credentialsNotSaved(user: updatedUser)
        }

        return updatedUser
    }

    func deleteUser() async throws -> APIModel.DeletedUser {
        try await request(path: "user", method: .del, model: APIModel.DeletedUser.self)
    }

    func reauthenticate(with password: String) async throws {
        guard let credentials = sessionCredentials else {
            throw APIError.sessionExpired
        }

        let refreshedToken = try await AuthenticationService(
            region: region,
            urlSession: urlSession
        ).getToken(email: credentials.email, password: password)
        token = refreshedToken
    }

    @discardableResult
    func clearSession() -> SessionCredentialStore.CleanupResult {
        let result = credentialStore.clear(currentEmail: sessionCredentials?.email)
        sessionCredentials = nil
        token = ""
        return result
    }

    func persistLogin(keepMeLoggedIn: Bool) throws {
        guard let sessionCredentials else { return }
        try credentialStore.persistLogin(
            credentials: sessionCredentials,
            keepMeLoggedIn: keepMeLoggedIn,
            server: domain
        )
    }
    
    func getTowerDetails(towerID: Int) async throws -> APIModel.TowerDetails {
        try await request(path: "tower/\(towerID)", method: .get, model: APIModel.TowerDetails.self)
    }
    
    func createTower(called name: String) async throws -> APIModel.TowerCreationDetails {
        try await request(path: "tower", method: .post, json: ["tower_name": name], model: APIModel.TowerCreationDetails.self)
    }
}
