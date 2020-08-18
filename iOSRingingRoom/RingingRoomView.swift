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
    @ObservedObject var bellCircle = BellCircle()
    @State var center = CGPoint(x: 0, y: 0)
    @State var radius:CGFloat = 0
    @State var bellPositions = [CGPoint]()
    
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
                GeometryReader { geo in
                        ZStack {
                            ForEach(self.bellCircle.bells) { bell in
                                if self.setupComplete {
                                    Button(action: self.ringBell(number: bell.number)) {
                                        HStack(spacing: CGFloat(12-self.bellCircle.size)) {
                                            Image(bell.stroke.rawValue ? ((bell.number == 1) ? "t-handstroke-treble" : "t-handstroke") :"t-backstroke").resizable()
                                                .frame(width: 25, height: 75)
                                        }
                                    }.buttonStyle(touchDown())
                                        .position(self.bellPositions[bell.number-1])
                                }
                            }
                        }
                    }
                    .onAppear(perform: {
                        let height = geo.frame(in: .global).height
                        let width = geo.frame(in: .global).width
                        
                        self.radius = width/2 - 20
                        
                        self.center = CGPoint(x: width/2, y: height/2)
                        self.getBellPositions(center: self.center, radius: self.radius)
                    })
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
        Manager = SocketIOManager(server_ip: towerParameters.server_ip)
        
    }
    
    func initializeSocket() {
        Manager.addListeners()
        Manager.connectSocket()
        Manager.getStatus()
    }
    
    func joinTower() {
        Manager.socket.emit("c_join", ["tower_id":towerParameters["id"],"user_token":towerParameters["user_token"],"anonymous_user":towerParameters["anonymous_user"]])
        Manager.socket.emit("c_join", ["tower_id":towerParameters.id!, "anonymous_user":towerParameters.anonymous_user])
    }
    
    func ringBell() {
        print(bellNumber)
        Manager.socket.emit("c_bell_rung", ["bell": bellNumber, "stroke": "handstroke", "tower_id": towerParameters["id"]])
        print("hopefully rang bell")
    }
    
        bellPositions = [CGPoint]()
        let bellAngle = CGFloat(360)/CGFloat(self.bellCircle.size)
        
        var currentAngle:CGFloat = (360 - bellAngle/2)
        
        for _ in 1...self.bellCircle.size {
            print(currentAngle)
            let bellXOffset = -sin(currentAngle.radians()) * radius
            let bellYOffset = cos(currentAngle.radians()) * radius
            bellPositions.append(CGPoint(x: center.x + bellXOffset, y: center.y + bellYOffset))
            
            let numberXOffset = -sin(currentAngle.radians()) * (radius - 60)
            let numberYOffset = cos(currentAngle.radians()) * (radius - 60)
            numberPositions.append(CGPoint(x: center.x + numberXOffset, y: center.y + numberYOffset))
            
            currentAngle += bellAngle
            
            if currentAngle > 360 {
                currentAngle -= 360
            }
            
        }
        print(bellPositions.count)
        
        for pos in bellPositions {
            print(pos)
        }
        setupComplete = true
    }
}

extension CGFloat {
    func radians() -> CGFloat {
        (self * CGFloat.pi)/180
    }
}
