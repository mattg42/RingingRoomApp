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
    var region: Region { get set }
    var token: String? { get set }
    
    func request<T: Decodable>(endpoint: String, method: HTTPMethod, json: JSON?, headers: JSON?, auth: Bool, model: T.Type) async -> Result<T, APIError>
}

extension HTTPClient {
    func request<T: Decodable>(endpoint: String, method: HTTPMethod, json: JSON? = nil, headers: JSON? = nil, auth: Bool = true, model: T.Type) async -> Result<T, APIError> {
        
        let url = URL(string: "https://\(region.server)ringingroom.co.uk/api/\(endpoint)")!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        
        if auth {
            if let token = token {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
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
                return .failure(.noResponse)
            }
            switch response.statusCode {
            case 200...299:
                let decodedResponse = try JSONDecoder().decode(model, from: data)
                return .success(decodedResponse)
            case 401:
                return .failure(.unauthorized)
            default:
                return .failure(.http(code: response.statusCode))
            }
        } catch let error as DecodingError {
            return .failure(.decode(error: error))
        } catch let error as URLError {
            return .failure(.url(error: error))
        } catch {
            return .failure(.unknown(message: error.localizedDescription))
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
