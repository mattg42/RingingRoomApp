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

enum BellType: String, CaseIterable {
    case tower = "Tower", hand = "Hand"
}


class BellCircle: ObservableObject {

    @Published var isLargeSize = false
    
    @Published var towerControlsViewSelection = 1 {
        didSet {
            ChatManager.shared.canSeeMessages = towerControlsViewSelection == 2
        }
    }
    
    @Published var showingTowerControls = false
            
    
    var serverAddress = ""
    
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
    
    @Published var isHost = false
    @Published var hostModeEnabled = false
    var hostModePermitted = false
    
    var audioController = AudioController()
    
    var size = 0
    
    var perspective = 1 {
        didSet {
            changedPerspective = true
            print("from perspective")
//            getNewPositions(radius: radius, centre: centre)
        }
    }
    
    var changedPerspective = false
    
    var bellType:BellType = BellType.hand
    
    var centre = CGPoint(x: 0, y: 0) {
        didSet(oldCentre) {
            print("centre changed")
        }
    }
    
    var timer = Timer()
    var counter = 0.000
    
    var sortUsersTimer = Timer()
    var updateAssignmentsTimer = Timer()
    
    var oldScreenSize = CGSize(width: 0, height: 0)
    var oldBellCircleSize = 0
    
    var imageSize = 0.0
    var radius = 0.0
    
    var additionalSizes = true
    
    var towerSizes:[Int] {
        additionalSizes ? [4, 5, 6, 8, 10, 12, 14, 16] : [4, 6, 8, 10, 12]
    }
    
    var needsTowerInfo = false
    
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
    var usersBuffer = [Ringer]()
    
    var bellPositions = [CGPoint]()
    
    @Published var bellStates = [Bool]()
        
    var halfMuffled = false
    
    var autoRotate = UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
    
    @Published var bellMode = BellMode.ring
    
    @Published var keyboardShowing = false
    
    var gotHostMode = true
    var hostModeFromSelf = false
    var hostModeFromServer = false
    
    var joinedTowers = [Int]()
    
    private init() {
        let session = AVAudioSession.sharedInstance()
    
        do {
            try session.setCategory(.playback, mode: AVAudioSession.Mode.voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])

            //            try session.setCategory(.playback, mode: AVAudioSession.Mode.voiceChat)
//            try session.setCategory(.playback, mode: AVAudioSession.Mode.voiceChat, options: .interruptSpokenAudioAndMixWithOthers)
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
        
    var oldRadius:CGFloat = 0
    var oldCentre:CGPoint = CGPoint(x: 0, y: 0)
    var oldSize = 0
    var oldPerspective = 0
    var oldBellType = BellType.tower
    
    func getNewPositions(radius:CGFloat, centre:CGPoint) -> [CGPoint] {
//        print(radius, oldRadius)
        if radius.truncate(places: 5) == oldRadius {
//            print("passed radius")
//            print(centre, oldCentre)
            if centre.truncate(places: 5) == oldCentre {
//                print("passed centre")

                if size == oldSize {
//                    print("passed size")

                    if bellType == oldBellType {
//                        print("passed bellType")

                        if perspective == oldPerspective {
//                            print("passed perspective")

                            return bellPositions
                        }
                    }
                }
            }
        }
        
        print("new positions")
        let angleIncrement:Double = 360/Double(size)
        let startAngle:Double = 360 - (-angleIncrement/2 + angleIncrement*Double(perspective))
        
        var newPositions = [CGPoint]()
        
//        print("calculating")
        
        var currentAngle = startAngle
        
        for _ in 0..<size {
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians)) * radius
            var y = CGFloat(cos(Angle(degrees: currentAngle).radians)) * radius
            
            if size % 4 == 0 {
                if ((90.0)...(270.0)).contains(currentAngle) {
                    y -= 7.5
                } else {
                    y += 7.5
                }
            }
            
            let bellPos = CGPoint(x: centre.x + x, y: centre.y + y)

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
        oldRadius = radius.truncate(places: 5)
        oldCentre = centre.truncate(places: 5)
        oldSize = size
        oldPerspective = perspective
        oldBellType = bellType
        print(size, bellPositions.count)
//        print(centre)
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
        
        guard var fileName = BellCircle.sounds[bellType]?[size]?[number-1] else { return }
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
        if AppController.shared.state != .ringing && !SocketIOManager.shared.refresh {
            SocketIOManager.shared.refresh = false
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
                print("from size")
                perspective = (assignments.allIndicesOfRingerForID(User.shared.ringerID).first ?? 0) + 1
            }
            if newSize != size {
                bellStates = Array(repeating: true, count: newSize)
                size = newSize
            }
        }
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
    
    func ringBell(_ number:Int) {
            SocketIOManager.shared.socket?.emit("c_bell_rung", ["bell": number, "stroke": (bellStates[number - 1]), "tower_id": towerID])
    }
    
    @objc func updateAssignments() {
        print("updating assignments")
        for (index, assignment) in assignmentsBuffer.enumerated() {
            if assignment != nil {
                assignments[index] = assignment!
            }
        }
        if autoRotate {

            perspective = (assignments.allIndicesOfRingerForID(User.shared.ringerID).first ?? 0) + 1
        }
        assignmentsBuffer = Array(repeating: nil, count: size)
        print(assignments.ringers)
        if AppController.shared.state != .ringing {
            if !gotAssignments {
                print("from assignments")
                SocketIOManager.shared.setups += 1
                gotAssignments = true
            }
        }
        sortUserArray()
    }
    
    var gotAssignments = false
    
    var fillIn = false
    
    func assign(_ id:Int, to bell: Int) {
        print("assign", id, bell)
        if let ringer = ringerForID(id) {
            if (1...size).contains(bell) {
                assignmentsBuffer[bell - 1] = ringer
            }
//            updateAssignments()
            if fillIn {
                if assignmentsBuffer.filter { ringer in return ringer?.userID ?? 0 != Ringer.blank.userID }.count + (size - assignments.allIndicesOfRingerForID(Ringer.blank.userID).count) == size {
                    updateAssignments()
                    fillIn = false
                }
            } else {
                updateAssignments()
            }
//            updateAssignmentsTimer.invalidate()
//            updateAssignmentsTimer = Timer.scheduledTimer(timeInterval: 0.07, target: self, selector: #selector(updateAssignments), userInfo: nil, repeats: false)
        }
    }
    
    func unAssign(at bell:Int) {
        print("un assign")
        print(User.shared.ringerID)
        if (1...size).contains(bell) {
            if assignments[bell - 1] != Ringer.blank {
                assignmentsBuffer[bell - 1] = Ringer.blank
    //            updateAssignments()
            }
            updateAssignmentsTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateAssignments), userInfo: nil, repeats: false)
        }
    }
    
    func newUserlist(_ newUsers:[[String:Any]]) {
        users = [Ringer]()
        assignments = [Ringer]()
        print(self.users.ringers)
        print(newUsers)
        usersBuffer = [Ringer]()
        for newRinger in newUsers {
            let ringer = Ringer.blank
            ringer.userID = newRinger["user_id"] as! Int
            ringer.name = newRinger["username"] as! String
            print(ringer.userID)
            newUser(id: ringer.userID, name: ringer.name)
            print(self.users.ringers)
        }
        
        print(self.users.ringers)
    }
    
    func newUser(id:Int, name:String) {
        if !users.containsRingerForID(id) {
            users.append(Ringer(name: name, id: id))
            print(self.users.ringers)
            sortUserArray()
        }
    }
    
    func userLeft(id:Int) {
        for i in assignments.allIndicesOfRingerForID(id) ?? [Int]() {
            unAssign(at: i+1)
        }
        users.removeRingerForID(id)
        sortUserArray()
    }
    
    func newAudio(_ audio:String) {
        for type in BellType.allCases {
            if type.rawValue == audio {
                objectWillChange.send()
                bellType = type
            }
        }
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
        print(self.users.ringers)

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
    
    func allIndicesOfRingerForID(_ id:Int) -> [Int] {
        var output = [Int]()
        if self.containsRingerForID(id) {
            for (index, ringer) in self.enumerated() {
                if ringer.userID == id {
                    output.append(index)
                }
            }
            return output
        } else {
            return [Int]()
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

extension CGPoint {
    func truncate(places : Int) -> CGPoint {
        return CGPoint(x: self.x.truncate(places: places), y: self.y.truncate(places: places))
    }
}

extension CGFloat {
    func truncate(places : Int) -> CGFloat {
        return CGFloat(floor(pow(10.0, CGFloat(places)) * self)/pow(10.0, CGFloat(places)))
    }
}

extension CGSize {
    func truncate(places : Int) -> CGSize {
        return CGSize(width: self.width.truncate(places: places), height: self.height.truncate(places: places))
    }
}
