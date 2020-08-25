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
    var towerParameters:TowerParameters
    
    @ObservedObject var bellCircle = BellCircle()
    
    @State var center = CGPoint(x: 0, y: 0)
    
    @State var radius:CGFloat = 0
    
    @State var angleOffset:CGFloat = 20 {
        didSet {
            getBellPositions(center: center, radius: radius)
        }
    }
    
    @State var perspective = 1 {
        didSet {
            getBellPositions(center: center, radius: radius)
        }
    }
    
    @State var bellPositions = [CGPoint]()
    
    @State var setupComplete = false
    
    let tower_id:String
    
    @State var Manager:SocketIOManager!
    
    var body: some View {
        ZStack {
            Color(red: 211/255, green: 209/255, blue: 220/255)
                .edgesIgnoringSafeArea(.all) //background view
            VStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .topTrailing) {
                        ZStack() {
                            ForEach(self.bellCircle.bells) { bell in
                                if self.setupComplete {
                                    Button(action: self.ringBell(number: bell.number)) {
                                        HStack(spacing: CGFloat(12-self.bellCircle.size)) {
                                            Text(String(bell.number))
                                                .opacity((bell.side == .left) ? 1 : 0)
                                            Image(bell.stroke.rawValue ? ((bell.number == 1) ? "t-handstroke-treble" : "t-handstroke") :"t-backstroke").resizable()
                                                .frame(width: 25, height: 75)
                                            Text(String(bell.number))
                                                .opacity((bell.side == .right) ? 1 : 0)
                                        }
                                    }.buttonStyle(touchDown())
                                        .position(self.bellPositions[bell.number-1])
                                }
                            }
                            GeometryReader { scrollGeo in
                                ScrollView(.vertical, showsIndicators: true) {
                                    ForEach(self.bellCircle.bells) { bell in
                                        Text((bell.person == "") ? "" : "\(bell.number) \(bell.person)")
                                        .frame(maxWidth: geo.frame(in: .global).width - 100, alignment: .leading)
                                    }
                                }.id(UUID().uuidString)
                                .frame(maxHeight: geo.frame(in: .global).height - 220)
                                .fixedSize(horizontal: true, vertical: true)
                                .position(self.center)
                            }
                        }
                        Button(action: {print("menu")}) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title)
                                .foregroundColor(.black)
                        }
                        .padding()
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
                VStack {
                    HStack {
                        Button(action: self.makeCall("Bob")) {
                            ZStack {
                                Color.white
                                Text("Bob")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        
                        Button(action: self.makeCall("Single")) {
                            ZStack {
                                Color.white
                                Text("Single")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                        Button(action: self.makeCall("That's all")) {
                            ZStack {
                                Color.white
                                Text("That's all")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                    }
                    .frame(maxHeight: 35)
                    HStack {
                        Button(action: self.makeCall("Look to")) {
                            ZStack {
                                Color.white
                                Text("Look to")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                        Button(action: self.makeCall("Go")) {
                            ZStack {
                                Color.white
                                Text("Go next time")
                                    .foregroundColor(.black)
                                    .truncationMode(.tail)
                            }
                        }
                        .cornerRadius(5)

                        Button(action: self.makeCall("Stand next")) {
                            ZStack {
                                Color.white
                                Text("Stand next")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                    }
                    .frame(maxHeight: 35)
                    
                    HStack {
                        ForEach(self.bellCircle.bells.reversed()) { bell in
                       //     if !self.towerParameters.anonymous_user {
                                if bell.person == self.towerParameters.cur_user_name {
                                    Button(action: self.ringBell(number: (bell.number))) {
                                        ZStack {
                                            Color.primary.colorInvert()
                                            Text("\(bell.number)")
                                                .foregroundColor(.primary)
                                                .bold()
                                        }
                                    }
                                    .cornerRadius(5)
                                }
//                     /
                        }
                    }
                    .frame(maxHeight: 70)
                }
                .padding(.horizontal)
                .padding(.bottom)
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
        Manager.socket.emit("c_user_left",
                            ["user_name": towerParameters.cur_user_name!,
                             "user_token": towerParameters.user_token!,
                             "anonymous_user": towerParameters.anonymous_user!,
                             "tower_id": towerParameters.id!])
        Manager.socket.disconnect()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "dismissRingingRoom"), object: nil)
    }
    
    func connectToTower() {
        self.bellCircle.size = towerParameters.size
        var setPerseptive = false
        for i in 1...towerParameters.size {
            self.bellCircle.bells[i-1].person = self.towerParameters.assignments[i-1]
            if !setPerseptive && self.bellCircle.bells[i-1].person == self.towerParameters.cur_user_name {
                self.perspective = i
                setPerseptive = true
            }
        }
        initializeManager()
        initializeSocket()
        joinTower()
    }
    
    func initializeManager() {
        Manager = SocketIOManager(server_ip: towerParameters.server_ip)
        
    }
    
    func initializeSocket() {
        Manager.addListeners()
        
        Manager.connectSocket()
        
        //  Manager.getStatus()
    }
    
    func joinTower() {
        Manager.socket.emit("c_join", ["tower_id":towerParameters.id!, "anonymous_user":towerParameters.anonymous_user])
    }
    
    
    func ringBell(number:Int) -> () -> () {
        return {
            self.bellCircle.bells[number-1].stroke.toggle()
            self.Manager.socket.emit("c_bell_rung", ["bell": number, "stroke": self.bellCircle.bells[number-1].stroke.rawValue ? "handstroke" : "backstroke", "tower_id": self.towerParameters.id!])
        }
    }
    
    func makeCall(_ call:String) -> () -> () {
        return {
            self.Manager.socket.emit("c_call", ["call": call, "tower_id": self.towerParameters.id])
        }
    }
    
    func getBellPositions(center:CGPoint, radius:CGFloat) {
        bellPositions = [CGPoint]()
        let bellAngle = CGFloat(360)/CGFloat(self.bellCircle.size)
        
        let baseline = (360 + bellAngle*0.5)
        
        var currentAngle:CGFloat = baseline - bellAngle*CGFloat(perspective)
        
        for i in 0..<self.bellCircle.size {
            print(currentAngle)
            let bellXOffset = -sin(currentAngle.radians()) * radius
            let bellYOffset = cos(currentAngle.radians()) * radius
            bellPositions.append(CGPoint(x: center.x + bellXOffset, y: center.y + bellYOffset))
            
            if bellCircle.bells.count > 0 {
                bellCircle.bells[i].side = (180.0...360.0).contains(currentAngle) ? .left : .right
            }
            
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
