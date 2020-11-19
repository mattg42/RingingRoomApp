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
import AVKit
import AVFoundation

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
    
    var size = 0
    
    var perspective = 1 {
        didSet {
            print("from perspective")
            getNewPositions(radius: radius, center: center)
        }
    }
    
    var setupComplete = ["gotUserList":false, "gotSize":false, "gotAudioType":false, "gotHostMode":false, "gotUserEntered":false, "gotBellStates":false, "gotAssignments":false]
    
    static let setup = Notification.Name("setup")
    
    let setupPublisher = NotificationCenter.default.publisher(for: BellCircle.setup)
    
    var bellType:BellType = BellType.hand
    
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
    
    var sortTimer = Timer()
    
    var radius:CGFloat {
        get {
            var returnValue = self.baseRadius
            returnValue -= 25
            if bellType == .hand {
                switch self.size {
                case 6:
                    returnValue -= 20
                case 8:
                    returnValue -= 5
                case 10:
                    returnValue -= 10
                case 12:
                    returnValue -= 5
                default:
                    returnValue -= 0
                }
            } else {
                switch self.size {
                case 6:
                    returnValue -= 20
                case 8:
                    returnValue -= 10
                case 10:
                    returnValue -= 5
//                case 12:
//                    returnValue -= 5
                default:
                    returnValue -= 0
                }
            }
            
            return returnValue
        }
    }
    
    var gotBellPositions = false
    
    var users = [Ringer]()
    
    var currentCall = ""
    var callTimer = Timer()
    var callTextOpacity = 0.0
    
    var assignments = [Ringer]()
    
    var assignmentsBuffer = [Ringer?]()
    
    var bellPositions = [BellPosition]()
    
    var bellStates = [Bool]()
        
    var halfMuffled = false
    
    @Published var keyboardShowing = false
    
    init() {
        let session = AVAudioSession()
        do {
            try session.setCategory(.playback)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audio error")
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyBoardWillShow(notification:Notification) {
        withAnimation {
            keyboardShowing = true
        }
    }
    
    @objc func keyBoardWillHide(notification:Notification) {
        withAnimation {
            keyboardShowing = false
        }
    }
    
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
        fileName.prefix(String(bellType.rawValue.first!))
        print(fileName)
        if bellType == .tower {
            if halfMuffled {
                if bellStates[number-1] {
                    fileName += "-muf"
                }
            }
        }
        print(fileName)
        audioController.play(fileName)
        objectWillChange.send()
        self.bellStates = bellStates
    }
    
    func callMade(_ call:String) {
        audioController.play("C" + call)
        currentCall = call
        callTextOpacity  = 1
        objectWillChange.send()
        callTimer.invalidate()
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
            withAnimation {
                self.objectWillChange.send()
                self.callTextOpacity = 0
            }
        })
    }
    
    func newSize(_ newSize:Int) {
        print("new size from socketio")
        if setupComplete["gotSize"] == false {
            assignments = Array(repeating: Ringer.blank, count: newSize)
            assignmentsBuffer = Array(repeating: nil, count: newSize)
            bellStates = Array(repeating: true, count: newSize)
            size = newSize
            getNewPositions(radius: radius, center: center)
        } else {
            if newSize > size {
                for _ in 0..<(newSize - assignments.count) {
                    assignments.append(Ringer.blank)
                    assignmentsBuffer.append(nil)
                }
            } else if newSize < size {
                assignments = Array(assignments[..<newSize])
                assignmentsBuffer = Array(assignmentsBuffer[..<newSize])
            } else {
                
            }
            bellStates = Array(repeating: true, count: newSize)
            size = newSize
            getNewPositions(radius: radius, center: center)
        }
        print("assignments", assignments)
        objectWillChange.send()
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
        assignmentsBuffer[bell-1] = ringer
        sortTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateAssignments), userInfo: nil, repeats: false)
        if id == User.shared.ringerID {
            var tempAssignments = assignments
            for (index, assignment) in assignmentsBuffer.enumerated() {
                if assignment != nil {
                    tempAssignments[index] = assignment!
                }
            }
            objectWillChange.send()
            perspective = (tempAssignments.allIndecesOfRingerForID(User.shared.ringerID)?.first ?? 0) + 1
        }
    }
    
    func ringBell(_ number:Int) {
            SocketIOManager.shared.socket.emit("c_bell_rung", ["bell": number, "stroke": (bellStates[number - 1]), "tower_id": towerID])
//        bellCircle.timer.tolerance = 0
//        bellCircle.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true, block: { _ in
//            bellCircle.counter += 1
//        })
    }
    
    @objc func updateAssignments() {
        for (index, assignment) in assignmentsBuffer.enumerated() {
            if assignment != nil {
                assignments[index] = assignment!
            }
        }
        assignmentsBuffer = Array(repeating: nil, count: size)
        sortUserArray()
    }
    
    
    func unAssign(at bell:Int) {
        var changePerspective = false
        if assignments[bell - 1].userID == User.shared.ringerID {
            changePerspective = true
        }
//        if assignments[bell - 1] != Ringer.blank {
            assignmentsBuffer[bell - 1] = Ringer.blank
            sortTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateAssignments), userInfo: nil, repeats: false)
        if changePerspective {
            var tempAssignments = assignments
            for (index, assignment) in assignmentsBuffer.enumerated() {
                if assignment != nil {
                    tempAssignments[index] = assignment!
                }
            }
            perspective = (tempAssignments.allIndecesOfRingerForID(User.shared.ringerID)?.first ?? 0) + 1
        }
//        }
    }
    
    func newUserlist(_ newUsers:[[String:Any]]) {
        users = [Ringer]()
        
        for newRinger in newUsers {
            let ringer = Ringer.blank
            ringer.userID = newRinger["user_id"] as! Int
            ringer.name = newRinger["username"] as! String
            print(ringer.userID)
            if !users.containsRingerForID(ringer.userID) {
                users.append(ringer)
                print(users.ringers)
            }
        }
        objectWillChange.send()
    }
    
    func newUser(id:Int, name:String) {
        if !users.containsRingerForID(id) {
            users.append(Ringer(name: name, id: id))
            sortUsers()
        }
    }
    
    func userLeft(id:Int) {
        users.removeRingerForID(id)
        sortUsers()
    }
    
    func newAudio(_ audio:String) {
        for type in BellType.allCases {
            if type.rawValue == audio {
                objectWillChange.send()
                bellType = type
            }
        }
    }
    
    func sortUsers() {
//        sortTimer.invalidate()
        sortTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(sortUserArray), userInfo: nil, repeats: false)
    }
    
    @objc func sortUserArray() {
//        print(users.ringers)
        var tempUsers = users
        var newUsers = [Ringer]()
        for assignment in assignments {
            if assignment.userID != 0 {
                if !newUsers.containsRingerForID(assignment.userID) {
                    tempUsers.removeRingerForID(assignment.userID)
                    newUsers.append(assignment)
                }                                                                                                                                                                                                                                                                                
            }
        }
        tempUsers.sortAlphabetically()
        newUsers += tempUsers
//        print(newUsers.ringers)
        objectWillChange.send()
        users = newUsers
        if !setupComplete["gotAssignments"]! {
            setupComplete["gotAssignments"] = true
            NotificationCenter.default.post(name: BellCircle.setup, object: nil )
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
    
    mutating func sortAlphabetically() {
        self.sort { (first, second) -> Bool in
            first.name.lowercased() < second.name.lowercased()
        }
    }
    
    var ringers:[[String:Int]] {
        get {
            var desc = [[String:Int]]()
            for ringer in self {
                desc.append([ringer.name:ringer.userID])
            }
            return desc
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
