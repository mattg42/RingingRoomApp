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
    case tower = "Tower", hand = "Hand"
}

enum Stroke:Bool {
    case handstroke = true, backstroke = false
    
    mutating func toggle() {
        switch self {
            case .handstroke:
                self = .backstroke
            case .backstroke:
                self = .handstroke
        }
    }
}

class BellCircle: ObservableObject {
    var towerID:Int = 0
    
    @Published var users = [Ringer]()
    
    static var current = BellCircle()
    
    @Published var bellPositions = [CGPoint]()
    
    var baseRadius:CGFloat = 0
            
    var radius:CGFloat {
        get {
            var returnValue = self.baseRadius
            returnValue -= 20
            if bellType == .hand {
                switch self.size {
                case 6:
                    returnValue -= 20
                case 10:
                    returnValue -= 10
                case 12:
                    returnValue -= 5
                default:
                    returnValue -= 0
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
    
    @Published var perspective = 4 {
        didSet {
            self.bellPositions = newBellPositions()
        }
    }
    
    @Published var assignments:[Ringer] {
        didSet {
            if assignments.count == size {
                var newPerspective = 1
                print(self.assignments.count)
                for i in 0..<self.size {
                    if self.assignments[i].name == User.shared.name {
                        newPerspective = i+1
                        break
                    }
                }
                self.perspective = newPerspective
            }
            sortUsers()
        }
    }
    
    @Published var hostModeEnabled = false
    
    @Published var bells:[Bell]
    
    @Published var bellStates:[Bool]
    
    @Published var bellType:BellType {
        didSet {
            print("from belltype")
            self.bellPositions = newBellPositions()
        }
    }
    
    var size:Int = 0 {
        didSet {
            var newBells = [Bell]()
            for i in 1...size {
                newBells.append(Bell(number: i, side: ((2...size/2).contains(i)) ? .left : .right))
            }
            bells = newBells
            if oldValue > size {
                assignments = Array(assignments[0..<size])
                    print("new array size: ", assignments.count)
            } else if size > oldValue {
                for _ in 0..<size-oldValue {
                    print("added empty assignment")
                    assignments.append(Ringer(name: "", id: 0))
                }
            }
            bellStates = Array.init(repeating: true, count: self.size)
            self.bellPositions = newBellPositions()
        }
    }
    
    init(number:Int = 0) {
        self.size = number
        bells = [Bell]()
        assignments = [Ringer]()
        bellStates = [Bool]()
        //change to .tower to test tower bells
        bellType = .hand
        if number > 0 {
            for i in 1...number {
                assignments.append(Ringer(name: "", id: 0))
                bells.append(Bell(number: i, side: ((2...size/2).contains(i)) ? .left : .right))
                bellStates.append(true)
            }
        }
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
    
    func setAssignment(user:Ringer, to bell:Int) {
        var newAssignments = self.assignments
        newAssignments[bell-1] = user
        self.assignments = newAssignments
        print(self.assignments.names)
    }
    
    func sortUsers() {
        var newUsers = [Ringer]()
    
        for ringer in assignments {
            if ringer.name != "" {
                if !newUsers.containsRingerForID(ringer.userID) {
                    newUsers.append(ringer)
                }
            }
        }
        users.sort { (first: Ringer, second:Ringer) -> Bool in
            return first.name < second.name
        }
        for ringer in users {
            if !newUsers.containsRingerForID(ringer.userID) {
                newUsers.append(ringer)
            }
        }
        users = newUsers
    }
    

    
    func ringerForId(_ id:Int) -> Ringer? {
        for ringer in users {
            if ringer.userID == id {
                return ringer
            }
        }
        return nil
    }
    
    func ringerForName(_ name:String) -> Ringer? {
        for ringer in users {
            if ringer.name == name {
                return ringer
            }
        }
        return nil
    }
    
    func removeRinger(for id:Int) {
        users.removeRingerForID(id)
        for (index, ringer) in BellCircle.current.assignments.enumerated() {
            if ringer.userID == id {
               setAssignment(user: Ringer(name: "", id: 0), to: index+1)
            }
        }
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
    
    var number:Int
    
    init(number:Int, side:Side) {
        self.side = side
        self.number = number
    }
}

extension NSNotification.Name {
    public static let strokeChanged = NSNotification.Name(rawValue: "strokeChanged")
    public static let sizeChanged = NSNotification.Name(rawValue: "sizeChanged")
    public static let loggedOut = NSNotification.Name(rawValue: "loggedOut")
}

extension Array where Element == Ringer {
    func containsRingerForID(_ id:Int) -> Bool {
        var isContained = false
        for ringer in self {
            if ringer.userID == id {
                isContained = true
            }
        }
        return isContained
    }
    
    func containsRingerForName(_ name:String) -> Bool {
        var isContained = false
        for ringer in self {
            if ringer.name == name {
                isContained = true
            }
        }
        return isContained
    }
    
    func allIndecesForID(_ id:Int) -> [Int]? {
        //  init outputArray
        print(self.names)
        print("getting indeces for \(id)")
        var outputArray = [Int]()
        //  step through array, comparing the element at each index with the input element
        for (index, element) in self.enumerated() {
            //  if they are the same, add index to output array
            if element.userID == id {
                outputArray.append(index)
            }
        }
        // return output array or nil if array is empty
        print(outputArray)
        return (outputArray.count > 0) ? outputArray : nil
    }
    
    mutating func removeRingerForID(_ id:Int) {
        for (index, ringer) in self.enumerated() {
            if ringer.userID == id {
                self.remove(at: index)
            }
        }
    }
    
    var names:[String] {
        var output = [String]()
        for ringer in self {
            output.append(ringer.name)
        }
        return output
    }
    
    var IDs:[Int] {
        var output = [Int]()
        for ringer in self {
            output.append(ringer.userID)
        }
        return output
    }
    
}
