//
//  HTTPClient.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation
import Combine
import SwiftUI

protocol HTTPClient {
    var region: Region { get }
    var domain: String { get }
        
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON?, headers: JSON?, model: T.Type)  async throws -> T
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
                print(error)
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw APIError.noResponse
            }
            switch response.statusCode {
            case 200...299:
                let decodedResponse = try JSONDecoder().decode(model, from: data)
                return decodedResponse
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.http(code: response.statusCode)
            }
        } catch let error as DecodingError {
            throw APIError.decode(error: error)
        } catch let error as URLError {
            throw APIError.url(error: error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(message: error.localizedDescription)
        }
    }
}

protocol UnauthenticatedClient: HTTPClient {
    var region: Region { get set }
        
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON?, headers: JSON?, model: T.Type)  async throws -> T
}

extension UnauthenticatedClient {
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON? = nil, headers: JSON? = nil, model: T.Type)  async throws -> T {
        try await request(path: path, method: method, json: json, headers: headers, token: nil, model: model)
    }
}

protocol AuthenticatedClient: HTTPClient {
    var region: Region { get }
    
    var token: String { get }
    
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON?, headers: JSON?, model: T.Type)  async throws -> T}

extension AuthenticatedClient {
    func request<T: Decodable>(path: String, method: HTTPMethod, json: JSON? = nil, headers: JSON? = nil, model: T.Type)  async throws -> T {
        try await request(path: path, method: method, json: json, headers: headers, token: token, model: model)
    }
}

typealias JSON = [String: String]

enum HTTPMethod: String {
    case get = "GET",
         del = "DELETE",
         put = "PUT",
         post = "POST"
}
