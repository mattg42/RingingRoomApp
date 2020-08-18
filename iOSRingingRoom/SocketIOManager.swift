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
    
    init(server_ip:String) {
        super.init()
        manager = SocketManager(socketURL: URL(string: server_ip)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        addListeners()
    }
    
    func addListeners() {
        socket.onAny() { data in
         //   print("description: ", data.description)
        }
        
        socket.on(clientEvent: .connect) { data, ack in
            print(self.socket.status)
        }
    
        socket.on("s_bell_rung") { data, ack in
            print("received bell rung")
            for line in data {
                print(line)
//            print("Received event: " + data["global_bell_state"] + data["who_rang"])
//            // if(msg.disagree) {}
//            print("ring bell", data["who_rang"])
//          //  bell_circle.ring_bell(msg.who_rang)
            }
        }

        // Userlist was set
//        socket.on('s_set_userlist', function(msg,cb){
//            console.log('s_set_userlist: ' + msg.user_list)
//            bell_circle.$refs.users.user_names = msg.user_list
//        })
//
//        // User entered the room
//        socket.on('s_user_entered', function(msg, cb){
//            console.log(msg.user_name + ' entered')
//            bell_circle.$refs.users.add_user(msg.user_name)
//        })
//
//        // User left the room
//        socket.on('s_user_left', function(msg, cb){
//            console.log(msg.user_name + ' left')
//            bell_circle.$refs.users.remove_user(msg.user_name)
//            bell_circle.$refs.bells.forEach((bell,index)=>
//                {
//                    if (bell.assigned_user === msg.user_name) {
//                        bell.assigned_user = ''
//                    }
//                })
//        })
//
//        // Number of observers changed
//        socket.on('s_set_observers', function(msg, cb){
//            console.log('observers: ' + msg.observers)
//            bell_circle.$refs.users.observers = msg.observers
//        })
//
//        // User was assigned to a bell
//        socket.on('s_assign_user', function(msg, cb){
//            console.log('Received user assignment: ' + msg.bell + ' ' + msg.user)
//            try {
//                // This stochastically very error-prone:
//                // Sometimes it sets the state before the bell is created
//                // As such: try it, but if it doesn't work wait a bit and try again.
//                bell_circle.$refs.bells[msg.bell - 1].assigned_user = msg.user
//                if (msg.user === window.tower_parameters.cur_user_name){
//                    bell_circle.$refs.users.rotate_to_assignment()
//                }
//            } catch(err) {
//                console.log('caught error assign_user trying again')
//                setTimeout(100, function(){
//                    bell_circle.$refs.bells[msg.bell - 1].assigned_user = msg.user
//                    if (msg.user === window.tower_parameters.cur_user_name){
//                        bell_circle.$refs.users.rotate_to_assignment()
//                    }
//                })
//            }
//        })
//
//        // A call was made
//        socket.on('s_call',function(msg,cb){
//            console.log('Received call: ' + msg.call)
//            bell_circle.$refs.display.make_call(msg.call)
//        })
//
//        // The server told us the number of bells in the tower
//        socket.on('s_size_change', function(msg,cb){
//            var new_size = msg.size
//            bell_circle.number_of_bells = new_size
//        })
//
//
//        // The server sent us the global state set all bells accordingly
//        socket.on('s_global_state',function(msg,cb){
//            var gstate = msg.global_bell_state
//            for (var i = 0 i < gstate.length i++){
//                try {
//                    // This stochastically very error-prone:
//                    // Sometimes it sets the state before the bell is created
//                    // As such: try it, but if it doesn't work wait a bit and try again.
//                    bell_circle.$refs.bells[i].set_state_silently(gstate[i])
//                } catch(err) {
//                    console.log('caught error set_state trying again')
//                    setTimeout(100, function(){
//                        bell_circle.$refs.bells[i].set_state_silently(gstate[i])
//                    })
//                }
//            }
//        })
//
//        // The server told us whether to use handbells or towerbells
//        socket.on('s_audio_change',function(msg,cb){
//          console.log('changing audio to: ' + msg.new_audio)
//          bell_circle.$refs.controls.audio_type = msg.new_audio
//          bell_circle.audio = msg.new_audio == 'Tower' ? tower : hand
//          // Make sure the volume is set consistently
//          bell_circle.audio._volume = window.user_parameters.bell_volume * 0.1
//        })
//
//        // A chat message was received
//        socket.on('s_msg_sent', function(msg,cb){
//            bell_circle.$refs.chatbox.messages.push(msg)
//            if(msg.email != window.tower_parameters.cur_user_email && !$('#chat_input_box').is(':focus')) {
//                bell_circle.unread_messages++
//            }
//            bell_circle.$nextTick(function()
//                $('#chat_messages').scrollTop($('#chat_messages')[0].scrollHeight)
//            })
//        })
//
//        // Host mode was changed
//        socket.on('s_host_mode', function(msg,cb){
//            bell_circle.$refs.controls.host_mode = msg.new_mode
//        })
    }
    
    
    func connectSocket() {
        socket.connect()
    }
    
    func getStatus() {
        print(socket.status)
    }
    
}
