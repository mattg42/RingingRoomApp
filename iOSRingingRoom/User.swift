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
    
    var loggedIn:Bool = false
    var name:String = ""
    var email:String = ""
    var host = false
    
    @Published var savedTowerID = UserDefaults.standard.string(forKey: "selectedTower") ?? "" {
        didSet {
            if UserDefaults.standard.bool(forKey: "keepMeLoggedIn") {
                UserDefaults.standard.set(savedTowerID, forKey: "selectedTower")
            }
        }
    }
    
    @Published var myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
    
    var firstTower = true
    
    func addTower(_ tower:Tower) {
        DispatchQueue.main.async {
            if self.firstTower {
                self.objectWillChange.send()
                self.myTowers[0] = tower
                self.firstTower = false
            } else {
                self.objectWillChange.send()
                self.myTowers.append(tower)
                self.myTowers.sort(by: { $0.tower_name <
                    $1.tower_name } )
//                self.myTowers = self.myTowers.sorted(by: {
//                    $0.visited.compare($1.visited) == .orderedDescending
//                })
            }
        }
    }
}
