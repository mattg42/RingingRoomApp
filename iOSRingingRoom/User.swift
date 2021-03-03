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
    static var blank:User {
        get { User() }
    }
    
    var ringerID = 0
    var loggedIn:Bool = false
    var name:String = ""
    var email:String = ""
    var password = ""
    
//    @Published var towerID = 0
    
    @Published var myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
    
    var firstTower = true
    
    func addTower(_ tower:Tower) {
            if self.firstTower {
                self.myTowers[0] = tower
                self.firstTower = false
            } else {
                self.myTowers.append(tower)
            }
    }
    
    func reset() {
        ringerID = 0
        loggedIn = false
        name = ""
        email = ""
        password = ""
        myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
        
        firstTower = true
    }
    
    func sortTowers() {
//        DispatchQueue.main.async {
            self.objectWillChange.send()
//            print(self.myTowers.dates)
            self.myTowers.sort(by: { $0.visited > $1.visited } )
            print("sorted myTowers")
//            NotificationCenter.default.post(name: Notification.Name.gotMyTowers, object: self)
//        }
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
