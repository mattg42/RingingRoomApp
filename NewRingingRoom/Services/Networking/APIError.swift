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
    case invalidURL(attemptedURL: String)
    case noResponse
    case unauthorized
    case encode
    case http(code: Int)
    case unknown(message: String)
    
    var alertData: AlertData {
        switch self {
        case .decode(let error):
            return AlertData(title: "Decoding error", message: "There was an error decoding the server response: \(error.localizedDescription) Please make sure the app is updated.")
        case .url(let error):
            return AlertData(title: "Couldn't reach server", message: "There was an error reaching the server: \(error.localizedDescription)")
        case .invalidURL(let url):
            return AlertData(title: "Invalid URL", message: "Invalid request URL: \(url). Please screenshot and email to support at ringingroomapp@gmail.com.")
        case .noResponse:
            return AlertData(title: "No response", message: "There was no response from the server. Please try again.")
        case .unauthorized:
            return AlertData(title: "Unauthorized", message: "Please restart the app.")
        case .encode:
            return AlertData(title: "Encoding error", message: "There was an error encoding your username or password.")
        case .http(let code):
            return AlertData(title: "Unexpected server response", message: "HTTP code: \(code). Please contact support at ringingroomapp@gmail.com, and provide the HTTP code and explain what you were trying to do.")
        case .unknown(let message):
            return AlertData(title: "Unexpected error", message: "An unknown error occured: \(message)")
        }
    }
}
