//
//  RingingRoomService.swift
//  NewRingingRoom
//
//  Created by Matthew on 15/07/2022.
//

import Foundation
import Combine

extension Double {
    func truncate(places: Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

enum TowerControlsViewSelection {
    case users, chat
}

enum BellType: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case tower = "Tower", hand = "Hand"
    
    var sounds: [Int: [String]] {
        switch self {
        case .tower:
            return [
                4: ["5","6","7","8"],
                5: ["4","5","6","7","8"],
                6: ["3","4","5","6","7","8"],
                8: ["1","2sharp","3","4","5","6","7","8"],
                10: ["3","4","5","6","7","8","9","0","E","T"],
                12: ["1","2","3","4","5","6","7","8","9","0","E","T"],
                14: ["e3", "e4", "1","2","3","4","5","6","7","8","9","0","E","T"],
                16: ["e1","e2","e3","e4","1","2","3","4","5","6","7","8","9","0","E","T"]
            ]
        case .hand:
            return [
                4: ["9","0","E","T"],
                5: ["8","9","0","E","T"],
                6: ["7", "8", "9", "0", "E", "T"],
                8: ["5", "6", "7", "8", "9", "0", "E", "T"],
                10: ["3", "4", "5", "6", "7", "8", "9", "0", "E", "T"],
                12: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "E", "T"],
                14: ["3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"],
                16: ["1", "2", "3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"],
            ]
        }
    }
}

enum BellStroke {
    case hand, back
    
    init(bool: Bool) {
        if bool { self = .hand }
        else { self = .back }
    }
    
    var boolValue: Bool {
        switch self {
        case .hand:
            return true
        case .back:
            return false
        }
    }
}

enum BellMode {
    case ring, rotate
}

class RingingRoomViewModel: ObservableObject {
    
    init(socketIOService: SocketIOService, towerInfo: TowerInfo, apiService: APIService, user: User) {
        self.socketIOService = socketIOService
        self.towerInfo = towerInfo
        self.apiService = apiService
        self.user = user

        self.socketIOService.delegate = self
    }
    
    func ringBell(number: Int) {
        send(event: "c_bell_rung", with: ["bell": number, "stroke": bellStates[number - 1].boolValue, "tower_id": towerInfo.towerID])
    }
    
    func makeCall(_ call: Call) {
        send(event: "c_call", with: ["call": call.string, "tower_id": towerInfo.towerID])
    }
    
    func connect() {
        socketIOService.connect { [weak self] in
            if let self {
                self.send(event: "c_join", with: ["tower_id": self.towerInfo.towerID, "user_token": self.apiService.token, "anonymous_user": false])
                self.audioService.starling.prepareToStart()
            }
        }
    }
    
    @Published var ringer: Ringer?
    
    let apiService: APIService
    let user: User
    
    private let socketIOService: SocketIOService
    let towerInfo: TowerInfo
    
    func send(event: String, with data: [String: Any]) {
        socketIOService.send(event: event, with: data)
    }
    
    func disconnect() {
        socketIOService.disconnect()
    }
    
    @Published var perspective = 1
    
    @Published var size = 0
    @Published var bellType = BellType.tower
    @Published var users = [Int: Ringer]()
    @Published var assignments = [Int?]()
    @Published var bellStates = [BellStroke]()
    @Published var hostMode = false
    
    let callPublisher = PassthroughSubject<String, Never>()
    
    private let audioService = AudioService()
    
    func changeVolume(to volume: Float) {
        audioService.starling.changeVolume(to: volume)
    }
    
//    func sortUsers() {
//        print(users)
//        var tempUsers = users
//        var newUsers = [Ringer]()
//        for assignment in assignments {
//            if let assignment {
//                if !newUsers.contains(assignment) {
//                    tempUsers.remove(assignment)
//                    newUsers.append(assignment)
//                }
//            }
//        }
//        tempUsers.sortAlphabetically()
//        newUsers += tempUsers
//        print(newUsers)
//        users = newUsers
//    }
    
    @Published var isLargeSize = false
    
    @Published var towerControlsViewSelection = TowerControlsViewSelection.users
    
    @Published var newMessages = 0
    @Published var messages = [Message]()
    
    var canSeeMessages: Bool {
        towerControlsViewSelection == .chat && showingTowerControls
    }
    
    @Published var showingTowerControls = false
    
    var sortUsersTimer = Timer()
    var updateAssignmentsTimer = Timer()
    
    var assignmentsBuffer = [Ringer?]()
    var usersBuffer = [Ringer]()
    
    var autoRotate = UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
    
    @Published var bellMode = BellMode.ring
    
//    @objc func updateAssignments() {
//        print("updating assignments")
//        for (index, assignment) in assignmentsBuffer.enumerated() {
//            if assignment != nil {
//                assignments[index] = assignment!
//            }
//        }
//
//
//
//        assignmentsBuffer = Array(repeating: nil, count: size)
//    }
}

protocol SocketIODelegate: AnyObject {
    func sizeDidChange(to newSize: Int)
    func userDidEnter(_ ringer: Ringer)
    func userDidLeave(_ ringer: Ringer)
    func didReceiveGlobalState(_ globalState: [BellStroke])
    func didReceiveUserList(_ userList: [Int: Ringer])
    func bellDidRing(number: Int, globalState: [BellStroke])
    func didAssign(ringerID: Int, to bell: Int)
    func audioDidChange(to: BellType)
    func hostModeDidChange(to: Bool)
    func didReceiveMessage(_ message: Message)
    func didReceiveCall(_ call: String)
}

extension RingingRoomViewModel: SocketIODelegate {
    func userDidEnter(_ ringer: Ringer) {
        if self.ringer == nil {
            self.ringer = ringer
            send(event: "c_request_global_state", with: ["tower_id": towerInfo.towerID])
        }
        
        guard !users.keys.contains(ringer.ringerID) else { return }
        users[ringer.ringerID] = ringer
    }
    
    func userDidLeave(_ ringer: Ringer) {
        users.removeValue(forKey: ringer.ringerID)
        
        while assignments.contains(ringer.ringerID) {
            if let index = assignments.firstIndex(of: ringer.ringerID) {
                assignments[index] = nil
            }
        }
    }
    
    func didReceiveGlobalState(_ globalState: [BellStroke]) {
        if size == 0 {
            sizeDidChange(to: globalState.count)
        }
        bellStates = globalState
    }
    
    func didReceiveUserList(_ userList: [Int: Ringer]) {
        users = userList
    }
    
    func bellDidRing(number: Int, globalState: [BellStroke]) {
        bellStates = globalState
        
        guard var fileName = bellType.sounds[size]?[number - 1] else { return }
        
        if bellType == .tower {
            fileName = "T" + fileName
            switch towerInfo.muffled {
            case .toll:
                if (number != size) || globalState[number - 1] == .back {
                    fileName += "-muf"
                }
            case .full:
                fileName += "-muf"
            case .half:
                if bellStates[number-1] == .hand {
                    fileName += "-muf"
                }
            default:
                break
            }
        } else {
            fileName = "H" + fileName
        }
        
        audioService.play(fileName)
    }
    
    func didAssign(ringerID: Int, to bell: Int) {
        if users.keys.contains(ringerID) {
            assignments[bell - 1] = ringerID
        } else if ringerID == 0 {
            assignments[bell - 1] = nil
        } else {
            AlertHandler.presentAlert(title: "Error", message: "The users list is out of sync. Please leave the tower and rejoin.", dismiss: .cancel(title: "OK", action: nil))
        }
    }
    
    func audioDidChange(to newBellType: BellType) {
        bellType = newBellType
    }
    
    func hostModeDidChange(to newMode: Bool) {
        hostMode = newMode
    }
    
    func sizeDidChange(to newSize: Int) {
        
        if newSize > size {
            for _ in 1...(newSize - size) {
                assignments.append(nil)
            }
        } else {
            assignments = Array(assignments[..<newSize])
        }
        
        bellStates = Array(repeating: .hand, count: newSize)
        size = newSize
    }
    
    func didReceiveMessage(_ message: Message) {
        if !canSeeMessages {
            newMessages += 1
        }
        messages.append(message)
    }
    
    func didReceiveCall(_ call: String) {
        audioService.play(call)
        
        callPublisher.send(call)
    }
}
