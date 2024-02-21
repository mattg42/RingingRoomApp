//
//  SocketIOService.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation
import SocketIO
import Combine

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
        }
    }
}

class SocketIOService {
    
    private let manager: SocketManager
    private var socket: SocketIOClient
    private let url: URL
    
    weak var delegate: SocketIODelegate?
    
    init(url: URL) {
        self.url = url
        manager = SocketManager(socketURL: url)
        socket = manager.defaultSocket
    }
    
    deinit {
        print("socket deinit")
    }
    
    func connect(completion: @escaping () -> ()) {
        socket = manager.defaultSocket
        
        // Making sure the connection and listeners are reset if we try to reconnect
        socket.disconnect()
        socket.removeAllHandlers()
        
        setupListeners()
        
        socket.on(clientEvent: .connect) { _, _ in
            completion()
        }
        
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    private func setupListeners() {
 
//        socket.onAny { event in
//            print(event.event)
//        }
        
        listen(for: "s_user_entered") { [weak self] data in
            let user = Ringer(from: data)
            self?.delegate?.userDidEnter(user)
        }
        
        listen(for: "s_user_left") { [weak self] data in
            let user = Ringer(from: data)

            self?.delegate?.userDidLeave(user)
        }
        
        listen(for: "s_global_state") { [weak self] data in
            let globalState = try data.extract("global_bell_state", as: [Bool].self)
            
            self?.delegate?.didReceiveGlobalState(globalState.map { BellStroke(bool: $0) })
        }
        
        listen(for: "s_set_userlist") { [weak self] data in
            let userList = (try data.extract("user_list", as: [[String: Any]].self))
                .map({ Ringer(from: $0) })

            self?.delegate?.didReceiveUserList(userList)
        }
        
        listen(for: "s_bell_rung") { [weak self] data in
            let bell = try data.extract("who_rang", as: Int.self)
            let globalState = try data.extract("global_bell_state", as: [Bool].self)

            self?.delegate?.bellDidRing(
                number: bell,
                globalState: globalState.map { BellStroke(bool: $0) }
            )
        }
        
        listen(for: "s_assign_user") { [weak self] data in
            let bell = try data.extract("bell", as: Int.self)
            let userID = try data.extract("user", as: Int.self, else: 0)
            self?.delegate?.didAssign(ringerID: userID, to: bell)
        }
        
        listen(for: "s_audio_change") { [weak self] data in
            let newAudio = try data.extract("new_audio", as: String.self)
            
            guard let bellType = BellType(rawValue: newAudio) else {
                throw SocketIOError(message: "Unable to convert \(newAudio) to an audio type.")
            }
            
            self?.delegate?.audioDidChange(to: bellType)
        }
        
        listen(for: "s_host_mode") { [weak self] data in
            let newMode = try data.extract("new_mode", as: Bool.self)
            self?.delegate?.hostModeDidChange(to: newMode)
        }
        
        listen(for: "s_size_change") { [weak self] data in
            let newSize = try data.extract("size", as: Int.self)
            self?.delegate?.sizeDidChange(to: newSize)
        }
        
        listen(for: "s_msg_sent") { [weak self] data in
            let user = try data.extract("user", as: String.self)
            let message = try data.extract("msg", as: String.self)

            self?.delegate?.didReceiveMessage(Message(sender: user, message: message))
        }
        
        listen(for: "s_call") { [weak self] data in
            let call = try data.extract("call", as: String.self)
            self?.delegate?.didReceiveCall(call)
        }
        
        listen(for: "s_bad_token") { [weak self] data in
            self?.delegate?.didReceiveBadToken()
        }
    }
    
    func send(event: String, with data: SocketData) {
        socket.emit(event, data)
    }
    
    func listen(for event: String, callback: @escaping ([String: Any]) throws -> Void) {
        socket.on(event) { data, _ in
            do {
                try callback(data[0] as! [String: Any])
            } catch {
                AlertHandler.presentAlert(title: "SocketIO error", message: "Event: \(event). Error: \(error). Please screenshot and send to ringingroomapp@gmail.com.", dismiss: .cancel(title: "OK", action: nil))
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
