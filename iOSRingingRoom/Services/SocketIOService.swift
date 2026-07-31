//
//  SocketIOService.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation
import SocketIO
import Combine

enum SocketConnectionState: Equatable {
    case idle
    case connecting
    case authenticating
    case joined
    case reconnecting
    case failed
    case disconnected
}

enum WheatleySetting {
    case sensitivity(Double)
    case useUpDownIn(Bool)
    case stopAtRounds(Bool)
    case pealSpeed(Int)
    case callComposition(Bool)
    case fixedStrikingInterval(Bool)
    
    var json: [String: Any] {
        switch self {
        case .sensitivity(let double):
            ["sensitivity": double]
        case .useUpDownIn(let bool):
            ["use_up_down_in": bool]
        case .stopAtRounds(let bool):
            ["stop_at_rounds": bool]
        case .pealSpeed(let int):
            ["peal_speed": int]
        case .callComposition(let bool):
            ["call_composition": bool]
        case .fixedStrikingInterval(let bool):
            ["fixed_striking_interval": bool]
        }
    }
}

enum ClientSocketEvent {
    case join
    case leaveTower
    case requestGlobalState
    case bellRung(bell: Int, stroke: Bool)
    case assignUser(bell: Int, user: Int)
    case unassignBell(bell: Int)
    case audioChange(to: BellType)
    case hostModeSet(to: Bool)
    case sizeChange(to: Int)
    case messageSent(message: String, time: String)
    case call(_ call: String)
    case setBells
    
    case setWheatleySetting(setting: WheatleySetting)
    case setWheatleyRowGen(rowGen: [String: Any])
    case wheatleyStopTouch
    case resetWheatley
    
    var eventName: String {
        switch self {
        case .join:
            return "c_join"
        case .leaveTower:
            return "c_user_left"
        case .requestGlobalState:
            return "c_request_global_state"
        case .bellRung:
            return "c_bell_rung"
        case .assignUser, .unassignBell:
            return "c_assign_user"
        case .audioChange:
            return "c_audio_change"
        case .hostModeSet:
            return "c_host_mode"
        case .sizeChange:
            return "c_size_change"
        case .messageSent:
            return "c_msg_sent"
        case .call:
            return "c_call"
        case .setBells:
            return "c_set_bells"
        case .setWheatleySetting:
            return "c_wheatley_setting"
        case .setWheatleyRowGen:
            return "c_wheatley_row_gen"
        case .wheatleyStopTouch:
            return "c_wheatley_stop_touch"
        case .resetWheatley:
            return "c_reset_wheatley"
        }
    }
}

class SocketIOService {
    
    private struct SocketIOError: LocalizedError {
        let message: String
        
        var errorDescription: String? {
            message
        }
    }
    
    private var manager: SocketManager
    private var socket: SocketIOClient
    private let url: URL
    
    weak var delegate: SocketIODelegate?
    
    init(url: URL) {
        self.url = url
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .reconnects(true),
            .reconnectAttempts(3),
            .reconnectWait(2),
            .reconnectWaitMax(8)
        ])
        socket = manager.defaultSocket
    }
    
    deinit {
        AppLogger.socket.debug("Socket service deinitialized")
    }
    
    func connect(completion: @escaping () -> ()) {
        guard socket.status == .notConnected || socket.status == .disconnected else { return }

        AppLogger.socket.info("Opening socket connection")
        
        socket = manager.defaultSocket
        
        // Making sure the connection and listeners are reset if we try to reconnect
        socket.disconnect()
        socket.removeAllHandlers()
        
        setupListeners()

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            AppLogger.socket.info("Socket connection established")
            self?.notify { $0.socketDidConnect() }
            completion()
        }

        socket.on(clientEvent: .reconnect) { [weak self] _, _ in
            AppLogger.socket.info("Socket reconnected")
            self?.notify { $0.socketWillReconnect() }
        }

        socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            AppLogger.socket.debug("Socket reconnect attempt started")
            self?.notify { $0.socketWillReconnect() }
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            let reason = data.first as? String ?? "The connection was closed."
            AppLogger.socket.warning("Socket disconnected: \(reason, privacy: .private)")
            self?.notify { $0.socketDidDisconnect(reason: reason) }
        }

        socket.on(clientEvent: .error) { [weak self] data, _ in
            let message = data.first.map(String.init(describing:)) ?? "The socket connection failed."
            AppLogger.socket.error("Socket error: \(message, privacy: .private)")
            self?.notify { $0.socketDidFail(message: message) }
        }
        
        socket.connect()
    }
    
    func reset() {
        AppLogger.socket.debug("Resetting socket connection")
        socket.removeAllHandlers()
        manager.disconnect()
    
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .reconnects(true),
            .reconnectAttempts(3),
            .reconnectWait(2),
            .reconnectWaitMax(8)
        ])
        socket = manager.defaultSocket
    }
    
    func disconnect() {
        AppLogger.socket.info("Closing socket connection")
        socket.disconnect()
    }

    private func notify(_ action: @escaping @MainActor (any SocketIODelegate) -> Void) {
        guard let delegate else { return }
        Task { @MainActor in
            action(delegate)
        }
    }
    
    private func setupListeners() {

        listen(for: "s_user_entered") { [weak self] data in
            let user = try Ringer(socketPayload: data)
            self?.notify { $0.userDidEnter(user) }
        }
        
        listen(for: "s_user_left") { [weak self] data in
            let user = try Ringer(socketPayload: data)

            self?.notify { $0.userDidLeave(user) }
        }
        
        listen(for: "s_global_state") { [weak self] data in
            let globalState = try data.extract("global_bell_state", as: [Bool].self)
            
            let state = globalState.map { BellStroke(bool: $0) }
            self?.notify { $0.didReceiveGlobalState(state) }
        }
        
        listen(for: "s_set_userlist") { [weak self] data in
            let userPayloads = try data.extract("user_list", as: [[String: Any]].self)
            let userList = try userPayloads.map { try Ringer(socketPayload: $0) }

            self?.notify { $0.didReceiveUserList(userList) }
        }
        
        listen(for: "s_bell_rung") { [weak self] data in
            let bell = try data.extract("who_rang", as: Int.self)
            let globalState = try data.extract("global_bell_state", as: [Bool].self)

            let state = globalState.map { BellStroke(bool: $0) }
            self?.notify { $0.bellDidRing(number: bell, globalState: state) }
        }
        
        listen(for: "s_assign_user") { [weak self] data in
            let bell = try data.extract("bell", as: Int.self)
            let userID = try data.extract("user", as: Int.self, else: 0)
            self?.notify { $0.didAssign(ringerID: userID, to: bell) }
        }
        
        listen(for: "s_audio_change") { [weak self] data in
            let newAudio = try data.extract("new_audio", as: String.self)
            
            guard let bellType = BellType(rawValue: newAudio) else {
                throw SocketIOError(message: "Unable to convert \(newAudio) to an audio type.")
            }
            
            self?.notify { $0.audioDidChange(to: bellType) }
        }
        
        listen(for: "s_host_mode") { [weak self] data in
            let newMode = try data.extract("new_mode", as: Bool.self)
            self?.notify { $0.hostModeDidChange(to: newMode) }
        }
        
        listen(for: "s_size_change") { [weak self] data in
            let newSize = try data.extract("size", as: Int.self)
            self?.notify { $0.sizeDidChange(to: newSize) }
        }
        
        listen(for: "s_msg_sent") { [weak self] data in
            let user = try data.extract("user", as: String.self)
            let message = try data.extract("msg", as: String.self)

            self?.notify { $0.didReceiveMessage(Message(sender: user, message: message)) }
        }
        
        listen(for: "s_call") { [weak self] data in
            let call = try data.extract("call", as: String.self)
            self?.notify { $0.didReceiveCall(call) }
        }
        
        listen(for: "s_bad_token") { [weak self] data in
            self?.notify { $0.didReceiveBadToken() }
        }
        
        listen(for: "s_wheatley_row_gen") { [weak self] data in
            let newRowGen = try RowGen(dictionary: data)
            self?.notify { $0.rowGenDidChange(to: newRowGen) }
        }
        
        listen(for: "s_wheatley_setting") { [weak self] data in
            for key in data.keys {
                switch key {
                case "sensitivity":
                    // Currently unused
                    break
                case "use_up_down_in":
                    let newSetting = try data.extract(key, as: Bool.self)
                    self?.notify { $0.wholePullAndOffDidChange(to: newSetting) }
                case "stop_at_rounds":
                    let newSetting = try data.extract(key, as: Bool.self)
                    self?.notify { $0.stopAtRoundsDidChange(to: newSetting) }
                case "peal_speed":
                    let newSetting = try data.extract(key, as: Int.self)
                    self?.notify { $0.pealSpeedDidChange(to: newSetting) }
                case "call_composition":
                    let newSetting = try data.extract(key, as: Bool.self)
                    self?.notify { $0.callCompositionDidChange(to: newSetting) }
                case "fixed_striking_interval":
                    let newSetting = try data.extract(key, as: Bool.self)
                    self?.notify { $0.fixedStrikingIntervalDidChange(to: newSetting) }
                default:
                    throw SocketIOError(message: "Setting not found \(key)")
                }
            }
        }
        
        listen(for: "s_wheatley_is_ringing") { [weak self] data in
            let isRinging = try data.extract("is_ringing", as: Bool.self)
            self?.notify { $0.wheatleyStateDidChange(to: isRinging) }
        }

    }
    
    func send(event: String, with data: SocketData) {
        AppLogger.socket.debug("Sending socket event \(event, privacy: .public)")
        socket.emit(event, data)
    }
    
    func listen(for event: String, callback: @escaping ([String: Any]) throws -> Void) {
        socket.on(event) { data, _ in
            do {
                guard let object = data[0] as? [String: Any] else { throw SocketIOError(message: "Payload for \(event) is not an object.") }
                try callback(object)
            } catch {
                AppLogger.socket.error("Failed to process socket event \(event, privacy: .public): \(String(describing: error), privacy: .private)")
                let message = "Event: \(event). Error: \(error). Please screenshot and send to ringingroomapp@gmail.com."
                Task { @MainActor in
                    AlertHandler.presentAlert(title: "SocketIO error", message: message, dismiss: .cancel(title: "OK", action: nil))
                }
            }
        }
    }
}

fileprivate struct SocketIOError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        message
    }
}

fileprivate extension Dictionary where Key == String, Value == Any {
    func extract<T>(_ key: String, as: T.Type, else defaultValue: T? = nil) throws -> T {
        guard let val = self[key] as? T else {
            if let defaultValue {
                return defaultValue
            } else {
                throw SocketIOError(message: "Unable to read \(key) from \(self)")
            }
        }
        return val
    }
}
