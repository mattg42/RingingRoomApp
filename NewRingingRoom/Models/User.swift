//
//  User.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import Foundation

class User: ObservableObject {
    
    static var shared = User()
    
    private init() {}
    
    var email: String = ""
    var password: String = ""
    var username: String = ""
    var ringerID: String = ""
    
    var towers = [Tower]()
    
}
