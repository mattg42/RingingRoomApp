//
//  User.swift
//  iOSRingingRoom
//
//  Created by Matthew on 11/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

class User:ObservableObject {
    static var shared = User()
    
    var ringerID = 0
    var loggedIn:Bool = false
    var name:String = ""
    var email:String = ""
    
    @Published var myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
    
    var firstTower = true
    
    func addTower(_ tower:Tower) {
            if self.firstTower {
                self.objectWillChange.send()
                self.myTowers[0] = tower
                self.firstTower = false
            } else {
                self.myTowers.append(tower)
                self.sortTowers()
            }
    }
    
    func sortTowers() {
        self.objectWillChange.send()
        self.myTowers.sort(by: { $0.tower_name <
            $1.tower_name } )
    }
}

class Ringer:Identifiable {
    var id = UUID()
    
    static var blank:Ringer {
        get {
            Ringer(name: "", id: 0)
        }
    }

    var name:String
    var userID:Int
    
    var assignments = [Int]()
    
    var description:String {
        get {
            "\(name), \(userID)"
        }
    }
    
    init(name:String, id:Int) {
        self.name = name
        self.userID = id
    }
}
