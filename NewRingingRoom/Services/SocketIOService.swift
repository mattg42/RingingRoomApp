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
    case userLeft
    case requestGlobalState
    case bellRung(bell: Int, stroke: Bool)
    case assignUser(bell: Int, user: Int)
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
        case .userLeft:
            return "c_user_left"
        case .requestGlobalState:
            return "c_request_global_state"
        case .bellRung:
            return "c_bell_rung"
        case .assignUser:
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
    
    private struct SocketIOError: LocalizedError {
        let message: String
        
        var errorDescription: String? {
            message
        }
    }
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    weak var delegate: SocketIODelegate?
    
    init(url: URL) {
        manager = SocketManager(socketURL: url)
        socket = manager.defaultSocket
        setupListeners()
    }
    
    deinit {
        print("socket deinit")
    }
    
    func connect(completion: @escaping () -> ()) {
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
            let globalState = data["global_bell_state"] as! [Bool]
            self?.delegate?.didReceiveGlobalState(globalState.map { BellStroke(bool: $0) })
        }
        
        listen(for: "s_set_userlist") { [weak self] data in
            let userList = (data["user_list"] as! [[String: Any]])
                .reduce(into: [Int: Ringer]()) { partialResult, newRinger in
                    let ringer = Ringer(from: newRinger)
                    partialResult[ringer.ringerID] = ringer
                }
            
            self?.delegate?.didReceiveUserList(userList)
        }
        
        listen(for: "s_bell_rung") { [weak self] data in
            let bell = data["who_rang"] as! Int
            let globalState = data["global_bell_state"] as! [Bool]
            
            self?.delegate?.bellDidRing(
                number: bell,
                globalState: globalState.map { BellStroke(bool: $0) }
            )
        }
        
        listen(for: "s_assign_user") { [weak self] data in
            let bell = data["bell"] as! Int
            let userID = (data["user"] as? Int) ?? 0
            self?.delegate?.didAssign(ringerID: userID, to: bell)
        }
        
        listen(for: "s_audio_change") { [weak self] data in
            let newAudio = data["new_audio"] as! String
            self?.delegate?.audioDidChange(to: BellType(rawValue: newAudio)!)
        }
        
        listen(for: "s_host_mode") { [weak self] data in
            let newMode = data["new_mode"] as! Bool
            self?.delegate?.hostModeDidChange(to: newMode)
        }
        
        listen(for: "s_size_change") { [weak self] data in
            let newSize = data["size"] as! Int
            self?.delegate?.sizeDidChange(to: newSize)
        }
        
        listen(for: "s_msg_sent") { [weak self] data in
            let user = data["user"] as! String
            let message = data["msg"] as! String

            self?.delegate?.didReceiveMessage(Message(sender: user, message: message))
        }
        
        listen(for: "s_call") { [weak self] data in
            let call = data["call"] as! String
            self?.delegate?.didReceiveCall(call)
        }
    }
    
    func send(event: String, with data: SocketData) {
        socket.emit(event, data)
//        print("sent event \(event) with data \(data)")
    }
    
    func listen(for event: String, callback: @escaping ([String: Any]) throws -> Void) {
        socket.on(event) { data, _ in
            do {
                try callback(data[0] as! [String: Any])
            } catch {
                AlertHandler.presentAlert(title: "SocketIO error", message: "Error: \(error.localizedDescription) Please screenshot and send to ringingroomapp@gmail.com.", dismiss: .cancel(title: "OK", action: nil))
            }
        }
    }
}
