//
//  Bell.swift
//  iOSRingingRoom
//
//  Created by Matthew on 17/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import Combine

class BellCircle: ObservableObject {
    
    @Published var bells:[Bell]
    
    @Published var size:Int {
        didSet {
            
            var newBells = [Bell]()
            for i in 1...size {
                newBells.append(Bell(number: i))
            }
            bells = newBells
        }
    }
    
    init(number:Int = 0) {
        self.size = number
        bells = [Bell]()
        if number > 0 {
            for i in 1...number {
                bells.append(Bell(number: i))
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateBells), name: NSNotification.Name.strokeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBells), name: NSNotification.Name.assignmentChanged, object: nil)
    }
    
    @objc func updateBells(notification:Notification) {
        print("received notification")
        let info = notification.userInfo!
        var newBells = [Bell]()
        
        for bell in self.bells {
            newBells.append(bell)
        }
        
        if notification.name.rawValue == "strokeChanged" {
            newBells[(info["number"] as! Int) - 1] = Bell(number: info["number"] as! Int, stroke: info["stroke"] as! Stroke)
        } else if notification.name.rawValue == "assignmentChanged" {
            newBells[(info["number"] as! Int) - 1] = Bell(number: info["number"] as! Int, person: info["person"] as! String)
        }
        
        self.bells = newBells
    }
}

class Bell:Identifiable {
    
    var id = UUID()
    
    var stroke:Stroke {
        didSet {
            print("posting")
            NotificationCenter.default.post(name: NSNotification.Name.strokeChanged, object: nil, userInfo: ["number":self.number, "stroke": self.stroke])
        }
    }
    var number:Int
    var person:String {
        didSet {
            print("posting")
            NotificationCenter.default.post(name: NSNotification.Name.assignmentChanged, object: nil, userInfo: ["number":self.number, "person": self.person])
        }
    }
    
    init(number:Int, stroke:Stroke = .handstoke, person:String = "") {
        self.number = number
        self.stroke = stroke
        self.person = person
    }
}

extension NSNotification.Name {
    public static let strokeChanged = NSNotification.Name(rawValue: "strokeChanged")
    public static let assignmentChanged = NSNotification.Name(rawValue: "assignmentChanged")

}
