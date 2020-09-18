//
//  RingingRoomView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 08/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

struct RingingRoomView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    init(towerName:String, serverURL:String) {
        
        self.towerName = towerName
        self.serverURL = serverURL
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setPreferredIOBufferDuration(0.002)
            try audioSession.setCategory(.playback)
        } catch {
                print("error")
        }
    }
    
    var towerName:String
    var serverURL:String
    
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    var audioController = AudioController()
    
    @State var gotUserList = false
    @State var gotSize = false
    @State var gotBellType = false
    @State var gotHostMode = false
    @State var gotUserEntered = false
    @State var gotAssignments = false

    var setupComplete:Bool {
        get {
            gotSize && gotUserList && gotBellType && gotHostMode && gotUserEntered && gotAssignments
        }
        set {
            self.gotSize = newValue
            self.gotBellType = newValue
            self.gotHostMode = newValue
            self.gotUserList = newValue
            self.gotAssignments = newValue
            self.gotUserEntered = newValue
        }
    }
            
    @State var hostModeEnabled = false
    @State var permitHostMode = true
    
    @State var host:Bool = false
    
    @State var isShowingTowerControls = false
    @State var towerControlsView:TowerControlsView? = nil
    @State var towerControlsViewWidth:CGFloat = 0
    
    @State var audioPlayer:AVAudioPlayer!
    
    @State var cooldownSounds = [String]()
    @State var timers = [Timer]()
    
    @State var manager:SocketIOManager!
    
    @State var callText = ""
    @State var callTextOpacity = 0.0
    
    @State var callTimer:Timer?
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color.darkBackground
                .edgesIgnoringSafeArea(.all)
            } else {
                Color.lightBackground
                .edgesIgnoringSafeArea(.all)
            }
            //background view
            if setupComplete {
                ZStack {
                    VStack(spacing: 10) {
                        Spacer()
                        GeometryReader { geo in
                            ZStack() {
                                if self.bellCircle.bellPositions.count != 0 {
                                    ForEach(self.bellCircle.bells) { bell in
                                        Button(action: self.ringBell(number: bell.number)) {
                                            HStack(spacing: CGFloat(6-self.bellCircle.size) - ((self.bellCircle.bellType == .hand) ? 1 : -1)) {
                                                Text(String(bell.number))
                                                    .opacity((bell.side == .left) ? 1 : 0)
                                                Image(self.getImage(bell.number)).resizable()
                                                    .aspectRatio(contentMode: ContentMode.fit)
                                                    .frame(height: self.bellCircle.bellType == .hand ?  58 : 75)
                                                    .rotation3DEffect(.degrees(self.bellCircle.bellType == .hand ? (bell.side == .left) ? 0 : 180 : 0), axis: (x: 0, y: 1, z: 0))
                                                Text(String(bell.number))
                                                    .opacity((bell.side == .right) ? 1 : 0)
                                            }
                                        }
                                        .buttonStyle(touchDown())
                                        .position(self.bellCircle.bellPositions[bell.number-1])
                                        .disabled(self.hostModeEnabled ? self.host ? false : (self.bellCircle.assignments[bell.number - 1] == User.shared.name) ? false : true : false)
                                    }
                                }
                                GeometryReader { scrollGeo in
                                    ScrollView(.vertical, showsIndicators: true) {
                                        ForEach(self.bellCircle.bells) { bell in
                                            Text((self.bellCircle.assignments[bell.number - 1] == "") ? "" : "\(bell.number) \(self.bellCircle.assignments[bell.number - 1])")
                                                .foregroundColor(self.colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))
                                                .font(.callout)
                                                .frame(maxWidth: geo.frame(in: .global).width - 100, alignment: .leading)
                                        }
                                    }.id(UUID().uuidString)
                                        .frame(maxHeight: geo.frame(in: .global).height - 230)
                                        .fixedSize(horizontal: true, vertical: true)
                                        .position(self.bellCircle.center)
                                }
                                ZStack {
                                    Color.primary.colorInvert()
                                            .shadow(color: .white, radius: 10, x: 0, y: 0)
                                            .opacity(self.callTextOpacity/2)
                                        .cornerRadius(10)
                                        .blur(radius: 10, opaque: false)
                                    Text(self.callText)
                                        .font(.system(size: 60, weight: .bold))
                                     //   .foregroundColor(Color.init(white: 0.7))
                                        .opacity(self.callTextOpacity)
                                    .padding()
                                  //  .shadow(radius: 10)
                                }
                            .fixedSize()
                            }
                            .onAppear(perform: {
                                let height = geo.frame(in: .global).height
                                let width = geo.frame(in: .global).width
                                
                                self.bellCircle.baseRadius = width/2
                                
                                self.bellCircle.center = CGPoint(x: width/2, y: height/2)
                             })
                        }
                        .padding(.bottom, -40)
                        VStack {
                            HStack {
                                Button(action: self.makeCall("Bob")) {
                                    ZStack {
                                        Color.primary.colorInvert()
                                        Text("Bob")
                                            .foregroundColor(.primary)
                                    }
                                }
                            
                                .modifier(CallButtonViewModifier(disabled: self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.shared.name) != nil ? false : true : false))
                                .buttonStyle(touchDown())
                                
                                Button(action: self.makeCall("Single")) {
                                    ZStack {
                                        Color.primary.colorInvert()
                                        Text("Single")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .modifier(CallButtonViewModifier(disabled: self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.shared.name) != nil ? false : true : false))
                                .buttonStyle(touchDown())
                                Button(action: self.makeCall("That's all")) {
                                    ZStack {
                                        Color.primary.colorInvert()
                                        Text("That's all")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .modifier(CallButtonViewModifier(disabled: self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.shared.name) != nil ? false : true : false))
                                .buttonStyle(touchDown())
                            }
                            .frame(maxHeight: 35)
                            HStack {
                                Button(action: self.makeCall("Look to")) {
                                    ZStack {
                                        Color.primary.colorInvert()
                                        Text("Look to")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .modifier(CallButtonViewModifier(disabled: self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.shared.name) != nil ? false : true : false))
                                .buttonStyle(touchDown())
                                Button(action: self.makeCall("Go")) {
                                    ZStack {
                                        Color.primary.colorInvert()
                                        Text("Go")
                                            .foregroundColor(.primary)
                                            .truncationMode(.tail)
                                    }
                                }
                                .modifier(CallButtonViewModifier(disabled: self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.shared.name) != nil ? false : true : false))
                                .buttonStyle(touchDown())
                                Button(action: self.makeCall("Stand next")) {
                                    ZStack {
                                        Color.primary.colorInvert()
                                        Text("Stand")
                                            .foregroundColor(.primary)
                                    }
                                }
                            .modifier(CallButtonViewModifier(disabled: self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.shared.name) != nil ? false : true : false))
                                .buttonStyle(touchDown())
                            }
                            .frame(maxHeight: 35)
                            
                            HStack {
                                if self.bellCircle.assignments.contains(User.shared.name) {
                                    ForEach(self.bellCircle.bells.reversed()) { bell in
                                        //     if !self.towerParameters.anonymous_user {
                                        if self.bellCircle.assignments[bell.number - 1] == User.shared.name {
                                            Button(action: self.ringBell(number: (bell.number))) {
                                                ZStack {
                                                    Color.primary.colorInvert()
                                                    Text("\(bell.number)")
                                                        .foregroundColor(.primary)
                                                        .bold()
                                                }
                                            }
                                            .cornerRadius(5)
                                            .buttonStyle(touchDown())
                                            .frame(height: 70)
                                        }
                                    }
                                } else {
                                    Color.white.frame(height: 70).opacity(0)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                        
                    }
                 //   .blur(radius: self.isShowingTowerControls ? 1 : 0)
                    
                    Color.primary.colorInvert().edgesIgnoringSafeArea(.all).opacity(0.92)
                        .offset(x: self.isShowingTowerControls ? 0 : self.towerControlsViewWidth, y: 0)
                    
                    VStack {
                        ZStack {
                            HStack {
                                Button(action: {
                                    self.manager.socket.emit("c_set_bells", ["tower_id":self.bellCircle.towerID])
                                }) {
                                    VStack {
                                        Text("Set at")
                                        Text("hand")
                                    }
                                    .padding(5)
                                    .background(Color.main).cornerRadius(5)
                                }
                                .foregroundColor(.white)
                                Spacer()
                                Button(action: { withAnimation(self.isShowingTowerControls ? .easeIn : .easeOut) { print(self.bellCircle.assignments) ; self.isShowingTowerControls.toggle() ; print(self.bellCircle.assignments)} }) {
                                    Image(systemName: "line.horizontal.3")
                                        .font(.largeTitle)
                                        .foregroundColor(.primary)
                                        .padding(5)
                                }
                            }
                            
                            HStack {
                                VStack(spacing: 0) {
                                    
                                    Text(self.towerName)
                                        .font(Font.custom("Simonetta-Black", size: 35))
                                        .lineLimit(1)
                                        .layoutPriority(2)
                                        .scaleEffect(0.9)
                                        .padding(.vertical, -3)
                                        .padding(.horizontal, -15)
                             //       .background(Color.red)
                                    Text(String(bellCircle.towerID))
                                    .padding(.top, -5)

                                }
                        //        .background(Color.green)
                            }
                   //         .background(Color.blue)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 60)
                        }
                        .padding(.top, -10)
                        Spacer()
                    }
                    .padding()
                    Group {
                        if self.towerControlsView != nil {
                            towerControlsView!
                                .offset(x: self.isShowingTowerControls ? 0 : self.towerControlsViewWidth, y: 0)
                                .padding(.top, 65)
                        }
                    }
                }
            } else {
                /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
            }
        }
        .onAppear(perform: {
            print("performing on appear")
            self.towerControlsView = TowerControlsView(permitHostMode: self.permitHostMode, width: self.$towerControlsViewWidth, manager: self.$manager, towerSizeSelection: 0)
            self.connectToTower()
            
            //plays a silent sound on startup to remove initial audio delay
            if let path = Bundle.main.path(forResource: "Bob", ofType: ".aifc", inDirectory: "RingingRoomAudio") {
                let url = URL(fileURLWithPath: path)
                do {
                    self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                    self.audioPlayer.prepareToPlay()
                    self.audioPlayer.play(atTime: self.audioPlayer.duration)
                } catch {
                    print("Error")
                }
            }
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
    
    func connectToTower() {
        initializeManager()
        initializeSocket()
    }
    
    func initializeManager() {
        manager = SocketIOManager(server_ip: self.serverURL, ringingRoomView: self, towerControlsView: self.towerControlsView!)
        
    }
    
    func initializeSocket() {        
        manager.connectSocket()
        //  Manager.getStatus()
    }
    
    func joinTower() {
        print(CommunicationController.token!)
        manager.socket.emit("c_join", ["tower_id":self.bellCircle.towerID, "user_token":CommunicationController.token!, "anonymous_user":false])
    }
    
    func ringBell(number:Int) -> () -> () {
        return {
            let bellName = Bell.sounds[self.bellCircle.bellType]![self.bellCircle.size]![number - 1].prefix((self.bellCircle.bellType == .hand) ? "H" : "T")
            if !self.cooldownSounds.contains(bellName) {
                self.manager.socket.emit("c_bell_rung", ["bell": number, "stroke": self.bellCircle.bellStates[number-1] ? "handstroke" : "backstroke", "tower_id": self.bellCircle.towerID])
                self.cooldownSounds.append(bellName)
                let newTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                    self.cooldownSounds.remove(at: self.cooldownSounds.firstIndex(of: bellName)!)
                    self.timers.remove(at: self.timers.firstIndex(of: timer)!)
                }
                self.timers.append(newTimer)
            }
        }
    }
    
    func bellRang(number:String) {
        audioController.play(Bell.sounds[self.bellCircle.bellType]![self.bellCircle.size]![Int(number)!].prefix((self.bellCircle.bellType == .hand) ? "H" : "T"))
        bellCircle.objectWillChange.send()
        bellCircle.bellStates[Int(number)!].toggle()
    }
    
    func makeCall(_ call:String) -> () -> () {
        return {
            if !self.cooldownSounds.contains(call) {
                self.manager.socket.emit("c_call", ["call": call, "tower_id": self.bellCircle.towerID])
                self.cooldownSounds.append(call)
                print("timers, ",self.timers.count)
                let newTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                    self.cooldownSounds.remove(at: self.cooldownSounds.firstIndex(of: call)!)
                    self.timers.remove(at: self.timers.firstIndex(of: timer)!)
                }
                self.timers.append(newTimer)
            }
        }
    }
    
    func callMade(_ call:String) {
        audioController.play(call)
        self.callText = call
        self.callTextOpacity = 1
        self.callTimer?.invalidate()
        self.callTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { timer in
            withAnimation(.linear(duration: 0.4)) {
                self.callTextOpacity = 0
            }
        }
    }
    
    func getImage(_ number:Int) -> String {
        var imageName = ""
        
        if bellCircle.bellType == .tower {
            imageName += "t"
        } else {
            imageName += "h"
        }
        
        if bellCircle.bellStates[number-1] {
            imageName += "-handstroke"
            
            if number == 1 {
                imageName += "-treble"
            }
            
        } else {
            imageName += "-backstroke"
        }
        
        
        
        return imageName
    }
    
}

struct CallButtonViewModifier:ViewModifier {
    var disabled:Bool
    
    func body(content: Content) -> some View {
        content
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .cornerRadius(5)
    }
}

extension CGFloat {
    func radians() -> CGFloat {
        (self * CGFloat.pi)/180
    }
}

extension String {
    mutating func prefix(_ prefix:String) -> String {
        return prefix + self
    }
}

struct TowerControlsView:View {
    @State var presentingHelp = false
    
    @ObservedObject var bellCircle = BellCircle.current
    
    @State var permitHostMode:Bool
    
    @Binding var width:CGFloat
        
    @Binding var manager:SocketIOManager!
    
    @State var updateView = false
    
    @State var towerSizeSelection:Int {
        willSet {
            print("about to set to  ", newValue)
        }
        didSet {
            print("oldValue: ", oldValue, ", current value: ", self.towerSizeSelection)
        }
    }
    @State var bellTypeSelection = 0
    
    @State var selectedUser = 0
    
    @State var newAssigment = false
    
    @State var usersView:UsersView? = nil
    @State var chatView:ChatView? = nil
    
    @State var towerSelectionCount = 0
    @State var bellTypeSelectionCount = 0
    
    var bellTypes = [BellType.tower, BellType.hand]
    var towerSizes = [4, 6, 8, 10, 12]
    
    @State var showingUsers = false
    
    @State var viewOffset:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    @State var messageFieldYPosition:CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
                VStack(spacing: 0) {
                    Button(action: {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = String(self.bellCircle.towerID)
                    }) {
                        Text("Copy tower ID").foregroundColor(.main)
                    }
                    .foregroundColor(.primary)
                    if User.shared.host && self.permitHostMode {
                        Toggle(isOn: .init(get: {self.bellCircle.hostModeEnabled}, set: {
                            self.manager.socket.emit("c_host_mode", ["new_mode":$0, "tower_id":self.bellCircle.towerID])
                        }) ) {
                            Text("Enable host mode")
                        }
                        .padding(.horizontal)
                    }
                    if !self.bellCircle.hostModeEnabled || User.shared.host {
                        Picker(selection: .init(get: {(self.bellCircle.size-4)/2}, set: {self.sizeChanged(value:$0)}), label: Text("Tower size picker")) {
                            ForEach(0..<5) { i in
                                Text(String(self.towerSizes[i]))
                            }
                        }
                        .padding(.horizontal)
                            .opacity(1)
                            .padding(.top, 10)
                            .pickerStyle(SegmentedPickerStyle())
                        Picker(selection: .init(get: {self.bellTypes.firstIndex(of: self.bellCircle.bellType)!}, set: {self.bellTypeChanged(value:$0)}), label: Text("Bell type picker")) {
                            ForEach(0..<2) { i in
                                Text(self.bellTypes[i].rawValue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 7)
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    if self.usersView != nil {
                        self.usersView
                            .shadow(color: Color.gray.opacity(0.4), radius: 7, x: 0, y: 0)
                            .padding(.top, 10)
                            .padding(.horizontal)
                        //     .fixedSize(horizontal: false, vertical: true)

                    }

                    if self.chatView != nil {
                        self.chatView
                            .shadow(color: Color.gray.opacity(0.4), radius: 7, x: 0, y: 0)
                            .padding(.top, 10)
                            .padding(.horizontal)
                            .offset(x: 0, y: self.viewOffset)
                        //      .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                    HStack {
                        Button(action: self.leaveTower) {
                            Text("Leave Tower")
                                .foregroundColor(.main)
                        }
                        Spacer()
                        Button(action:  {
                            self.presentingHelp = true
                        }) {
                            Text("Help")
                        }
                        .sheet(isPresented: self.$presentingHelp) {
                            HelpView(asSheet: true, isPresented: self.$presentingHelp)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 7)
                }
                .onAppear(perform: {
                    self.width = geo.frame(in: .global).width
                    print("controls width: ", self.width)
                    self.usersView = UsersView(manager: self.manager)
//                    self.chatView = ChatView(manager: self.manager, messageFieldYPosition: self.$messageFieldYPosition)
                })
                    .onReceive(Publishers.keyboardHeight) {
                        self.keyboardHeight = $0
                        print(self.keyboardHeight)
                        let offset = self.keyboardHeight - self.messageFieldYPosition
                        print("offset: ",offset)
                        if offset <= 0 {
                            withAnimation(.easeIn(duration: 0.16)) {
                                self.viewOffset = 0
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.16)) {
                                self.viewOffset = -offset
                            }
                        }
                }
            
        }
        
        
    }
    
    func update() {
        self.updateView.toggle()
        print("updated tower controls")
    }
    
    func leaveTower() {
        manager.socket.emit("c_user_left",
                            ["user_name": User.shared.name,
                             "user_token": CommunicationController.token!,
                             "anonymous_user": false,
                             "tower_id": self.bellCircle.towerID])
        manager.socket.disconnect()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "dismissRingingRoom"), object: nil)
    }
    
    func bellTypeChanged(value:Int) {
        print("changing belltype")
        self.manager.socket.emit("c_audio_change", ["new_audio":self.bellTypes[value].rawValue, "tower_id":self.bellCircle.towerID])
     //
    }
    
    func sizeChanged(value:Int) {
        print(self.towerSizeSelection)
        self.manager.socket.emit("c_size_change", ["new_size":value*2+4, "tower_id":self.bellCircle.towerID])
    //    self.size = self.towerSizes[self.towerSizeSelection]
//        if self.usersView != nil {
//            print("trying to update")
//            self.usersView!.size = self.size
//        }
    }
    
}

struct UsersView:View {
    
    @State var showingUsers = true
            
    @ObservedObject var bellCircle = BellCircle.current
        
    @State var selectedUser = ""
    
    @State var updateView = false
    
    @State var manager:SocketIOManager!
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation(.linear) {
                        self.showingUsers.toggle()
                    }
                }) {
                    Text("Users")
                        .bold()
                    Image(systemName: self.showingUsers ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .animation(.linear)
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.leading, 4)
                .contentShape(Rectangle())
                    if available() {
                        Button(action: {
                            var tempUsers = self.bellCircle.users
                            for assignedUser in self.bellCircle.assignments {
                                if assignedUser != "" {
                                    if let index = tempUsers.firstIndex(of: assignedUser) {
                                        tempUsers.remove(at: index)
                                    }
                                }
                            }
                            for i in 0..<self.bellCircle.size {
                                if self.bellCircle.assignments[i] == "" {
                                    let index = Int.random(in: 0..<tempUsers.count)
                                    let user = tempUsers[index]
                                    self.manager.socket.emit("c_assign_user", ["user":user, "bell":i+1, "tower_id":self.bellCircle.towerID])
                                    tempUsers.remove(at: index)
                                }
                            }
                        }) {
                            Text("Fill In")
                                .padding(7)
                            .lineLimit(1)
                        }
                            .background(Color.main.cornerRadius(5))
                        .disabled(self.bellCircle.users.count < self.bellCircle.size)
                        .opacity(self.bellCircle.users.count < self.bellCircle.size ? 0.35 : 1)
                        .foregroundColor(.white)
                        
                    Button(action: {
                        for i in 0..<self.bellCircle.size {
                            self.unAssign(bell: i+1)
                        }
                    }) {
                        Text("Unassign all")
                            .padding(7)
                        .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .background(Color.main.cornerRadius(5))
                }
            }
            if self.showingUsers {
                ScrollView(showsIndicators: false) {
                    
                    HStack(alignment: .top) {
                        VStack(spacing: 7) {
                            ForEach(self.bellCircle.users, id: \.self) { user in
                                RingerView(assignments: self.bellCircle.assignments, user: user, selectedUser: self.selectedUser)
                                    .opacity(self.available() ? 1 : (user == self.selectedUser) ? 1 : 0.35)
                                .onTapGesture(perform: {
                                    if self.available() {
                                        self.selectedUser = user
                                    }
                                })

                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                        VStack(alignment: .trailing, spacing: -7) {
                            ForEach(0..<self.bellCircle.size, id: \.self) { number in
                                HStack(alignment: .top) {
                                    if self.canUnassign(number)  {
                                            Button(action: {
                                                self.unAssign(bell: number+1)
                                                self.updateView.toggle()
                                            }) {
                                                Text("x")
                                                    .foregroundColor(.primary)
                                                    .font(.title)
                                            }
                                            .padding(.top, 1)
                                    }
                                    Button(action: self.assign(self.selectedUser, to: number + 1)) {
                                        Text(String(number + 1))
                                            .font(.callout)
                                            .bold()
                                    }
                                    .modifier(BellAssigmentViewModifier(isAvailible: (self.bellCircle.assignments[number] == "")))
                                    //.background(.black)
                                }
                            }
                        }
                        .padding(.top, -6)
                    }
                }
                .padding(.top, -3)
                .padding(.horizontal, 7)
            }
        }
        .onAppear(perform: {
            print("users view initialized")
            self.selectedUser = User.shared.name
        })
            .clipped()
            .padding(7)
            .background(Color.primary.colorInvert().cornerRadius(5))
    }
        
    func canUnassign(_ number:Int) -> Bool {
        return (self.bellCircle.assignments[number] != "") && (self.available() || self.bellCircle.assignments[number] == User.shared.name)
    }

    func available() -> Bool {
        return User.shared.host || !self.bellCircle.hostModeEnabled
    }
    
    func assign(_ user:String, to bell:Int) -> () -> () {
        return {
            print("assigning")
            self.manager.socket.emit("c_assign_user", ["user":user, "bell":bell, "tower_id":self.bellCircle.towerID])
        }
    }
    
    func unAssign(bell:Int) {
        print("unassigning")
        manager.socket.emit("c_assign_user", ["user":"", "bell":bell, "tower_id":self.bellCircle.towerID])
    }
    
    
    
}

struct RingerView:View {
    
    var assignments:[String]
    var user:String
    var selectedUser:String
    
    var body: some View {
        HStack {
            Text(self.assignments.firstIndex(of: user) == nil ? "-" : self.getString(indexes: self.assignments.allIndexes(of: user)!))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(user)
                .fontWeight(user == self.selectedUser ? .bold : .regular)
                .lineLimit(1)
                .layoutPriority(2)
            Spacer()
        }
        .foregroundColor(user == self.selectedUser ? Color.main : Color.primary)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
    }
    
    func getString(indexes:[Int]) -> String {
        var str = ""
        for (index, number) in indexes.enumerated() {
            if index == 0 {
                str += String(number + 1)
            } else {
                str += ", \(number + 1)"
            }
        }
        return str
    }
}

struct ChatView:View {
    
    @State var manager:SocketIOManager!
    
    @State var updateView = false
    
    @State var showingChat = false {
        didSet {
            self.chatManager.canSeeMessages = self.showingChat
            if self.showingChat == true {
                self.chatManager.newMessages = 0
            }
        }
    }
    
    @ObservedObject var chatManager = ChatManager()
        
    @State var currentMessage = ""
        
    @Binding var messageFieldYPosition:CGFloat
    
    @State var viewOffset:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation(.linear) {
                        self.showingChat.toggle()
                    }
                }) {
                    Text("Chat")
                        .bold()
                    Image(systemName: self.showingChat ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .animation(.linear)
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.leading, 7)
                if chatManager.newMessages > 0 {
                    Text(String(chatManager.newMessages))
                    .padding(8)
                        .background(Circle().fill(Color.main))
                        .foregroundColor(.white)
                }
            }
            if self.showingChat {
                ScrollView {
                    VStack {
                        if chatManager.messages.count > 0 {
                            ForEach(chatManager.messages, id: \.self) { message in
                                HStack {
                                    Text(message)
                                    Spacer()
                                }
                            .flippedUpsideDown()
                            }
                        }
                    }
                }
                .flippedUpsideDown()
                HStack {
                    GeometryReader { geo in
                        TextField("Message", text: self.$currentMessage, onEditingChanged: { selected in
                            //  self.textFieldSelected = selected
                        })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .shadow(color: Color.white.opacity(0), radius: 1, x: 0, y: 0)
                            .onAppear(perform: {
                                var pos = geo.frame(in: .global).midY
                                pos += geo.frame(in: .global).height/2 + 25
                                print("pos", pos)
                                pos = UIScreen.main.bounds.height - pos
                                self.messageFieldYPosition = pos
                            })
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Button("Send") {
                        self.sendMessage()
                    }
                    .foregroundColor(Color.main)
                }
                .padding(.bottom, 7)
            }
        }
    .onAppear(perform: {
        self.manager.chatView = self
    })
            
        .clipped()
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(Color.primary.colorInvert().cornerRadius(5))
    }
    
    func sendMessage() {
        //send message
        chatManager.objectWillChange.send()
        chatManager.messages.append(currentMessage)
       // manager.socket.emit("c_msg_sent", ["user":User.name, "email":User.email, "msg":currentMessage, "tower_id":BellCircle.current.towerID])
        currentMessage = ""
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

extension Array {
    func allIndexes(of member:String) -> [Int]? {
        var strSelf = self as! [String]
        var finished = false
        var indexes = [Int]()
        if strSelf.firstIndex(of: member) != nil {
            while !finished {
                indexes.append(strSelf.firstIndex(of: member)!)
                for _ in 0...indexes.last! {
                    strSelf.removeFirst()
                }
                if indexes.count != 1 {
                    indexes[indexes.count - 1] += 1 + indexes[indexes.count - 2]
                }
                print(strSelf)
                if strSelf.firstIndex(of: member) == nil {
                    finished = true
                }
            }
        } else {
            return nil
        }
        return indexes
    }
}

struct BellAssigmentViewModifier:ViewModifier {
    var isAvailible:Bool
    func body(content: Content) -> some View {
        ZStack {
            Text("1")
                .font(.body)
                .padding(10)
                .opacity(0)
                .background(Circle().fill(Color.main))
                .foregroundColor(Color.main)
            content
                .disabled(isAvailible ? false : true)
                .animation(.linear(duration: 0.1))
                .foregroundColor(Color.white)
        }
        .opacity(isAvailible ? 1 : 0.35)
        .fixedSize(horizontal: true, vertical: true)
        
    }
}

struct RingingRoomView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}

struct FlippedUpsideDown: ViewModifier {
   func body(content: Content) -> some View {
    content
        .rotationEffect(Angle.init(radians: Double.pi))
      .scaleEffect(x: -1, y: 1, anchor: .center)
   }
}
extension View{
   func flippedUpsideDown() -> some View{
     self.modifier(FlippedUpsideDown())
   }
}

extension Color {
    static var lightBackground = Color(red: 211/255, green: 209/255, blue: 220/255)
    static var darkBackground = Color(white: 0.07)
}
