//
//  Ringer.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation

struct Ringer: Identifiable, Codable {
    var id: Int { ringerID }
    
    var name: String
    var ringerID: Int
    
    init(name: String, id: Int) {
        self.name = name
        self.ringerID = id
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "username"
        case ringerID = "user_id"
    }
}
