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
    var id:Int
    var towerName:String
    var serverURL:String
    
    @ObservedObject var bellCircle:BellCircle = BellCircle()
    
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

    @State var users = [String]()
    
    @State var isBookmarked = false
        
    @State var hostModeEnabled = false
    @State var permitHostMode = true
    
    @State var host:Bool = false
    
    @State var isShowingTowerControls = false
    @State var towerControlsView:TowerControlsView? = nil
    @State var towerControlsViewWidth:CGFloat = 0
    
    @State var audioPlayer:AVAudioPlayer?
    
    @State var Manager:SocketIOManager!
    
    var body: some View {
        ZStack {
            Color(red: 211/255, green: 209/255, blue: 220/255)
                .edgesIgnoringSafeArea(.all) //background view
            VStack(spacing: 10) {
                Spacer()
                GeometryReader { geo in
                    ZStack() {
                        ForEach(self.bellCircle.bells) { bell in
                            if self.bellCircle.bellPositions.count == self.bellCircle.size {
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
                                .disabled(self.hostModeEnabled ? self.host ? false : (self.bellCircle.assignments[bell.number - 1] == User.name) ? false : true : false)
                            }
                        }
                        GeometryReader { scrollGeo in
                            ScrollView(.vertical, showsIndicators: true) {
                                ForEach(self.bellCircle.bells) { bell in
                                    Text((self.bellCircle.assignments[bell.number - 1] == "") ? "" : "\(bell.number) \(self.bellCircle.assignments[bell.number - 1])")
                                        .font(.callout)
                                        .frame(maxWidth: geo.frame(in: .global).width - 100, alignment: .leading)
                                }
                            }.id(UUID().uuidString)
                                .frame(maxHeight: geo.frame(in: .global).height - 230)
                                .fixedSize(horizontal: true, vertical: true)
                                .position(self.bellCircle.center)
                        }
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
                                Color.white
                                Text("Bob")
                                    .foregroundColor(.black)
                            }
                        }
                        .disabled(self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? false : true : false)
                        .opacity(self.hostModeEnabled ? self.host ? 1 : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? 1 : 0.35 : 1)
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        
                        Button(action: self.makeCall("Single")) {
                            ZStack {
                                Color.white
                                Text("Single")
                                    .foregroundColor(.black)
                            }
                        }
                        .disabled(self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? false : true : false)
                        .opacity(self.hostModeEnabled ? self.host ? 1 : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? 1 : 0.35 : 1)
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("That's all")) {
                            ZStack {
                                Color.white
                                Text("That's all")
                                    .foregroundColor(.black)
                            }
                        }
                        .disabled(self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? false : true : false)
                        .opacity(self.hostModeEnabled ? self.host ? 1 : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? 1 : 0.35 : 1)
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
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
                        .disabled(self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? false : true : false)
                        .opacity(self.hostModeEnabled ? self.host ? 1 : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? 1 : 0.35 : 1)
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("Go")) {
                            ZStack {
                                Color.white
                                Text("Go next time")
                                    .foregroundColor(.black)
                                    .truncationMode(.tail)
                            }
                        }
                        .disabled(self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? false : true : false)
                        .opacity(self.hostModeEnabled ? self.host ? 1 : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? 1 : 0.35 : 1)
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("Stand next")) {
                            ZStack {
                                Color.white
                                Text("Stand next")
                                    .foregroundColor(.black)
                            }
                        }
                        .disabled(self.hostModeEnabled ? self.host ? false : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? false : true : false)
                        .opacity(self.hostModeEnabled ? self.host ? 1 : self.bellCircle.assignments.firstIndex(of: User.name) != nil ? 1 : 0.35 : 1)
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                    }
                    .frame(maxHeight: 35)
                    
                    HStack {
                        ForEach(self.bellCircle.bells.reversed()) { bell in
                            //     if !self.towerParameters.anonymous_user {
                            if self.bellCircle.assignments[bell.number - 1] == User.name {
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
                            }
                        }
                    }
                    .frame(maxHeight: 70)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                
            }
            .blur(radius: self.isShowingTowerControls ? 1 : 0)
            
            Color.primary.colorInvert().edgesIgnoringSafeArea(.all).opacity(0.9)
                .offset(x: self.isShowingTowerControls ? 0 : self.towerControlsViewWidth, y: 0)
            
            VStack {
                ZStack {
                    HStack {
                        Button(action: {
                            for bell in self.bellCircle.bells {
                                bell.stroke = .handstroke
                            }
                            
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
                        Button(action: {
                            self.isBookmarked.toggle()
                        }) {
                            Image(systemName: self.isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(.black)
                                .font(.title)
                                .scaleEffect(0.85)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text(self.towerName)
                            .font(Font.custom("Simonetta-Black", size: 35))
                            .lineLimit(1)
                            .layoutPriority(2)
                    }
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 60)
                }
                Spacer()
            }
            .padding()
            Group {
                if self.towerControlsView != nil {
                    towerControlsView!
                        .offset(x: self.isShowingTowerControls ? 0 : self.towerControlsViewWidth, y: 0)
                        .padding(.top, 75)
                }
            }
        }
        .onAppear(perform: {
            self.bellCircle.size = 8

            self.connectToTower()

            
            self.towerControlsView = TowerControlsView(towerID: self.id, hostModeEnabled: self.$hostModeEnabled, permitHostMode: self.permitHostMode, host: self.host, width: self.$towerControlsViewWidth, isBookmarked: self.$isBookmarked, manager: self.$Manager, size: .init(get: {self.bellCircle.size}, set: {self.bellCircle.size = $0}), bellType: .init(get: {self.bellCircle.bellType}, set: {self.bellCircle.bellType = $0}), assignments: .init(get: {self.bellCircle.assignments}, set: {self.bellCircle.assignments = $0}))
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
        joinTower()
    }
    
    func initializeManager() {
        Manager = SocketIOManager(server_ip: self.serverURL, ringingRoomView: self)
        
    }
    
    func initializeSocket() {
        Manager.addListeners()
        
        Manager.connectSocket()
        
        //  Manager.getStatus()
    }
    
    func joinTower() {
        print(CommunicationController.token!)
        Manager.socket.emit("c_join", ["tower_id":self.id, "user_token":CommunicationController.token!, "anonymous_user":false])
    }
    
    
    func ringBell(number:Int) -> () -> () {
        return {
            self.Manager.socket.emit("c_bell_rung", ["bell": number, "stroke": self.bellCircle.bells[number-1].stroke.rawValue ? "handstroke" : "backstroke", "tower_id": self.self.id])
        }
    }
    
    func bellRang(number:Int) {
        self.play(Bell.sounds[self.bellCircle.bellType]![self.bellCircle.size]![number-1].prefix((self.bellCircle.bellType == .hand) ? "H" : "T"), inDirectory: "RingingRoomAudio")
    }
    
    func makeCall(_ call:String) -> () -> () {
        return {
            self.Manager.socket.emit("c_call", ["call": call, "tower_id": self.self.id])
            self.play(call, inDirectory: "RingingRoomAudio")
        }
    }
    
    func getImage(_ number:Int) -> String {
        var imageName = ""
        
        if bellCircle.bellType == .tower {
            imageName += "t"
        } else {
            imageName += "h"
        }
        
        if bellCircle.bells[number-1].stroke == .handstroke {
            imageName += "-handstroke"
            
            if number == 1 {
                imageName += "-treble"
            }
            
        } else {
            imageName += "-backstroke"
        }
        
        
        
        return imageName
    }
    
    
    
    func play(_ fileName:String, inDirectory directory:String? = nil) {
        if let path = Bundle.main.path(forResource: fileName, ofType: ".m4a", inDirectory: directory) {
            let url = URL(fileURLWithPath: path)
            
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.play()
            }catch {
                print("Error")
            }
        }
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
    
    @State var towerID:Int
    
    @Binding var hostModeEnabled:Bool
    @State var permitHostMode:Bool
    @State var host:Bool
    
    @Binding var width:CGFloat
    
    @Binding var isBookmarked:Bool
    
    @Binding var manager:SocketIOManager!
        
    @State var users = ["Matthew Goodship", "Nigel", "James", "Leland", "Sarah", "Brynn", "Anthony"]
        
    @Binding var size:Int
    @Binding var bellType:BellType
    @Binding var assignments:[String]
    
    @State var towerSizeSelection = 0
    @State var bellTypeSelection = 0
    
    @State var selectedUser = 0
    
    @State var newAssigment = false
    
    @State var usersView:UsersView? = nil
    @State var chatView:ChatView? = nil
    
    @State var towerSelectionCount = 0
    @State var bellTypeSelectionCount = 0
    
    var towerSizes = [4, 6, 8, 10, 12]
    var bellTypes = [BellType.hand, BellType.tower]
    
    @State var showingUsers = false
    
    @State var viewOffset:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    @State var messageFieldYPosition:CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if self.host && self.permitHostMode {
                    Toggle(isOn: self.$hostModeEnabled) {
                        Text("Enable host mode")
                    }
                    .padding(.horizontal)
                }
                if !self.hostModeEnabled || self.host {
                    Picker(selection: self.$towerSizeSelection.onChange(self.sizeChanged), label: Text("Tower size picker")) {
                        ForEach(0..<5) { i in
                            Text(String(self.towerSizes[i]))
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                        .opacity(1)
                        .padding(.top, 10)
                        .pickerStyle(SegmentedPickerStyle())
                        .onAppear(perform: {
                            self.towerSizeSelection = self.towerSizes.firstIndex(of: self.size)!
                        })
                    Picker(selection: self.$bellTypeSelection.onChange(self.bellTypeChanged), label: Text("Bell type picker")) {
                        ForEach(0..<2) { i in
                            Text(self.bellTypes[i].rawValue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 7)
                    .pickerStyle(SegmentedPickerStyle())
                    .onAppear(perform: {
                        self.bellTypeSelection = self.bellTypes.firstIndex(of: self.bellType)!
                    })
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
                    Button(action:  { self.presentingHelp = true }) {
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
                self.usersView = UsersView(host: self.host, hostModeEnabled: self.hostModeEnabled, size: self.size, users: self.$users, assignments: self.$assignments)
                self.chatView = ChatView(messageFieldYPosition: self.$messageFieldYPosition)
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
    
    
    
    func leaveTower() {
        manager.socket.emit("c_user_left",
                            ["user_name": User.name,
                             "user_token": CommunicationController.token!,
                             "anonymous_user": false,
                             "tower_id": self.towerID])
        manager.socket.disconnect()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "dismissRingingRoom"), object: nil)
    }
    
    func bellTypeChanged(value:Int) {
        self.bellType = self.bellTypes[self.bellTypeSelection]
    }
    
    func sizeChanged(value:Int) {
        self.size = self.towerSizes[self.towerSizeSelection]
        if self.usersView != nil {
            print("trying to update")
            self.usersView!.size = self.size
        }
    }
    
}

struct UsersView:View {
    
    @State var showingUsers = false
    
    @State var host:Bool
    @State var hostModeEnabled:Bool
    
    var size:Int {
        didSet {
            self.updateView.toggle()
        }
    }
        
    @Binding var users:[String]
    
    @Binding var assignments:[String]
    
    @State var selectedUser = ""
    
    @State var updateView = false
    
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
                .padding(.leading, 7)
                    if available() {
                    Button(action: {
                        self.assignments = Array(repeating: "", count: self.size)
                        self.updateView.toggle()
                    }) {
                        Text("Unassign all")
                            .padding(7)
                    }
                    .foregroundColor(.white)
                    .background(Color.main.cornerRadius(5))
                }
            }
            if self.showingUsers {
                ScrollView(showsIndicators: false) {
                    
                    HStack(alignment: .top) {
                        VStack(spacing: 7) {
                            ForEach(self.users, id: \.self) { user in
                                RingerView(assignments: self.assignments, user: user, selectedUser: self.selectedUser)
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
                            ForEach(0..<self.size, id: \.self) { number in
                                HStack(alignment: .top) {
                                    if self.canUnassign(number)  {
                                            Button(action: {
                                                self.assignments[number] = ""
                                                self.updateView.toggle()
                                            }) {
                                                Text("x")
                                                    .foregroundColor(.black)
                                                    .font(.title)
                                            }
                                            .padding(.top, 1)
                                    }
                                    Button(action: self.assign(to: number)) {
                                        Text(String(number + 1))
                                            .font(.callout)
                                            .bold()
                                    }
                                    .modifier(BellAssigmentViewModifier(isAvailible: (self.assignments[number] == "")))
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
            self.selectedUser = User.name
        })
            .clipped()
            .padding(7)
            .background(Color.primary.colorInvert().cornerRadius(5))
    }
        
    func canUnassign(_ number:Int) -> Bool {
        return (self.assignments[number] != "") && (self.available() || self.assignments[number] == User.name)
    }

    func available() -> Bool {
        return self.host || !self.hostModeEnabled
    }
    
    func assign(to bell:Int) -> () -> () {
        return {
            self.assignments[bell] = self.selectedUser
            self.updateView.toggle()
        }
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
    
    @State var updateView = false
    
    @State var showingChat = false
    
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
            }
            if self.showingChat {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(0..<10) { number in
                            HStack {
                                Text("Matthew Goodship: \(number)")
                                Spacer()
                            }
                        }
                    }
                }
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
            
            
        .clipped()
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(Color.primary.colorInvert().cornerRadius(5))
    }
    
    func sendMessage() {
        //send message
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
                for i in 0...indexes.last! {
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
