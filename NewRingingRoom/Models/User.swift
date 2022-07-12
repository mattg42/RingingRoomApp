//
//  User.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

class User: ObservableObject {
    var email: String = ""
    var password: String = ""
    var username: String = ""
    var ringerID: String = ""
    
    var towers = [Tower]()
}
