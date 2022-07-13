//
//  SocketIOService.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation
import SocketIO
import Combine

class SocketIOService {
    
    private struct SocketIOError: LocalizedError {
        let message: String
        
        var errorDescription: String? {
            message
        }
    }
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    weak var delegate: BellCircleDelegate?
    
    init(url: URL) {
        manager = SocketManager(socketURL: url)
        socket = manager.defaultSocket
        setupListeners()
    }
    
    func connect() {
        socket.connect()
    }
    
    private let jsonDecoder = JSONDecoder()
    
    private func createRingerFrom(dict: [String: Any]) throws -> Ringer {
        let jsonData = try JSONSerialization.data(withJSONObject: dict)
        let newUser = try jsonDecoder.decode(Ringer.self, from: jsonData)
        return newUser
    }
    
    private func setupListeners() {
        socket.on(clientEvent: .connect) {[weak self]  _, _ in
            self?.delegate?.didConnectToServer()
        }
        
        listen(for: "s_user_entered") { [weak self] data in
            guard let user = try self?.createRingerFrom(dict: data) else {
                fatalError("self not available")
            }
            self?.delegate?.userDidEnter(user)
        }
        
        listen(for: "s_user_left") { [weak self] data in
            guard let user = try self?.createRingerFrom(dict: data) else {
                fatalError("self not available")
            }
            self?.delegate?.userDidLeave(user)
        }
        
        listen(for: "s_global_state") { [weak self] data in
            let globalState = data["global_bell_state"] as! [Bool]
            self?.delegate?.didReceiveGlobalState(globalState.map { BellStroke(bool: $0) })
        }
        
        listen(for: "s_set_userlist") { [weak self] data in
            let userList = data["user_list"] as! [[String: Any]]

            self?.delegate?.didReceiveUserList(
                try userList.map { dict in
                    guard let user = try self?.createRingerFrom(dict: dict) else {
                        fatalError("self not available")
                    }
                    return user
                }
            )
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
            let userID = data["user"] as! Int
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

            self?.delegate?.didReceiveMessage(Message(user: user, message: message))
        }
        
        listen(for: "s_call") { [weak self] data in
            let call = data["call"] as! String
            self?.delegate?.didReceiveCall(call)
        }
    }
    
    func send(event: String, with data: SocketData) {
        socket.emit(event, data)
    }
    
    private func listen(for event: String, callback: @escaping ([String: Any]) throws -> Void) {
        socket.on(event) { data, _ in
            do {
                try callback(data[0] as! [String: Any])
            } catch {
                AlertHandler.presentAlert(title: "SocketIO error", message: "Error: \(error.localizedDescription). Please screenshot and send to ringingroomapp@gmail.com.", dismiss: .cancel(title: "OK", action: nil))
            }
        }
    }
}
