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

class RingingRoomState: ObservableObject {
    
    @Published var ringer: Ringer?
    
    @Published var perspective = 1
    
    @Published var size = 0
    @Published var bellType = BellType.tower
    @Published var users = [Int: Ringer]()
    @Published var assignments = [Int?]()
    @Published var bellStates = [BellStroke]()
    @Published var hostMode = false
    @Published var bellMode = BellMode.ring
    
    @Published var isLargeSize = false
    
    @Published var newMessages = 0
    @Published var messages = [Message]()
    
    @Published var showingTowerControls = false
}

class TowerControlsState: ObservableObject {
    @Published var towerControlsViewSelection = TowerControlViewSelection.settings
}

class RingingRoomViewModel: ObservableObject {
    
    init(socketIOService: SocketIOService, router: Router<MainRoute>, towerInfo: TowerInfo, token: String, user: User) {
        self.socketIOService = socketIOService
        self.towerInfo = towerInfo
        self.token = token
        self.user = user
        self.router = router
        self.socketIOService.delegate = self
    }
    
    deinit {
        socketIOService.disconnect()
    }
    
    func ringBell(number: Int) {
        ringTime = .now
        send(.bellRung(bell: number, stroke: state.bellStates[number - 1].boolValue))
    }
    
    func connect() {
        socketIOService.connect { [weak self] in
            if let self {
                self.send(.join)
                self.audioService.starling.prepareToStart()
            }
        }
    }
    
    var state = RingingRoomState()
    let towerControlsState = TowerControlsState()
    
    var unwrappedRinger: Ringer {
        if let ringer = state.ringer {
            return ringer
        } else {
            AlertHandler.presentAlert(title: "An error occured", message: "Please leave the tower and rejoin", dismiss: .cancel(title: "Leave", action: { [weak self] in
                self?.send(.userLeft)
            }))
            return Ringer(name: "", id: 0)
        }
    }
    
    let router: Router<MainRoute>
    let token: String
    let user: User
    
    let socketIOService: SocketIOService
    let towerInfo: TowerInfo
    
    func disconnect() {
        socketIOService.disconnect()
    }
    
    func send(_ event: ClientSocketEvent) {
        let payload = {
            switch event {
            case .join:
                return ["tower_id": towerInfo.towerID, "user_token": token, "anonymous_user": false]
            case .userLeft:
                return ["user_name": user.username, "tower_id": towerInfo.towerID, "user_token": token, "anonymous_user": false]
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
    
    var hasPermissions: Bool {
        !towerInfo.hostModePermitted || towerInfo.isHost || !state.hostMode
    }
    
    let callPublisher = PassthroughSubject<String, Never>()
    
    private let audioService = AudioService()
    
    func changeVolume(to volume: Double) {
        UserDefaults.standard.set(volume, forKey: "volume")

        let mappedVolume = pow(volume, 3)
        audioService.starling.changeVolume(to: Float(mappedVolume))
    }
    

    
    var canSeeMessages: Bool {
        false
    }
    

    
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
        if self.state.ringer == nil {
            self.state.ringer = ringer
        }
        
        guard !state.users.keys.contains(ringer.ringerID) else { return }
        state.users[ringer.ringerID] = ringer
    }
    
    func userDidLeave(_ ringer: Ringer) {
        if ringer.id == unwrappedRinger.ringerID {
            router.moveTo(.home)
        }
        
        state.users.removeValue(forKey: ringer.ringerID)
        
        while state.assignments.contains(ringer.ringerID) {
            if let index = state.assignments.firstIndex(of: ringer.ringerID) {
                state.assignments[index] = nil
            }
        }
    }
    
    func didReceiveGlobalState(_ globalState: [BellStroke]) {
        if state.size == 0 {
            sizeDidChange(to: globalState.count)
        }
        state.bellStates = globalState
    }
    
    func didReceiveUserList(_ userList: [Int: Ringer]) {
        state.users = userList
    }
    
    func bellDidRing(number: Int, globalState: [BellStroke]) {
        print(Date.now.timeIntervalSince(ringTime))
        state.bellStates = globalState
        
        guard var fileName = state.bellType.sounds[state.size]?[number - 1] else { return }
        
        if state.bellType == .tower {
            fileName = "T" + fileName
            switch towerInfo.muffled {
            case .toll:
                if (number != state.size) || globalState[number - 1] == .back {
                    fileName += "-muf"
                }
            case .full:
                fileName += "-muf"
            case .half:
                if state.bellStates[number-1] == .hand {
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
        if state.users.keys.contains(ringerID) {
            state.assignments[bell - 1] = ringerID
        } else if ringerID == 0 {
            state.assignments[bell - 1] = nil
        } else {
            AlertHandler.presentAlert(title: "Error", message: "The users list is out of sync. Please leave the tower and rejoin.", dismiss: .cancel(title: "OK", action: nil))
            return
        }
        
        if ringerID == unwrappedRinger.ringerID || ringerID == 0 {
            if autoRotate {
                setPersective()
            }
        }
    }
    
    func audioDidChange(to newBellType: BellType) {
        state.bellType = newBellType
    }
    
    func hostModeDidChange(to newMode: Bool) {
        state.hostMode = newMode
    }
    
    func setPersective() {
        state.perspective = (
            state.assignments
                .enumerated()
                .first(where: { $0.element == state.ringer?.ringerID })?
                .offset ?? 0
        ) + 1
    }
    
    func sizeDidChange(to newSize: Int) {
        if state.size != newSize {
            if state.size == 0 {
                send(.requestGlobalState)
            }
            
            if newSize > state.size {
                for _ in 1...(newSize - state.size) {
                    state.assignments.append(nil)
                }
            } else {
                state.assignments = Array(state.assignments[..<newSize])
            }
            
            if autoRotate {
                setPersective()
            } else {
                if state.perspective > newSize {
                    state.perspective = 1
                }
            }
            
            state.bellStates = Array(repeating: .hand, count: newSize)
            state.size = newSize
        } else {
            send(.requestGlobalState)
        }
    }
    
    func didReceiveMessage(_ message: Message) {
        if !canSeeMessages {
            state.newMessages += 1
        }
        state.messages.append(message)
    }
    
    func didReceiveCall(_ call: String) {
        audioService.play(call)
        
        callPublisher.send(call)
    }
}
