//
//  Bell.swift
//  iOSRingingRoom
//
//  Created by Matthew on 17/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

enum Side {
    case left, right
}

enum BellType:String {
    case tower = "tower", hand = "hand"
}

class BellCircle: ObservableObject {
    @Published var bellPositions = [CGPoint]()
    
    var baseRadius:CGFloat = 0
    
    var radius:CGFloat {
        get {
            var returnValue = self.baseRadius
            if bellType == .hand {
                switch self.size {
                case 6:
                    returnValue -= 40
                case 8:
                    returnValue -= 20
                case 10:
                    returnValue -= 30
                case 12:
                    returnValue -= 25
                default:
                    returnValue -= 20
                }
            }
            return returnValue
        }
    }
    
    @Published var center:CGPoint = CGPoint(x: 0, y: 0) {
        didSet {
            self.bellPositions = newBellPositions()
        }
    }
    
    var perspective = 1 {
        didSet {
            self.bellPositions = newBellPositions()
        }
    }
    
    @Published var bells:[Bell]
    
    @Published var bellType:BellType
    
    @Published var size:Int {
        didSet {
            var newBells = [Bell]()
            for i in 1...size {
                newBells.append(Bell(number: i, side: ((2...size/2).contains(i)) ? .left : .right))
            }
            bells = newBells
            
            self.bellPositions = newBellPositions()
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
    
    func newBellPositions() -> [CGPoint] {
        var newBellPoints = [CGPoint]()
        let bellAngle = CGFloat(360)/CGFloat(size)
        
        let baseline = (360 + bellAngle*0.5)
        
        var currentAngle:CGFloat = baseline - bellAngle*CGFloat(perspective)
        
        for i in 0..<size {
            print(currentAngle)
            let bellXOffset = -sin(currentAngle.radians()) * radius
            let bellYOffset = cos(currentAngle.radians()) * radius
            newBellPoints.append(CGPoint(x: center.x + bellXOffset, y: center.y + bellYOffset))
            
            if bells.count > 0 {
                bells[i].side = (180.0...360.0).contains(currentAngle) ? .left : .right
            }
            
            currentAngle += bellAngle
            
            if currentAngle > 360 {
                currentAngle -= 360
            }
            
        }
        return newBellPoints
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
        6: ["7","8","9","0","E","T"],
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
