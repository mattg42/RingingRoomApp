//
//  Ringer.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation

struct Ringer: Identifiable, Codable, Equatable {
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
    
    init(from dict: [String: Any]) {
        print(dict)
        let name = dict["username"] as! String
        let ringerID = dict["user_id"] as! Int
        
        self = Ringer(name: name, id: ringerID)
    }
    
    static let wheatley = Ringer(name: "Wheatley", id: -1)
}

extension Array where Element == Ringer? {
    func allIndicesOfRinger(_ ringer: Ringer) -> [Int] {
        var output = [Int]()
        
        if contains(ringer) {
            for (index, element) in self.enumerated() {
                if element == ringer {
                    output.append(index)
                }
            }
            return output
        } else {
            return [Int]()
        }
    }
}

extension Array where Element == Ringer {
    mutating func remove(_ ringer: Ringer) {
        for (index, element) in self.enumerated() {
            if element == ringer {
                self.remove(at: index)
                return
            }
        }
    }
    
    mutating func sortAlphabetically() {
        self.sort { (first, second) -> Bool in
            first.name.lowercased() < second.name.lowercased()
        }
    }
}
