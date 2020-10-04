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

        }
    }
    
    func getDict(_ array:[Any]) -> [String:Any] {
        let data = array[0] as! [String:Any]
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
