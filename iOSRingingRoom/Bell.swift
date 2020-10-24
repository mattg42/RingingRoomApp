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

enum BellType:String, CaseIterable {
    case tower = "Tower", hand = "Hand"
}


class BellCircle: ObservableObject {
    
    var ringingroomIsPresented = false
    
    static var current = BellCircle()
    
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
    
    var towerID = 0
    var towerName = ""
    
    var isHost = false
    var hostModeEnabled = false
    
    var audioController = AudioController()
    
    @Published var size = 0
    
    var perspective = 1 {
        didSet {
            print("from perspective")
            getNewPositions(radius: radius, center: center)
        }
    }
    
    var setupComplete = ["gotUserList":false, "gotSize":false, "gotAudioType":false, "gotHostMode":false, "gotUserEntered":false, "gotBellStates":false]
    
    static let setup = Notification.Name("setup")
    
    let setupPublisher = NotificationCenter.default.publisher(for: BellCircle.setup)
    
    @Published var bellType:BellType = BellType.hand
    
    var baseRadius:CGFloat = 0
    
    var center = CGPoint(x: 0, y: 0) {
        didSet(oldCenter) {
//            if BellCircle.current.ringingroomIsPresented {
//                if oldCenter != CGPoint(x: 0, y: 0) || oldCenter != center {
//                    center = oldCenter
//                }
//            }
            print("center changed")
        }
    }
    
    var timer = Timer()
    var counter = 0.000
    
    var radius:CGFloat {
        get {
            var returnValue = self.baseRadius
            returnValue -= 20
            if bellType == .hand {
                switch self.size {
                case 6:
                    returnValue -= 20
//                case 8:
//                    returnValue -= 10
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
    
    var gotBellPositions = false
    
    var users = [Ringer]()
    
    @Published var currentCall = ""
    var callTimer = Timer()
    @Published var callTextOpacity = 0.0
    
    var assignments = [Ringer]()
    
    @Published var bellPositions = [BellPosition]()
    
    @Published var bellStates = [Bool]()
    
    func getNewPositions(radius:CGFloat, center:CGPoint) {
        let angleIncrement:Double = 360/Double(size)
        let startAngle:Double = 360 - (-angleIncrement/2 + angleIncrement*Double(perspective))
        
        var newPositions = [BellPosition]()
        
        var currentAngle = startAngle
        for _ in 0..<size {
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians)) * radius
            let y = CGFloat(cos(Angle(degrees: currentAngle).radians)) * radius
            
            let bellPos = BellPosition(pos: CGPoint(x: center.x + x, y: center.y + y), side: .right)
            if (0..<180).contains(currentAngle) {
                bellPos.side = .left
            }
            newPositions.append(bellPos)
            currentAngle += angleIncrement
            if currentAngle > 360 {
                currentAngle -= 360
            }
        }
        
        print(center)
        for pos in newPositions {
            print(pos.pos)
        }
        print("got new positions")
        objectWillChange.send()
        bellPositions = newPositions
        gotBellPositions = true
    }
    
    func bellRang(number:Int, bellStates:[Bool]) {
        var fileName = BellCircle.sounds[bellType]![size]![number-1]
        fileName = fileName.prefix(String(bellType.rawValue.first!))
        audioController.play(fileName)
//        objectWillChange.send()
        self.bellStates = bellStates
    }
    
    func callMade(_ call:String) {
        audioController.play("C" + call)
        currentCall = call
        callTextOpacity  = 1
        callTimer.invalidate()
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
            withAnimation {
                self.callTextOpacity = 0
            }
        })
    }
    
    func newSize(_ newSize:Int) {
        print("new size from socketio")
        if setupComplete["gotSize"] == false {
            assignments = Array(repeating: Ringer.blank, count: newSize)
            bellStates = Array(repeating: true, count: newSize)
            size = newSize
            getNewPositions(radius: radius, center: center)
        } else {
        if newSize > size {
            for i in 0..<(newSize - assignments.count) {
                assignments.append(Ringer.blank)
            }
        } else if newSize < size {
            assignments = Array(assignments[..<newSize])
        }
            bellStates = Array(repeating: true, count: newSize)
            size = newSize
            getNewPositions(radius: radius, center: center)
        }
    }
    
    func ringerForID(_ id:Int) -> Ringer? {
        for ringer in users {
            if ringer.userID == id {
                return ringer
            }
        }
        return nil
    }
    
    func assign(_ id:Int, to bell: Int) {
        print("assign", id, bell)
        let ringer = ringerForID(id)!
        assignments[bell-1] = ringer
        objectWillChange.send()
        if ringer.userID == User.shared.ringerID {
            perspective = (assignments.allIndecesOfRingerForID(User.shared.ringerID)?.first ?? 0) + 1
        }
    }
    
    func unAssign(at bell:Int) {
        if assignments[bell - 1] != Ringer.blank {
            assignments[bell - 1] = Ringer.blank
            objectWillChange.send()
            perspective = (assignments.allIndecesOfRingerForID(User.shared.ringerID)?.first ?? 0) + 1
        }
    }
    
    func newUserlist(_ newUsers:[[String:Any]]) {
        for newRinger in newUsers {
            let ringer = Ringer.blank
            ringer.userID = newRinger["user_id"] as! Int
            ringer.name = newRinger["username"] as! String
            print(ringer.userID)
            if !users.containsRingerForID(ringer.userID) {
                objectWillChange.send()
                users.append(ringer)
            }
        }
    }
    
    func newUser(id:Int, name:String) {
        if !users.containsRingerForID(id) {
            objectWillChange.send()
            users.append(Ringer(name: name, id: id))
        }
    }
    
    func newAudio(_ audio:String) {
        for type in BellType.allCases {
            if type.rawValue == audio {
                bellType = type
            }
        }
    }
}

extension Ringer:Equatable {
    static func == (lhs: Ringer, rhs: Ringer) -> Bool {
        return
            lhs.name == rhs.name &&
            lhs.userID == rhs.userID
    }
}

extension Array where Element == Ringer {
    func containsRingerForID(_ id:Int) -> Bool {
        for ringer in self {
            if ringer.userID == id {
                return true
            }
        }
        return false
    }
    
    func indexOfRingerForID(_ id:Int) -> Int? {
        for (index, ringer) in self.enumerated() {
            if ringer.userID == id {
                return index
            }
        }
        return nil
    }
    
    mutating func removeRingerForID(_ id:Int) {
        for (index, ringer) in self.enumerated() {
            if ringer.userID == id {
                self.remove(at: index)
                return
            }
        }
    }
    
    func allIndecesOfRingerForID(_ id:Int) -> [Int]? {
        var output = [Int]()
        if self.containsRingerForID(id) {
            for (index, ringer) in self.enumerated() {
                if ringer.userID == id {
                    output.append(index)
                }
            }
            return output
        } else {
            return nil
        }
    }
}

class BellPosition {
    var pos:CGPoint
    var side:Side
    
    init(pos:CGPoint, side:Side) {
        self.pos = pos
        self.side = side
    }
}
