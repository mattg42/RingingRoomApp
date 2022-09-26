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
    
    deinit {
        socketIOService.disconnect()
    }
    
    func ringBell(number: Int) {
        ringTime = .now
        send(.bellRung(bell: number, stroke: bellStates[number - 1].boolValue))
    }
    
    func makeCall(_ call: Call) {
        send(.call(call.string))
    }
    
    func connect() {
        socketIOService.connect { [weak self] in
            if let self {
                self.send(.join)
                self.audioService.starling.prepareToStart()
            }
        }
    }
    
    @Published var ringer: Ringer?
    
    let apiService: APIService
    let user: User
    
    private let socketIOService: SocketIOService
    let towerInfo: TowerInfo
    
    func send(_ event: ClientSocketEvent) {
        let payload = {
            switch event {
            case .join:
                return ["tower_id": towerInfo.towerID, "user_token": apiService.token, "anonymous_user": false]
            case .userLeft:
                return ["user_name": user.username, "tower_id": towerInfo.towerID, "user_token": apiService.token, "anonymous_user": false]
            case .requestGlobalState:
                return ["tower_id": towerInfo.towerID]
            case .bellRung(let bell, let stroke):
                return ["bell": bell, "stroke": stroke, "tower_id": towerInfo.towerID]
            case .assignUser(let bell, let user):
                return ["tower_id": towerInfo.towerID, "bell": bell, "user": user]
            case .audioChange(let bellType):
                return ["tower_id": towerInfo.towerID, "new_audio": bellType.rawValue]
            case .hostModeSet(let newMode):
                return ["tower_id": towerInfo.towerID, "new_mode": newMode]
            case .sizeChange(let newSize):
                return ["tower_id": towerInfo.towerID, "new_size": newSize]
            case .messageSent(let message, let time):
                return ["user": user.username, "email": user.email, "msg": message, "tower_id": towerInfo.towerID, "time": time]
            case .call(let call):
                return ["call": call, "tower_id": towerInfo.towerID]
            case .setBells:
                return ["tower_id": towerInfo.towerID]
            }
        }()
        socketIOService.send(event: event.eventName, with: payload)
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
    @Published var bellMode = BellMode.ring
    
    var hasPermissions: Bool {
        !towerInfo.hostModePermitted || towerInfo.isHost || !hostMode
    }
    
    let callPublisher = PassthroughSubject<String, Never>()
    
    private let audioService = AudioService()
    
    func changeVolume(to volume: Double) {
        UserDefaults.standard.set(volume, forKey: "volume")

        let mappedVolume = pow(volume, 3)
        audioService.starling.changeVolume(to: Float(mappedVolume))
    }
    
    @Published var isLargeSize = false
        
    @Published var newMessages = 0
    @Published var messages = [Message]()
    
    var canSeeMessages: Bool {
        false
    }
    
    @Published var showingTowerControls = false
    @Published var towerControlsViewSelection = TowerControlViewSelection.settings
    
    var sortUsersTimer = Timer()
    var updateAssignmentsTimer = Timer()
    
    var assignmentsBuffer = [Ringer?]()
    var usersBuffer = [Ringer]()
    
    var autoRotate = UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
    
    var ringTime: Date = .now
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
        }
        
        guard !users.keys.contains(ringer.ringerID) else { return }
        users[ringer.ringerID] = ringer
    }
    
    func userDidLeave(_ ringer: Ringer) {
        if ringer.id == self.ringer?.ringerID {
            
        }
        
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
        print(Date.now.timeIntervalSince(ringTime))
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
        if size != newSize {
            if size == 0 {
                send(.requestGlobalState)
            }
            
            if newSize > size {
                for _ in 1...(newSize - size) {
                    assignments.append(nil)
                }
            } else {
                assignments = Array(assignments[..<newSize])
            }
            
            bellStates = Array(repeating: .hand, count: newSize)
            size = newSize
        } else {
            send(.requestGlobalState)
        }
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
