//
//  Bell.swift
//  iOSRingingRoom
//
//  Created by Matthew on 17/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import Combine

enum Side {
    case left, right
}

enum BellType:String {
    case tower = "tower", hand = "hand"
}

class BellCircle: ObservableObject {
    
    @Published var bells:[Bell]
    
    @Published var bellType:BellType
    
    @Published var size:Int {
        didSet {
            
            var newBells = [Bell]()
            for i in 1...size {
                newBells.append(Bell(number: i, side: ((2...size/2).contains(i)) ? .left : .right))
            }
            bells = newBells
        }
    }
    
    init(number:Int = 0) {
        self.size = number
        bells = [Bell]()
        //change to .tower to test tower bells
        bellType = .hand
        if number > 0 {
            for i in 1...number {
                bells.append(Bell(number: i, side: ((2...size/2).contains(i)) ? .left : .right))
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateBells), name: NSNotification.Name.strokeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBells), name: NSNotification.Name.assignmentChanged, object: nil)
    }
    
    @objc func updateBells(notification:Notification) {
        print("received notification")
        let info = notification.userInfo!
        var newBells = self.bells
        
        if notification.name.rawValue == "strokeChanged" {
            newBells[(info["number"] as! Int) - 1] = Bell(number: info["number"] as! Int, stroke: info["stroke"] as! Stroke, person: info["person"] as! String, side: info["side"] as! Side)
        } else if notification.name.rawValue == "assignmentChanged" {
            newBells[(info["number"] as! Int) - 1] = Bell(number: info["number"] as! Int, stroke: info["stroke"] as! Stroke, person: info["person"] as! String, side: info["side"] as! Side)
        }
        
        self.bells = newBells
    }
}

class Bell:Identifiable {
    
    var id = UUID()
    
    var side:Side
    
    static var sounds = [
        BellType.tower : [
        4: ["5","6","7","8"],
        6: ["3","4","5","6","7","8"],
        8: ["1","2sharp","3","4","5","6","7","8"],
        10: ["3","4","5","6","7","8","9","0","E","T"],
        12: ["1","2","3","4","5","6","7","8","9","0","E","T"]
        ],
        BellType.hand : [
        4: ["5","6","7","8"],
        6: ["3","4","5","6","7","8"],
        8: ["5","6","7","8","9","0","E","T"],
        10: ["3","4","5","6","7","8","9","0","E","T"],
        12: ["1","2","3","4","5","6","7","8","9","0","E","T"]
        ]
    ]
    
    var stroke:Stroke {
        didSet {
            print("posting")
            NotificationCenter.default.post(name: NSNotification.Name.strokeChanged, object: nil, userInfo: ["number":self.number, "stroke": self.stroke, "person": self.person, "side":self.side])
        }
    }
    var number:Int
    var person:String {
        didSet {
            print("posting")
            NotificationCenter.default.post(name: NSNotification.Name.assignmentChanged, object: nil, userInfo: ["number":self.number, "person": self.person, "stroke": self.stroke, "side":self.side])
        }
    }
    
    init(number:Int, stroke:Stroke = .handstoke, person:String = "", side:Side) {
        self.side = side
        self.number = number
        self.stroke = stroke
        self.person = person
    }
}

extension NSNotification.Name {
    public static let strokeChanged = NSNotification.Name(rawValue: "strokeChanged")
    public static let assignmentChanged = NSNotification.Name(rawValue: "assignmentChanged")

}
