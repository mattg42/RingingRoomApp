//
//  myManager.swift
//  NativeRingingRoom
//
//  Created by Matthew on 01/08/2020.
//  Copyright © 2020 Matthew. All rights reserved.
//

import Foundation
import SocketIO

class MyManager: NSObject {
    var socket:SocketIOClient!
    
    var manager:SocketManager!
    
    init(server_ip:String) {
        super.init()
        manager = SocketManager(socketURL: URL(string: server_ip)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
    }
    
    func addListeners() {
        socket.on(clientEvent: .connect) { data, ack in
            print(self.socket.status)
        }
    }
    
    
    func connectSocket() {
        socket.connect()
    }
    
    func getStatus() {
        print(socket.status)
    }
    
}
