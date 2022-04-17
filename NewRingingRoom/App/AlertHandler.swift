//
//  ErrorHandler.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/10/2021.
//

import Foundation
import SwiftUI

public extension AlertHandler {
    static func incorrectCredentials(action: @escaping Action) {
        shared.presentAlert(title: "Credentials error", message: "Your username or password is incorrect.", action: action)
    }
    
    static func socketFailed() {
        shared.presentAlert(title: "Failed to connect socket", message: "Please try and join the tower again. If the problem persists, restart the app.")
    }
    
    static func unauthorised() {
        shared.presentAlert(title: "Invalid token", message: "Please restart the app.")
    }
    
    static func noTower() {
        shared.presentAlert(title: "No tower found", message: "There is no tower with that ID.")
    }
    
    static func unknownError(message: String) {
        shared.presentAlert(title: "Error", message: "An unknown error occurred. \(message)")
    }
    
    static func noInternet(action: @escaping Action) {
        shared.presentAlert(title: "Connection error", message: "Your device is not connected to the internet. Please check your internet connection and try again.", action: action)
    }
    
    static func resetPasswordRequestSent() {
        shared.presentAlert(title: "Request sent", message: "Check your email for the instructions to reset your password.")
    }
}
