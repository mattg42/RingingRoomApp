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

enum BellType: String, CaseIterable, Identifiable, Sendable {
    var id: Self { self }
    
    case tower = "Tower", hand = "Hand", cowbell = "Cow"
    
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
        case .cowbell:
            return [
                4: ["13", "14", "15", "16"],
                5: ["12", "13", "14", "15", "16"],
                6: ["11", "12", "13", "14", "15", "16"],
                8: ["9", "10", "11", "12", "13", "14", "15", "16"],
                10: ["7", "8", "9", "10", "11", "12", "13", "14", "15", "16"],
                12: ["5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"],
                14: ["3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"],
                16: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"],
            ]
        }
        
    }
}

enum BellStroke: Sendable {
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

@MainActor
class RingingRoomState: ObservableObject {
    
    @Published var ringer: Ringer?
    
    @Published var perspective = 1
    
    @Published var size = 0
    @Published var bellType = BellType.tower
    @Published var users = [Ringer]()
    @Published var assignments = [Int?]()
    @Published var bellStates = [BellStroke]()
    @Published var hostMode = false
    @Published var bellMode = BellMode.ring
    
    @Published var isLargeSize = false
    
    @Published var newMessages = 0
    @Published var messages = [Message]()
}

@MainActor
class RingingRoomViewModel: ObservableObject {
    
    init(socketIOService: SocketIOService, router: Router<MainRoute>, towerInfo: TowerInfo, apiService: APIService, user: User) {
        self.socketIOService = socketIOService
        self.towerInfo = towerInfo
        self.apiService = apiService
        self.user = user
        self.router = router
        self.socketIOService.delegate = self
        Task { [audioService] in
            await audioService.prepareToStart()
        }
    }
    
    deinit {
        MainActor.assumeIsolated {
            connectionTimeoutTask?.cancel()
            tokenRecoveryTask?.cancel()
            socketIOService.disconnect()
        }
    }
    
    func ringBell(number: Int) {
        guard isValidBell(number),
              let stroke = state.bellStates[safe: number - 1] else {
            AppLogger.socket.warning("Ignoring attempt to ring bell outside the current tower state")
            return
        }

        #if DEBUG
        ringTime = .now
        #endif
        send(.bellRung(bell: number, stroke: stroke.boolValue))
    }
    
    func connect() {
        guard connectionState != .connecting,
              connectionState != .authenticating,
              connectionState != .reconnecting,
              connectionState != .joined else { return }

        if connectionState != .idle {
            resetTowerState()
        }

        connected = false
        connectionState = .connecting
        startConnectionTimeout()

        socketIOService.connect { [weak self] in
            if let self {
                self.connectionState = .authenticating
                self.startConnectionTimeout()
                self.send(.join)
            }
        }
    }
    
    var state = RingingRoomState()
    var wheatleyState = WheatleyState()
    
    var unwrappedRinger: Ringer {
        if let ringer = state.ringer {
            return ringer
        } else {
            AlertHandler.presentAlert(title: "An error occured", message: "Please leave the tower and rejoin", dismiss: .cancel(title: "Leave", action: { [weak self] in
                self?.send(.leaveTower)
            }))
            return Ringer(name: "", id: 0)
        }
    }
    
    let router: Router<MainRoute>
    let apiService: APIService
    let user: User
    
    let socketIOService: SocketIOService
    let towerInfo: TowerInfo
    
    func disconnect() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        cancelTokenRecovery()
        connectionState = .disconnected
        resetTowerState()
        socketIOService.disconnect()
    }
    
    func resetSocket(cancelTokenRecovery: Bool = true) {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        if cancelTokenRecovery {
            self.cancelTokenRecovery()
        }
        socketIOService.reset()
        connectionState = .idle
        resetTowerState()
        connect()
    }

    func retryConnection() {
        resetSocket()
    }

    func leaveTower() {
        if connectionState == .joined {
            send(.leaveTower)
        }
        disconnect()
        router.moveTo(.home)
    }

    private var connectionTimeoutTask: Task<Void, Never>?
    private var tokenRecoveryTask: Task<Void, Never>?
    private var isRecoveringToken = false
    private var tokenRecoveryGeneration = 0

    @Published var connectionState: SocketConnectionState = .idle

    private func startConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 20_000_000_000)
            } catch {
                return
            }

            guard let self, self.connectionState != .joined else { return }
            self.connectionTimeoutTask = nil
            self.connectionState = .failed
            self.resetTowerState()
            self.socketIOService.disconnect()
        }
    }

    private func resetTowerState() {
        connected = false
        // Set the size first, so SwiftUI never observes a non-zero size with
        // empty bell-state or assignment arrays.
        state.size = 0
        state.ringer = nil
        state.users = []
        state.assignments = []
        state.bellStates = []
        state.hostMode = false
        state.newMessages = 0
        state.messages = []
    }
    
    func send(_ event: ClientSocketEvent) {
        let payload = {
            switch event {
            case .join:
                return ["tower_id": towerInfo.towerID, "user_token": apiService.token, "anonymous_user": false] as [String : Any]
            case .leaveTower:
                return ["user_name": user.username, "tower_id": towerInfo.towerID, "user_token": apiService.token, "anonymous_user": false]
            case .requestGlobalState:
                return ["tower_id": towerInfo.towerID]
            case .bellRung(let bell, let stroke):
                return ["bell": bell, "stroke": stroke, "tower_id": towerInfo.towerID]
            case .assignUser(let bell, let user):
                return ["tower_id": towerInfo.towerID, "bell": bell, "user": user]
            case .unassignBell(let bell):
                return ["tower_id": towerInfo.towerID, "bell": bell, "user": 0]
            case .audioChange(let bellType):
                return ["tower_id": towerInfo.towerID, "new_audio": bellType.rawValue]
            case .hostModeSet(let newMode):
                return ["tower_id": towerInfo.towerID, "new_mode": newMode]
            case .sizeChange(let newSize):
                return ["tower_id": towerInfo.towerID, "new_size": newSize]
            case .messageSent(let message, let time):
                return ["user": user.username, "msg": message, "tower_id": towerInfo.towerID, "time": time]
            case .call(let call):
                return ["call": call, "tower_id": towerInfo.towerID]
            case .setBells:
                return ["tower_id": towerInfo.towerID]
            case .setWheatleySetting(let setting):
                return ["tower_id": towerInfo.towerID, "settings": setting.json]
            case .setWheatleyRowGen(let rowGen):
                return ["tower_id": towerInfo.towerID, "row_gen": rowGen]
            case .wheatleyStopTouch:
                return ["tower_id": towerInfo.towerID]
            case .resetWheatley:
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
        audioService.changeVolume(to: Float(mappedVolume))
    }
    
    var canSeeMessages = false
    
    var sortUsersTimer = Timer()
    var updateAssignmentsTimer = Timer()
    
    var assignmentsBuffer = [Ringer?]()
    var usersBuffer = [Ringer]()
    
    var autoRotate = UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
    
    #if DEBUG
    var ringTime: Date = .now
    #endif
    
    @Published var connected = false
}

@MainActor
protocol SocketIODelegate: AnyObject, Sendable {
    func socketDidConnect()
    func socketWillReconnect()
    func socketDidDisconnect(reason: String)
    func socketDidFail(message: String)
    func sizeDidChange(to newSize: Int)
    func userDidEnter(_ ringer: Ringer)
    func userDidLeave(_ ringer: Ringer)
    func didReceiveGlobalState(_ globalState: [BellStroke])
    func didReceiveUserList(_ userList: [Ringer])
    func bellDidRing(number: Int, globalState: [BellStroke])
    func didAssign(ringerID: Int, to: Int)
    func audioDidChange(to: BellType)
    func hostModeDidChange(to: Bool)
    func didReceiveMessage(_ message: Message)
    func didReceiveCall(_ call: String)
    func rowGenDidChange(to rowGen: RowGen)
    func didReceiveBadToken()
    func pealSpeedDidChange(to speed: Int)
    func fixedStrikingIntervalDidChange(to newValue: Bool)
    func wholePullAndOffDidChange(to newValue: Bool)
    func stopAtRoundsDidChange(to newValue: Bool)
    func callCompositionDidChange(to newValue: Bool)
    func wheatleyStateDidChange(to newValue: Bool)
}

extension RingingRoomViewModel: SocketIODelegate {
    func socketDidConnect() {
        guard connectionState != .disconnected else { return }
        connectionState = .authenticating
        startConnectionTimeout()
    }

    func socketWillReconnect() {
        guard connectionState != .disconnected else { return }
        connectionState = .reconnecting
        startConnectionTimeout()
    }

    func socketDidDisconnect(reason: String) {
        guard connectionState != .disconnected,
              connectionState != .failed else { return }

        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        resetTowerState()
        connectionState = .failed
    }

    func socketDidFail(message: String) {
        guard connectionState != .disconnected,
              connectionState != .failed else { return }

        connectionState = .reconnecting
        startConnectionTimeout()
    }

    func userDidEnter(_ ringer: Ringer) {
        guard connectionState != .disconnected else { return }

        if self.state.ringer == nil {
            self.state.ringer = ringer
        }

        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        connected = true
        connectionState = .joined
        
        guard !state.users.contains(where: { $0 == ringer }) else { return }
        state.users.append(ringer)
    }
    
    func userDidLeave(_ ringer: Ringer) {
        if ringer.id == unwrappedRinger.ringerID {
            disconnect()
            router.moveTo(.home)
        }
        
        state.users.remove(ringer)
        
        while state.assignments.contains(where: { $0 == ringer.ringerID }) {
            if let index = state.assignments.firstIndex(of: ringer.ringerID) {
                state.assignments[index] = nil
            }
        }
    }
    
    func didReceiveGlobalState(_ globalState: [BellStroke]) {
        guard isSupportedSize(globalState.count) else {
            AppLogger.socket.warning("Ignoring global state with unsupported size \(globalState.count, privacy: .public)")
            return
        }

        guard state.size == 0 || state.size == globalState.count else {
            AppLogger.socket.warning("Ignoring global state that does not match the current tower size")
            return
        }

        if state.size == 0 {
            resizeTowerState(to: globalState.count, bellStates: globalState)
            return
        }

        state.bellStates = globalState
    }
    
    func didReceiveUserList(_ userList: [Ringer]) {
        state.users = userList
    }
    
    func bellDidRing(number: Int, globalState: [BellStroke]) {
        #if DEBUG
        let latency = Date.now.timeIntervalSince(ringTime)
        AppLogger.socket.debug("Bell event latency: \(latency, privacy: .public) seconds")
        #endif
        
        guard isValidBell(number), globalState.count == state.size else {
            AppLogger.socket.warning("Ignoring bell event with invalid bell number or global state")
            return
        }

        state.bellStates = globalState
        
        guard var fileName = state.bellType.sounds[state.size]?[safe: number - 1] else { return }
        
        if state.bellType == .tower {
            fileName = "T" + fileName
            switch towerInfo.muffled {
            case .toll:
                if (number != state.size) || globalState[safe: number - 1] == .back {
                    fileName += "-muf"
                }
            case .full:
                fileName += "-muf"
            case .half:
                if state.bellStates[safe: number - 1] == .hand {
                    fileName += "-muf"
                }
            default:
                break
            }
        } else if state.bellType == .hand {
            fileName = "H" + fileName
        } else if state.bellType == .cowbell {
            fileName = "C" + fileName
        }
        
        audioService.play(fileName)
    }
    
    func didAssign(ringerID: Int, to bell: Int) {
        guard isValidBell(bell), state.assignments.count == state.size else {
            AppLogger.socket.warning("Ignoring assignment outside the current tower state")
            return
        }

        if state.users.contains(where: { $0.ringerID == ringerID }) {
            state.assignments[bell - 1] = ringerID
        } else if ringerID == 0 {
            state.assignments[bell - 1] = nil
        } else {
            // TODO: Change action to acutally leave the tower
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
        guard isSupportedSize(newSize) else {
            AppLogger.socket.warning("Ignoring unsupported tower size \(newSize, privacy: .public)")
            return
        }

        if state.size == newSize {
            send(.requestGlobalState)
            return
        }

        let needsGlobalState = state.size == 0
        resizeTowerState(to: newSize)

        if needsGlobalState {
            send(.requestGlobalState)
        }
    }

    private func isSupportedSize(_ size: Int) -> Bool {
        towerInfo.towerSizes.contains(size)
    }

    private func isValidBell(_ bell: Int) -> Bool {
        isSupportedSize(state.size) && (1...state.size).contains(bell)
    }

    private func resizeTowerState(to newSize: Int, bellStates: [BellStroke]? = nil) {
        let oldSize = state.size
        var assignments = Array(state.assignments.prefix(newSize))
        assignments.append(contentsOf: repeatElement(nil, count: newSize - assignments.count))
        let newBellStates = bellStates ?? Array(repeating: .hand, count: newSize)

        // Maintain the view-model invariant at every observable step: any
        // non-zero size has matching assignment and bell-state arrays.
        if newSize < oldSize {
            state.size = newSize
            state.assignments = assignments
            state.bellStates = newBellStates
        } else {
            state.assignments = assignments
            state.bellStates = newBellStates
            state.size = newSize
        }

        if autoRotate {
            setPersective()
        } else if state.perspective > newSize {
            state.perspective = 1
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
    
    func rowGenDidChange(to rowGen: RowGen) {
        wheatleyState.rowGen = rowGen
    }
    
    func didReceiveBadToken() {
        guard !isRecoveringToken else { return }
        isRecoveringToken = true
        tokenRecoveryGeneration += 1
        let generation = tokenRecoveryGeneration

        tokenRecoveryTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if self.tokenRecoveryGeneration == generation {
                    self.tokenRecoveryTask = nil
                    self.isRecoveringToken = false
                }
            }

            do {
                try await self.apiService.updateToken()
                try Task.checkCancellation()
                guard self.tokenRecoveryGeneration == generation else { return }
                self.resetSocket(cancelTokenRecovery: false)
            } catch is CancellationError {
                return
            } catch let error as Alertable {
                guard self.tokenRecoveryGeneration == generation else { return }
                self.failTokenRecovery()
                AlertHandler.handle(error: error)
            } catch {
                guard self.tokenRecoveryGeneration == generation else { return }
                self.failTokenRecovery()
                AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
            }
        }
    }

    private func cancelTokenRecovery() {
        tokenRecoveryGeneration += 1
        tokenRecoveryTask?.cancel()
        tokenRecoveryTask = nil
        isRecoveringToken = false
    }

    private func failTokenRecovery() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        connectionState = .failed
        resetTowerState()
    }
    
    func pealSpeedDidChange(to speed: Int) {
        wheatleyState.pealSpeed = speed
    }
    
    func fixedStrikingIntervalDidChange(to newValue: Bool) {
        wheatleyState.fixedStrikingInterval = newValue
    }
    
    func wholePullAndOffDidChange(to newValue: Bool) {
        wheatleyState.wholePullAndOff = newValue
    }
    
    func stopAtRoundsDidChange(to newValue: Bool) {
        wheatleyState.stopAtRounds = newValue
    }
    
    func callCompositionDidChange(to newValue: Bool) {
        wheatleyState.callComposition = newValue
    }
    
    func wheatleyStateDidChange(to newValue: Bool) {
        wheatleyState.wheatleyIsRinging = newValue
    }
}
