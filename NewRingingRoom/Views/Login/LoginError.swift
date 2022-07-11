//
//  LoginError.swift
//  NewRingingRoom
//
//  Created by Matthew on 17/04/2022.
//

import Foundation

enum LoginError: Error, Alertable {
    case emailNotValid, noUsername, noPassword, passwordsDontMatch
    
    var alertData: AlertData {
        switch self {
        case .emailNotValid:
            return AlertData(title: "Invalid email", message: "The email address you entered is invalid.", dissmiss: .cancel(title: "Ok", action: nil))
        case .noUsername:
            return AlertData(title:"No username", message: "Please enter a username", dissmiss: .cancel(title: "Ok", action: nil))
        case .noPassword:
            return AlertData(title: "No password", message: "Please enter a password", dissmiss: .cancel(title: "Ok", action: nil))
        case .passwordsDontMatch:
            return AlertData(title: "Passwords don't match", message: "Please type in the same password twice", dissmiss: .cancel(title: "Ok", action: nil))
        }
    }
}
