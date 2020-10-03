//
//  myManager.swift
//  NativeRingingRoom
//
//  Created by Matthew on 01/08/2020.
//  Copyright © 2020 Matthew. All rights reserved.
//

import Foundation
import SocketIO

class SocketIOManager: NSObject {
    static var shared = SocketIOManager()
    
    var socket:SocketIOClient!
    
    var manager:SocketManager!
    
    var bellCircle = BellCircle.current
    
    var ringingroomView:RingingRoomView!
    
    
    func initManager(server_ip:String) {
        manager = SocketManager(socketURL: URL(string: server_ip)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        addListeners()
    }
    
    func addListeners() {
        socket.onAny() { data in
            if !(data.event == "ping" || data.event == "pong") {
                print("received socketio event: ", data.event)
            }
        }
        
        socket.on(clientEvent: .connect) { data, ack in
            print(self.socket.status)
            if self.socket.status == .connected {
                self.ringingroomView.joinTower()
            }
        }
        
        socket.on("s_set_userlist") { data, ack in
            var userList = [Ringer]()

            for element in self.getDict(data)["user_list"] as! [Any] {
                let dict = Dictionary<String, Any>(_immutableCocoaDictionary: element as! NSDictionary)
                let newRinger = Ringer(name: dict["username"] as! String, id: dict["user_id"] as! Int)
                userList.append(newRinger)
            }
            BellCircle.current.users = userList
            print("userlist, ", userList.names, userList.IDs)
            self.ringingroomView.gotUserList = true
        }
        
        // The server told us the number of bells in the tower
        socket.on("s_size_change") { data, ack in
            BellCircle.current.size = self.getDict(data)["size"] as! Int
            if self.ringingroomView.gotSize == false {
                self.socket.emit("c_request_global_state", ["tower_id":BellCircle.current.towerID])
                self.ringingroomView.gotSize = true
            }
            
        }
        
        socket.on("s_bell_rung") { data, ack in
//            print("received bell rung")
            self.ringingroomView.bellRang(number: String((self.getDict(data)["who_rang"] as! Int) - 1))
        }
        
        // A call was made
        socket.on("s_call") { data, ack in
            print("call made")
            self.ringingroomView.callMade(self.getDict(data)["call"] as! String)
        }
        
        // User entered the room
        socket.on("s_user_entered") { data, ack in
            let id = self.getDict(data)["user_id"] as! Int
            let username = self.getDict(data)["username"] as! String
            if !BellCircle.current.users.containsRingerForID(id) {
                let newRinger = Ringer(name: username, id: id)
                BellCircle.current.users.append(newRinger)
            }
            BellCircle.current.sortUsers()
            self.ringingroomView.gotUserEntered = true
        }

        // User left the room
        socket.on("s_user_left") { data, ack in\
            let id = self.getDict(data)["user_id"] as! Int
            let username = self.getDict(data)["username"] as! String
            if BellCircle.current.users.containsRingerForID(id) {
                BellCircle.current.removeRinger(for: id)
            }
            

        }
        //
        //        // Number of observers changed
        //        socket.on("s_set_observers", function(msg, cb){
        //            console.log("observers: " + msg.observers)
        //            bell_circle.$refs.users.observers = msg.observers
        //        })
        //
        // User was assigned to a bell
        socket.on("s_assign_user") { data, ack in
            print(data)
            if let id = self.getDict(data)["user"] as? Int {
                if id == 0 {
                    BellCircle.current.setAssignment(user: Ringer(name: "", id: 0), to: self.getDict(data)["bell"] as! Int)
                } else {
                    BellCircle.current.setAssignment(user: BellCircle.current.ringerForId(id)!, to: self.getDict(data)["bell"] as! Int)
                }
            } else {
                BellCircle.current.setAssignment(user: Ringer(name: "", id: 0), to: self.getDict(data)["bell"] as! Int)
            }
            self.ringingroomView.gotAssignments = true
        }

        // The server sent us the global state set all bells accordingly
        socket.on("s_global_state") { data, ack in
            BellCircle.current.bellStates = self.getDict(data)["global_bell_state"] as! [Bool]
        }

        // The server told us whether to use handbells or towerbells
        socket.on("s_audio_change") { data, ack in
            print("changing audio to: \(String(describing: self.getDict(data)["new_audio"]))")
            if self.getDict(data)["new_audio"] as! String == "Tower" {
                BellCircle.current.bellType = .tower
            } else {
                BellCircle.current.bellType = .hand
            }
            self.ringingroomView.gotBellType = true
        }

        // A chat message was received
        socket.on("s_msg_sent") { data, ack in
            ChatManager.shared.newMessage(user: (self.getDict(data)["user"] as! String), message: (self.getDict(data)["msg"] as! String))
        }

        // Host mode was changed
        socket.on("s_host_mode") { data, ack in
            BellCircle.current.hostModeEnabled = self.getDict(data)["new_mode"] as! Bool
            self.ringingroomView.gotHostMode = true
        }
    }
    
    func getDict(_ array:[Any]) -> [String:Any] {
        var data = array[0] as! [String:Any]
//        for key in data.keys {
//            data[key] = data[key] as! [Any]
//            for (index, element) in (data[key] as! [Any]).enumerated() {
//                data[key]
//            }
////            data[key] = data[key]![0] as!
////            print(data[key])
//        }

        return data
    }
    
    func connectSocket() {
        socket.connect()
    }
    
    func getStatus() {
        print(socket.status)
    }
    
}
