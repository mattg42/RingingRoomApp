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
    
    @State var assignmentLabelScaleFactor = 1
    
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
                        ZStack {
                            ForEach(self.bellCircle.bells) { bell in
                                if self.setupComplete {
                                    Button(action: self.ringBell(number: bell.number)) {
                                        HStack(spacing: CGFloat(12-self.bellCircle.size)) {
                                            Text(String(bell.number))
                                                .opacity((2...(self.bellCircle.size/2)+1).contains(bell.number) ? 0 : 1)
                                            Image(bell.stroke.rawValue ? ((bell.number == 1) ? "t-handstroke-treble" : "t-handstroke") :"t-backstroke").resizable()
                                                .frame(width: 25, height: 75)
                                            Text(String(bell.number))
                                                .opacity((2...(self.bellCircle.size/2)+1).contains(bell.number) ? 1 : 0)
                                        }
                                    }.buttonStyle(touchDown())
                                        .position(self.bellPositions[bell.number-1])
                                }
                            }
                            VStack(alignment: .leading) {
                                ForEach(self.bellCircle.bells) { bell in
                                    Text("\(bell.number) \(bell.person)")
                                        .opacity(((bell.person) == "") ? 0 : 1)
                                        .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                                }
                                .minimumScaleFactor(0.5)
                            }
                            .frame(width: geo.frame(in: .global).width,height: geo.frame(in: .global).height - 185)
                         //   .scaleEffect(0.6)
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
                        Button(action: {print("")}) {
                            ZStack {
                                Color.white
                                Text("Bob")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        
                        Button(action: {print("")}) {
                            ZStack {
                                Color.white
                                Text("Single")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                        Button(action: {print("")}) {
                            ZStack {
                                Color.white
                                Text("Thats all")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                    }
                    .frame(maxHeight: 35)
                    HStack {
                        Button(action: {
                            self.bellCircle.size = 8
                            self.getBellPositions(center: self.center, radius: self.radius)
                        }) {
                            ZStack {
                                Color.white
                                Text("Look to")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                        Button(action: {self.bellCircle.bells[4].person = "Nigel"}) {
                            ZStack {
                                Color.white
                                Text("Go next time")
                                    .foregroundColor(.black)
                                    .truncationMode(.tail)
                            }
                        }
                        .cornerRadius(5)

                        Button(action: {self.bellCircle.bells[3].person = "Nigeljhkfjdhfkjshdfkjhslkdjf"}) {
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
                        Button(action: {self.bellCircle.bells[5].person = "Nigel"}) {
                            ZStack {
                                Color.white
                                Text("Left")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

                        
                        Button(action: {self.bellCircle.bells[5].person = "Matthew Goodship"}) {
                            ZStack {
                                Color.white
                                Text("Right")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)

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
        for i in 1...towerParameters.size {
            self.bellCircle.bells.append(Bell(number: i, stroke: .handstoke, person: self.towerParameters.assignments[i-1]))
        }
        self.bellCircle.size = towerParameters.size
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
    
    func getBellPositions(center:CGPoint, radius:CGFloat) {
        bellPositions = [CGPoint]()
        let bellAngle = CGFloat(360)/CGFloat(self.bellCircle.size)
        
        var currentAngle:CGFloat = (360 - bellAngle/2)
        
        for _ in 1...self.bellCircle.size {
            print(currentAngle)
            let bellXOffset = -sin(currentAngle.radians()) * radius
            let bellYOffset = cos(currentAngle.radians()) * radius
            bellPositions.append(CGPoint(x: center.x + bellXOffset, y: center.y + bellYOffset))
            
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
