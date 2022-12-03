//
//  User.swift
//  iOSRingingRoom
//
//  Created by Matthew on 11/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

@propertyWrapper
struct RingerID {
    private var number:Int
    
    init() {
        self.number = 0
    }
    
    var wrappedValue:Int {
        get {
            number
        }
        set {
            number = (number == 0) ? newValue : number
        }
    }
}

class User:ObservableObject {
    static var shared = User()
    
    private init() {}
    
    @RingerID var ringerID
    
    var loggedIn:Bool = false
    @Published var name:String = ""
    var email:String = "" {
        didSet {
            email = email.lowercased()
            objectWillChange.send()
        }
    }
    var password = ""
        
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
        User.shared = User()
    }
    
    func sortTowers() {
            self.objectWillChange.send()
            self.myTowers.sort(by: { $0.visited > $1.visited } )
            print("sorted myTowers")
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
