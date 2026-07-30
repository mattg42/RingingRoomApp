//
//  HTTPClient.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation
import Combine
import SwiftUI

@MainActor
protocol HTTPClient {
    var region: Region { get }
    var domain: String { get }
    var retryAction: AsyncAction? { get set }
        
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON?, headers: JSON?, model: T.Type)  async throws -> T
}

typealias AsyncAction = @MainActor @Sendable () async -> Void

actor TokenRefreshCoordinator {
    private var refreshTask: Task<String, Error>?

    func refresh(using operation: @escaping @Sendable () async throws -> String) async throws -> String {
        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task {
            try await operation()
        }
        refreshTask = task
        return try await task.value
    }

    func finish() {
        refreshTask = nil
    }
}

extension HTTPClient {
    
    var domain: String {
        "\(region.server)ringingroom.com"
    }
    
    fileprivate func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON? = nil, headers: JSON? = nil, token: String? = nil, model: T.Type) async throws -> T {
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = domain
        components.path = "/api/\(path)"
        
        guard let url = components.url else {
            throw APIError.invalidURL(attemptedURL: "https://\(domain)/api/\(path)")
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let headers = headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        if let json = json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: json)
            } catch {
                AppLogger.network.error("Failed to encode request body: \(String(describing: error), privacy: .private)")
            }
        }

        AppLogger.network.debug("Starting \(method.rawValue, privacy: .public) request for \(path, privacy: .private(mask: .hash))")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw APIError.noResponse
            }
            AppLogger.network.debug("Received HTTP response with status \(response.statusCode, privacy: .public)")
            switch response.statusCode {
            case 200...299:
                AppLogger.network.debug("Request succeeded with \(data.count, privacy: .public) response bytes")
                return try JSONDecoder().decode(model, from: data)
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.http(code: response.statusCode)
            }
        } catch let error as DecodingError {
            AppLogger.network.error("Failed to decode response for \(path, privacy: .private(mask: .hash)): \(String(describing: error), privacy: .private)")
            throw APIError.decode(error: error)
        } catch let error as URLError {
            AppLogger.network.error("Network request failed for \(path, privacy: .private(mask: .hash)) with URL error \(error.code.rawValue, privacy: .public)")
            throw APIError.url(error: error, retryAction: retryAction)
        } catch let error as APIError {
            AppLogger.network.debug("Request failed for \(path, privacy: .private(mask: .hash)) with API error \(String(describing: error), privacy: .private)")
            throw error
        } catch {
            AppLogger.network.error("Request failed for \(path, privacy: .private(mask: .hash)): \(String(describing: error), privacy: .private)")
            throw APIError.unknown(message: error.localizedDescription)
        }
    }
}

@MainActor
protocol UnauthenticatedClient: HTTPClient {
    var region: Region { get set }
        
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON?, headers: JSON?, model: T.Type)  async throws -> T
}

extension UnauthenticatedClient {
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON? = nil, headers: JSON? = nil, model: T.Type)  async throws -> T {
        try await request(path: path, method: method, json: json, headers: headers, token: nil, model: model)
    }
}

@MainActor
protocol AuthenticatedClient: AnyObject, HTTPClient {
    var token: String { get set }
    var sessionCredentials: SessionCredentials? { get }
    var tokenRefreshCoordinator: TokenRefreshCoordinator { get }
    var sessionExpiredAction: AsyncAction? { get set }
    
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON?, headers: JSON?, model: T.Type)  async throws -> T
}

extension AuthenticatedClient {
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON? = nil, headers: JSON? = nil, model: T.Type)  async throws -> T {
        do {
            return try await request(path: path, method: method, json: json, headers: headers, token: token, model: model)
        } catch APIError.unauthorized {
            try await updateToken()
            return try await request(path: path, method: method, json: json, headers: headers, token: token, model: model)
        }
    }
    
    func updateToken() async throws {
        guard let credentials = sessionCredentials else {
            await endSession()
            throw APIError.sessionExpired
        }

        let email = credentials.email
        let password = credentials.password
        let region = self.region

        do {
            let token = try await tokenRefreshCoordinator.refresh {
                try await AuthenticationService.getToken(
                    email: email,
                    password: password,
                    region: region
                )
            }

            self.token = token
            await tokenRefreshCoordinator.finish()
        } catch APIError.unauthorized {
            await tokenRefreshCoordinator.finish()
            await endSession()
            throw APIError.sessionExpired
        } catch {
            await tokenRefreshCoordinator.finish()
            throw error
        }
    }

    private func endSession() async {
        var credentialAccounts = sessionCredentials.map { [$0.email] } ?? []

        if let storedEmail = UserDefaults.standard.string(forKey: "userEmail") {
            let trimmedEmail = storedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            credentialAccounts.append(contentsOf: [storedEmail, trimmedEmail, trimmedEmail.lowercased()])
        }

        for account in Set(credentialAccounts) where !account.isEmpty {
            try? KeychainService.deletePasswordFor(account: account, server: domain)
        }

        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")

        if let sessionExpiredAction {
            await sessionExpiredAction()
        }
    }
}

typealias JSON = [String: String]

enum HTTPMethod: String {
    case get = "GET",
         del = "DELETE",
         put = "PUT",
         post = "POST"
}
