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
    
    func connectSocket(server_ip:String) {
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
        
        socket.on(clientEvent: .connect) { data, ack in
            print(self.socket.status)
            self.socket.emit("c_join", ["tower_id": self.bellCircle.towerID, "user_token": CommunicationController.token!, "anonymous_user": false])
        }
        
        socket.on("s_bell_rung") { data, ack in
            print(self.bellCircle.counter)
            self.bellCircle.bellRang(number: self.getDict(data)["who_rang"] as! Int, bellStates: self.getDict(data)["global_bell_state"] as! [Bool])
        }
        
        socket.on("s_call") { data, ack in
            print(self.getDict(data)["call"] as! String)
            self.bellCircle.callMade(self.getDict(data)["call"] as! String)
        }
    }
    
    func getDict(_ array:[Any]) -> [String:Any] {
        let data = array[0] as! [String:Any]

        return data
    }
    
    func leaveTower() {
        socket.emit("c_user_left", ["user_name":User.shared.name, "user_token":CommunicationController.token!, "anonymous_user":false, "tower_id":bellCircle.towerID])
        socket.disconnect()
    }
    
    func getStatus() {
        print(socket.status)
    }
    
}
