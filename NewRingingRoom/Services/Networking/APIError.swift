//
//  APIError.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation

enum APIError: Error, Alertable {
    case decode(error: DecodingError)
    case url(error: URLError)
    case invalidURL
    case noResponse
    case unauthorized
    case encode
    case http(code: Int)
    case unknown(message: String)
    
    var errorAlert: ErrorAlert {
        ErrorAlert(title: errorTitle, message: errorMessage, dissmiss: errorDissmiss)
    }
    
    var errorTitle: String {
        switch self {
        case .decode(let error):
            <#code#>
        case .url(let error):
            <#code#>
        case .invalidURL:
            <#code#>
        case .noResponse:
            <#code#>
        case .unauthorized:
            <#code#>
        case .encode:
            <#code#>
        case .http(let code):
            <#code#>
        case .unknown(let message):
            <#code#>
        }
    }
    
    var errorMessage: String {
        switch self {
        case .decode(let error):
            return "There was an error decoding the server response: \(error.localizedDescription)"
        case .url(let error):
            <#code#>
        case .invalidURL:
            <#code#>
        case .noResponse:
            <#code#>
        case .unauthorized:
            <#code#>
        case .encode:
            return "There was an error encoding your username or password."
        case .http(let code):
            <#code#>
        case .unknown(let message):
            <#code#>
        }
    }
    
    var errorDissmiss: DissmissType {
        switch self {
        case .decode(let error):
            <#code#>
        case .url(let error):
            <#code#>
        case .invalidURL:
            <#code#>
        case .noResponse:
            <#code#>
        case .unauthorized:
            <#code#>
        case .encode:
            return .cancel(title: "OK", action: nil)
        case .http(let code):
            <#code#>
        case .unknown(let message):
            <#code#>
        }
    }
    
}
