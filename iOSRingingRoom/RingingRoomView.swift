//
//  RingingRoomView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 08/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct RingingRoomView: View {
    @State var bellNumber = 1
    @State var towerParameters = [String:Any]()
    
    let tower_id:String
    
    @State var Manager:SocketIOManager!
    
    var body: some View {
        ZStack {
            //#d3d1dc
            Color(red: 211/255, green: 209/255, blue: 220/255)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 10) {
                Button(action: ringBell) {
                    
                    Text("ring")
                }.buttonStyle(touchDown())
                
                Stepper(value: $bellNumber, in: 1...8) {
                    Text("Bell selected: \(bellNumber)")
                        .font(.subheadline)
                        .padding(20)
                }
                Button(action: leaveTower) {
                    Text("Leave Tower")
                }
            }
        }
        .onAppear(perform: {
            self.connectToTower()
        })
    }
    
    struct touchDown:PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration
                .label
                .onLongPressGesture(minimumDuration: 0) {
                    configuration.trigger()
                    
            }
        }
    }
    
    func leaveTower() {
         NotificationCenter.default.post(name: Notification.Name(rawValue: "dismissRingingRoom"), object: nil)
    }
    
    func connectToTower() {
        }
        initializeManager()
        initializeSocket()
        joinTower()
    }
    
    func initializeManager() {
        Manager = SocketIOManager(server_ip: towerParameters["server_ip"] as! String)
        
    }
    
    func initializeSocket() {
        Manager.addListeners()
        Manager.connectSocket()
        Manager.getStatus()
    }
    
    func joinTower() {
        Manager.socket.emit("c_join", ["tower_id":towerParameters["id"],"user_token":towerParameters["user_token"],"anonymous_user":towerParameters["anonymous_user"]])
        print("hopefully joined tower")
    }
    
    func ringBell() {
        print(bellNumber)
        Manager.socket.emit("c_bell_rung", ["bell": bellNumber, "stroke": "handstroke", "tower_id": towerParameters["id"]])
        print("hopefully rang bell")
    }
    
}
