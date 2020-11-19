//
//  myManager.swift
//  NativeRingingRoom
//
//  Created by Matthew on 01/08/2020.
//  Copyright © 2020 Matthew. All rights reserved.
//

import Foundation
import SocketIO
import Combine

class SocketIOManager: NSObject {
    static var shared = SocketIOManager()
    
    var socket:SocketIOClient!
    
    var manager:SocketManager!
    
    var bellCircle = BellCircle.current
    
    var ignoreSetup = false
    
    var reconnectAttempt = false
    var server_ip = ""
    
    func connectSocket(server_ip:String) {
        self.server_ip = server_ip
        manager = SocketManager(socketURL: URL(string: server_ip)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        addListeners()
        socket.connect()
        print(bellCircle.towerID)
    }
    
    func addListeners() {
        socket.onAny() { data in
            if !(data.event == "ping" || data.event == "pong") {
                print("received socketio event: ", data.event)
            }
        }
        
        socket.on(clientEvent: .reconnect) { data, ack in
            self.reconnectAttempt = true
        }
//
        socket.on(clientEvent: .connect) { data, ack in
            print(self.socket.status)
            self.socket.emit("c_join", ["tower_id": self.bellCircle.towerID, "user_token": CommunicationController.token!, "anonymous_user": false])
        }
        
        socket.on("s_size_change") { data, ack in
            self.bellCircle.newSize(self.getDict(data)["size"] as! Int)
            if !self.bellCircle.setupComplete["gotSize"]! && !self.ignoreSetup {
                self.bellCircle.setupComplete["gotSize"] = true
                NotificationCenter.default.post(name: BellCircle.setup, object: nil )
                
                self.bellCircle.objectWillChange.send()
                
                self.socket.emit("c_request_global_state", ["tower_id":self.bellCircle.towerID])
            }
            if self.reconnectAttempt {
                self.socket.emit("c_request_global_state", ["tower_id":self.bellCircle.towerID])
                self.reconnectAttempt = false
            }
        }
        
        socket.on("s_global_state") { data, ack in
            if !self.bellCircle.setupComplete["gotBellStates"]! && !self.ignoreSetup {
                self.bellCircle.setupComplete["gotBellStates"] = true
                NotificationCenter.default.post(name: BellCircle.setup, object: nil )
            }
            self.bellCircle.objectWillChange.send()
            self.bellCircle.bellStates = self.getDict(data)["global_bell_state"] as! [Bool]
        }
        
        socket.on("s_bell_rung") { data, ack in
            print(self.bellCircle.counter)
            self.bellCircle.bellRang(number: self.getDict(data)["who_rang"] as! Int, bellStates: self.getDict(data)["global_bell_state"] as! [Bool])
        }
        
        socket.on("s_call") { data, ack in
            print(self.getDict(data)["call"] as! String)
            self.bellCircle.callMade(self.getDict(data)["call"] as! String)
        }
        
        socket.on("s_set_userlist") { data, ack in
            if !self.bellCircle.setupComplete["gotUserList"]! && !self.ignoreSetup {
                print("set true")
                self.bellCircle.setupComplete["gotUserList"] = true
                NotificationCenter.default.post(name: BellCircle.setup, object: nil )
            }
            self.bellCircle.newUserlist(self.getDict(data)["user_list"] as! [[String:Any]])
        }
        
        socket.on("s_assign_user") { data, ack in
            let id = self.getDict(data)["user"] as? Int
            let bell = self.getDict(data)["bell"] as! Int
            if id != nil {
                if id == 0 {
                    self.bellCircle.unAssign(at: bell)
                } else {
                    self.bellCircle.assign(id!, to: bell)
                }
            } else {
                self.bellCircle.unAssign(at: bell)
            }
        }
        
        socket.on("s_user_entered") { data, ack in
            if !self.bellCircle.setupComplete["gotUserEntered"]! && !self.ignoreSetup {
                User.shared.ringerID = self.getDict(data)["user_id"] as! Int
                self.bellCircle.setupComplete["gotUserEntered"] = true
                NotificationCenter.default.post(name: BellCircle.setup, object: nil )
            }
            self.bellCircle.newUser(id: self.getDict(data)["user_id"] as! Int, name: self.getDict(data)["username"] as! String)
        }
        
        socket.on("s_audio_change") { data, ack in
            if !self.bellCircle.setupComplete["gotAudioType"]! && !self.ignoreSetup {
                self.bellCircle.setupComplete["gotAudioType"] = true
                NotificationCenter.default.post(name: BellCircle.setup, object: nil )
            }
            self.bellCircle.newAudio(self.getDict(data)["new_audio"] as! String)
        }
        
        socket.on("s_host_mode") { data, ack in
            if !self.bellCircle.setupComplete["gotHostMode"]! && !self.ignoreSetup {
                self.bellCircle.setupComplete["gotHostMode"] = true
                NotificationCenter.default.post(name: BellCircle.setup, object: nil )
            }
            self.bellCircle.objectWillChange.send()
            self.bellCircle.hostModeEnabled = self.getDict(data)["new_mode"] as! Bool
        }
        
        socket.on("s_msg_sent") { data, ack in
            ChatManager.shared.newMessage(user: self.getDict(data)["user"] as! String, message: self.getDict(data)["msg"] as! String)
        }
        
        socket.on("s_user_left") { data, ack in
            if self.getDict(data)["user_id"] as! Int == User.shared.ringerID {
                self.leaveTower()
            } else {
                self.bellCircle.userLeft(id: self.getDict(data)["user_id"] as! Int)
            }
        }
    }
    
    func getDict(_ array:[Any]) -> [String:Any] {
        let data = array[0] as! [String:Any]

        return data
    }
    
    func leaveTower() {
        socket.emit("c_user_left", ["user_name":User.shared.name, "user_token":CommunicationController.token!, "anonymous_user":false, "tower_id":bellCircle.towerID])
        if bellCircle.ringingroomIsPresented {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "dismissRingingRoom"), object: nil)
            bellCircle.ringingroomIsPresented = false
        }
        bellCircle.setupComplete = ["gotUserList":false, "gotSize":false, "gotAudioType":false, "gotHostMode":false, "gotUserEntered":false, "gotBellStates":false, "gotAssignments":false]
        socket.disconnect()
        ChatManager.shared.messages = [String]()
        ChatManager.shared.newMessages = 0
        ChatManager.shared.canSeeMessages = false
//        manager = nil
        ignoreSetup = false
    }
    
    func getStatus() {
        print(socket.status)
    }
    
}
