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
    var socket:SocketIOClient!
    
    var manager:SocketManager!
    
    var ringingroomView:RingingRoomView!
    
    init(server_ip:String, ringingRoomView:RingingRoomView) {
        super.init()
        self.ringingroomView = ringingRoomView
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
    
        socket.on("s_bell_rung") { data, ack in
            print("received bell rung")
            self.ringingroomView.bellCircle.bells[self.getDict(data)["who_rang"] as! Int].stroke.toggle()
            self.ringingroomView.bellRang(number: self.getDict(data)["who_rang"] as! Int)
        }

        socket.on("s_set_userlist") { data, ack in
            self.ringingroomView.users = self.getDict(data)["user_list"] as! [String]
        }
//
        // User entered the room
        socket.on("s_user_entered") { data, ack in
            self.ringingroomView.users.append(self.getDict(data)["user_name"] as! String)
        }
//
//        // User left the room
//        socket.on("s_user_left", function(msg, cb){
//            console.log(msg.user_name + " left")
//            bell_circle.$refs.users.remove_user(msg.user_name)
//            bell_circle.$refs.bells.forEach((bell,index)=>
//                {
//                    if (bell.assigned_user === msg.user_name) {
//                        bell.assigned_user = ""
//                    }
//                })
//        })
//
//        // Number of observers changed
//        socket.on("s_set_observers", function(msg, cb){
//            console.log("observers: " + msg.observers)
//            bell_circle.$refs.users.observers = msg.observers
//        })
//
        // User was assigned to a bell
        socket.on("s_assign_user") { data, ack in
            var assignments = self.ringingroomView.bellCircle.assignments
            assignments[self.getDict(data)["bell"] as! Int - 1] = self.getDict(data)["user"] as! String
            self.ringingroomView.bellCircle.assignments = assignments
        }
//
//        // A call was made
//        socket.on("s_call",function(msg,cb){
//            console.log("Received call: " + msg.call)
//            bell_circle.$refs.display.make_call(msg.call)
//        })
//
//        // The server told us the number of bells in the tower
//        socket.on("s_size_change", function(msg,cb){
//            var new_size = msg.size
//            bell_circle.number_of_bells = new_size
//        })
//
//
        // The server sent us the global state set all bells accordingly
        socket.on("s_global_state") { data, ack in
            for (index, state) in (self.getDict(data)["global_bell_state"] as! [Bool]).enumerated() {
                self.ringingroomView.bellCircle.bells[index].stroke = state ? .handstroke : .backstroke
            }
        }
//
        // The server told us whether to use handbells or towerbells
        socket.on("s_audio_change") { data, ack in
            print("changing audio to: \(self.getDict(data)["new_audio"])")
            if self.getDict(data)["new_audio"] as! String == "Tower" {
                self.ringingroomView.bellCircle.bellType = .tower
            } else {
                self.ringingroomView.bellCircle.bellType = .hand
            }
        }
//
//        // A chat message was received
//        socket.on("s_msg_sent", function(msg,cb){
//            bell_circle.$refs.chatbox.messages.push(msg)
//            if(msg.email != window.tower_parameters.cur_user_email && !$("#chat_input_box").is(":focus")) {
//                bell_circle.unread_messages++
//            }
//            bell_circle.$nextTick(function()
//                $("#chat_messages").scrollTop($("#chat_messages")[0].scrollHeight)
//            })
//        })
//
        // Host mode was changed
        socket.on("s_host_mode") { data, ack in
            self.ringingroomView.hostModeEnabled = self.getDict(data)["new_mode"] as! Bool
        }
    }
    
    func getDict(_ data:[Any]) -> [String:Any] {
        return (data[0] as! [String:Any])
    }
    
    func connectSocket() {
        socket.connect()
    }
    
    func getStatus() {
        print(socket.status)
    }
    
}
