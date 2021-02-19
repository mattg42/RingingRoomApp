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
    
    @Published var towerControlsViewSelection = 1 {
        didSet {
            ChatManager.shared.canSeeMessages = towerControlsViewSelection == 2
        }
    }
    
    @Published var showingTowerControls = false
    
    @Published var ringingroomIsPresented = false
    
    static var current = BellCircle()
    
    static var sounds = [
        BellType.tower : [
            4: ["5","6","7","8"],
            5: ["4","5","6","7","8"],
            6: ["3","4","5","6","7","8"],
            8: ["1","2sharp","3","4","5","6","7","8"],
            10: ["3","4","5","6","7","8","9","0","E","T"],
            12: ["1","2","3","4","5","6","7","8","9","0","E","T"],
            14: ["e3", "e4", "1","2","3","4","5","6","7","8","9","0","E","T"],
            16: ["e1","e2","e3","e4","1","2","3","4","5","6","7","8","9","0","E","T"]
        ],
        BellType.hand : [
            4: ["9","0","E","T"],
            5: ["8","9","0","E","T"],
            6: ["7", "8", "9", "0", "E", "T"],
            8: ["5", "6", "7", "8", "9", "0", "E", "T"],
            10: ["3", "4", "5", "6", "7", "8", "9", "0", "E", "T"],
            12: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "E", "T"],
            14: ["3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"],
            16: ["1", "2", "3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"],
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
            changedPerspective = true
            print("from perspective")
//            getNewPositions(radius: radius, center: center)
        }
    }
    
    var changedPerspective = false
    
    var bellType:BellType = BellType.hand
    
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
    
    var oldScreenSize = CGSize(width: 0, height: 0)
    var oldBellCircleSize = 0
    
    var imageSize = 0.0
    var radius = 0.0
    
    
    var gotBellPositions = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    var users = [Ringer]()
    
    var currentCall = ""
    var callTimer = Timer()
    var callTextOpacity = 0.0
    
    var assignments = [Ringer]()
    
    var assignmentsBuffer = [Ringer?]()
    
    var bellPositions = [CGPoint]()
    
    var bellStates = [Bool]()
        
    var halfMuffled = false
    
    var autoRotate = UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
    
    @Published var bellMode = BellMode.ring
    
    @Published var keyboardShowing = false
    
    init() {
        let session = AVAudioSession()
        do {
            try session.setCategory(.playback, mode: AVAudioSession.Mode.default, options: [AVAudioSession.CategoryOptions.mixWithOthers])
            try session.setPreferredIOBufferDuration(0.002)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audio error")
        }
//        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
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
    
    var newImages = false
    
    var oldRadius:CGFloat = 0
    var oldCenter:CGPoint = CGPoint(x: 0, y: 0)
    var oldSize = 0
    var oldPerpespective = 0
    
    func getNewPositions(radius:CGFloat, center:CGPoint) -> [CGPoint] {
        if radius == oldRadius {
            if center == oldCenter {
                if size == oldSize {
                    if perspective == oldPerpespective {
                        return bellPositions
                    }
                }
            }
        }
        let angleIncrement:Double = 360/Double(size)
        let startAngle:Double = 360 - (-angleIncrement/2 + angleIncrement*Double(perspective))
        
        var newPositions = [CGPoint]()
        
        print("calculating")
        
        var currentAngle = startAngle
        
        for _ in 0..<size {
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians)) * radius
            var y = CGFloat(cos(Angle(degrees: currentAngle).radians)) * radius
            
            if size % 4 == 0 {
                print("edited")
                if ((90.0)...(270.0)).contains(currentAngle) {
                    y -= 7.5
                } else {
                    y += 7.5
                }
            }
            
            let bellPos = CGPoint(x: center.x + x, y: center.y + y)

            newPositions.append(bellPos)
            currentAngle += angleIncrement
            if currentAngle > 360 {
                currentAngle -= 360
            }
        }
        
        if bellPositions.count != newPositions.count {
            objectWillChange.send()
        }
        bellPositions = newPositions
        oldRadius = radius
        oldCenter = center
        oldSize = size
        oldPerpespective = perspective
        print(size, bellPositions.count)
//        print(center)
//        for pos in newPositions {
//            print(pos.pos)
//        }
//        print("got new positions")
        objectWillChange.send()
        if !gotBellPositions {
            gotBellPositions = true
        }

        return newPositions
    }
    
    func bellRang(number:Int, bellStates:[Bool]) {
        var fileName = BellCircle.sounds[bellType]![size]![number-1]
        fileName.prefix(String(bellType.rawValue.first!))
        if bellType == .tower {
            if halfMuffled {
                if bellStates[number-1] {
                    fileName += "-muf"
                }
            }
        }
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
        if SocketIOManager.shared.ignoreSetup == false {
            assignments = Array(repeating: Ringer.blank, count: newSize)
            assignmentsBuffer = Array(repeating: nil, count: newSize)
            bellStates = Array(repeating: true, count: newSize)
            size = newSize
        } else {
            if newSize > size {
                for _ in 0..<(newSize - assignments.count) {
                    assignments.append(Ringer.blank)
                    assignmentsBuffer.append(nil)
                }
            } else if newSize < size {
                assignments = Array(assignments[..<newSize])
                assignmentsBuffer = Array(assignmentsBuffer[..<newSize])
            }
            if !autoRotate {
                if perspective > newSize {
                    perspective = 1
                }
            } else {
                perspective = (assignments.allIndecesOfRingerForID(User.shared.ringerID)?.first ?? 0) + 1
            }
            bellStates = Array(repeating: true, count: newSize)
            size = newSize
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
        if let ringer = ringerForID(id) {
            assignmentsBuffer[bell-1] = ringer
            sortTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateAssignments), userInfo: nil, repeats: false)
            if autoRotate {
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
        }
    }
    
    func ringBell(_ number:Int) {
            SocketIOManager.shared.socket?.emit("c_bell_rung", ["bell": number, "stroke": (bellStates[number - 1]), "tower_id": towerID])
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
            assignmentsBuffer[bell - 1] = Ringer.blank
            sortTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateAssignments), userInfo: nil, repeats: false)
        if changePerspective && autoRotate {
            var tempAssignments = assignments
            for (index, assignment) in assignmentsBuffer.enumerated() {
                if assignment != nil {
                    tempAssignments[index] = assignment!
                }
            }
            perspective = (tempAssignments.allIndecesOfRingerForID(User.shared.ringerID)?.first ?? 0) + 1
        }
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
                newImages = true
            }
        }
    }
    
    func sortUsers() {
//        sortTimer.invalidate()
        sortTimer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(sortUserArray), userInfo: nil, repeats: false)
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
        if !SocketIOManager.shared.ignoreSetup {
            SocketIOManager.shared.setups += 1
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
