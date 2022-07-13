//
//  User.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

struct User {
    var email: String
    var password: String
    
    var ringer: Ringer
    
    var towers: [Tower]
}
