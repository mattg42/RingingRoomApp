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
    var towerParameters:TowerParameters? = nil
        
    @ObservedObject var bellCircle:BellCircle = BellCircle()
        
    @State var setupComplete = false
    
    
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
                GeometryReader { geo in
                    ZStack(alignment: .topTrailing) {
                        ZStack() {
                            ForEach(self.bellCircle.bells) { bell in
                                if self.bellCircle.bellPositions.count == self.bellCircle.size {
                                    Button(action: self.ringBell(number: bell.number)) {
                                        HStack(spacing: CGFloat(6-self.bellCircle.size) - ((self.bellCircle.bellType == .hand) ? 1 : 0)) {
                                            Text(String(bell.number))
                                                .opacity((bell.side == .left) ? 1 : 0)
                                            Image(self.getImage(bell.number)).resizable()
                                               .aspectRatio(contentMode: ContentMode.fit)
                                                .frame(height: self.bellCircle.bellType == .hand ?  58 : 75)
                                                .rotation3DEffect(.degrees(self.bellCircle.bellType == .hand ? (bell.side == .left) ? 0 : 180 : 0), axis: (x: 0, y: 1, z: 0))
                                            Text(String(bell.number))
                                                .opacity((bell.side == .right) ? 1 : 0)
                                        }
                                    }.buttonStyle(touchDown())
                                    .position(self.bellCircle.bellPositions[bell.number-1])
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
                        
                        self.bellCircle.baseRadius = width/2
                        
                        self.bellCircle.center = CGPoint(x: width/2, y: height/2)
                        
                        self.setupComplete = true
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
                        .buttonStyle(touchDown())
                        
                        Button(action: self.makeCall("Single")) {
                            ZStack {
                                Color.white
                                Text("Single")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("That's all")) {
                            ZStack {
                                Color.white
                                Text("That's all")
                                    .foregroundColor(.black)
                            }
                        }
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
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                        Button(action: self.makeCall("Stand next")) {
                            ZStack {
                                Color.white
                                Text("Stand next")
                                    .foregroundColor(.black)
                            }
                        }
                        .cornerRadius(5)
                        .buttonStyle(touchDown())
                    }
                    .frame(maxHeight: 35)
                    
                    HStack {
                        ForEach(self.bellCircle.bells.reversed()) { bell in
                       //     if !self.towerParameters.anonymous_user {
                            if self.bellCircle.assignments[bell.number - 1] == self.towerParameters!.cur_user_name {
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
            Group {
                if self.towerControlsView != nil {
                    towerControlsView!
                    .offset(x: self.isShowingTowerControls ? 0 : self.towerControlsViewWidth, y: 0)
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: { withAnimation(self.isShowingTowerControls ? .easeIn : .easeOut) { print(self.bellCircle.assignments) ; self.isShowingTowerControls.toggle() ; print(self.bellCircle.assignments)} }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                            .padding(5)
                    }
                }
                }
                Spacer()
            }
            .padding()
        }
        .onAppear(perform: {
            if !(self.towerParameters == nil) {
               
                
                self.towerParameters!.cur_user_name = "Matthew Goodship"

                 self.towerControlsView = TowerControlsView(width: self.$towerControlsViewWidth, isBookmarked: self.$isBookmarked, manager: self.$Manager, towerParameters: self.towerParameters!, userName: self.towerParameters!.cur_user_name, size: .init(get: {self.bellCircle.size}, set: {self.bellCircle.size = $0}), bellType: .init(get: {self.bellCircle.bellType}, set: {self.bellCircle.bellType = $0}), assignments: .init(get: {self.bellCircle.assignments}, set: {self.bellCircle.assignments = $0}))
                
                self.bellCircle.size = self.towerParameters!.size
                self.bellCircle.userName = self.towerParameters!.cur_user_name
                self.bellCircle.assignments = self.towerParameters!.assignments
                
                print("before connecting to new tower size = ", self.bellCircle.bells.count)
                
                self.connectToTower()
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
        joinTower()
    }
    
    func initializeManager() {
        Manager = SocketIOManager(server_ip: towerParameters!.server_ip)
        
    }
    
    func initializeSocket() {
        Manager.addListeners()
        
        Manager.connectSocket()
        
        //  Manager.getStatus()
    }
    
    func joinTower() {
        Manager.socket.emit("c_join", ["tower_id":towerParameters!.id, "anonymous_user":towerParameters!.anonymous_user])
    }
    
    
    func ringBell(number:Int) -> () -> () {
        return {
            self.bellCircle.bells[number-1].stroke.toggle()
            self.Manager.socket.emit("c_bell_rung", ["bell": number, "stroke": self.bellCircle.bells[number-1].stroke.rawValue ? "handstroke" : "backstroke", "tower_id": self.towerParameters!.id])
            self.play(Bell.sounds[self.bellCircle.bellType]![self.bellCircle.size]![number-1].prefix((self.bellCircle.bellType == .hand) ? "H" : "T"), inDirectory: "RingingRoomAudio")
        }
    }
    
    func makeCall(_ call:String) -> () -> () {
        return {
            self.Manager.socket.emit("c_call", ["call": call, "tower_id": self.towerParameters!.id])
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
        
        if bellCircle.bells[number-1].stroke == .handstoke {
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

            self.audioPlayer = AVAudioPlayer()

            let url = URL(fileURLWithPath: path)

            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
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
    @Binding var width:CGFloat
            
    @Binding var isBookmarked:Bool
    
    @Binding var manager:SocketIOManager!
    
    var towerParameters:TowerParameters
    
    @State var users = ["Matthew Goodship", "Nigel", "James", "John", "Leland", "Sarah", "Brynn", "Anthony"]
    
    var userName:String
    
    @Binding var size:Int
    @Binding var bellType:BellType
    @Binding var assignments:[String]
    
    @State var towerSizeSelection = 0
    @State var bellTypeSelection = 0
    
    @State var selectedUser = 0
    
    @State var newAssigment = false
    
    @State var usersView:UsersView? = nil
    
    @State var towerSelectionCount = 0
    @State var bellTypeSelectionCount = 0
    
    var towerSizes = [4, 6, 8, 10, 12]
    var bellTypes = [BellType.hand, BellType.tower]
    
    @State var showingUsers = false
        
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 14.0) {
                Picker(selection: self.$towerSizeSelection.onChange(self.sizeChanged), label: Text("Tower size picker")) {
                    ForEach(0..<5) { i in
                        Text(String(self.towerSizes[i]))
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal)
                    }
                }
                    .opacity(1)
                .padding(.top, 70)
                .pickerStyle(SegmentedPickerStyle())
                .onAppear(perform: {
                    self.towerSizeSelection = self.towerSizes.firstIndex(of: self.size)!
                })
                Picker(selection: self.$bellTypeSelection.onChange(self.bellTypeChanged), label: Text("Bell type picker")) {
                    ForEach(0..<2) { i in
                        Text(self.bellTypes[i].rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onAppear(perform: {
                        self.bellTypeSelection = self.bellTypes.firstIndex(of: self.bellType)!
                })
                
                
                if self.usersView != nil {
                    self.usersView
                }
                
                Spacer()
                Button(action: self.leaveTower) {
                    Text("Leave Tower")
                        .foregroundColor(.red)
                }
            }
        .padding()
            .background(Color.primary.colorInvert().edgesIgnoringSafeArea(.all).opacity(0.9))
        .onAppear(perform: {
            self.width = geo.frame(in: .global).width
            print("controls width: ", self.width)
            print(self.userName)
            self.usersView = UsersView(size: self.size, userName:self.userName, users: self.$users, assignments: self.$assignments)
        })
        }

    }
    
    
    
    func leaveTower() {
        manager.socket.emit("c_user_left",
                            ["user_name": towerParameters.cur_user_name!,
                             "user_token": towerParameters.user_token!,
                             "anonymous_user": towerParameters.anonymous_user!,
                             "tower_id": towerParameters.id!])
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
    
    var size:Int {
        didSet {
            self.updateView.toggle()
        }
    }
    
    @State var userName:String
    
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
                    Image(systemName: self.showingUsers ? "chevron.down" : "chevron.right")
                        .animation(.linear)
                    Spacer()
                }
                .foregroundColor(.primary)
                Button(action: {
                    self.assignments = Array(repeating: "", count: self.size)
                    self.updateView.toggle()
                }) {
                    Text("Unassign all")
                    .padding(5)
                }
                .foregroundColor(.white)
                .background(Color.main.cornerRadius(5))
            }
            if self.showingUsers {
                HStack(alignment: .top) {
                    VStack(spacing: 8) {
                        ForEach(users, id: \.self) { user in
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
                            .onTapGesture(perform: {
                                self.selectedUser = user
                            })
                            
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: -5) {
                        ForEach(0..<self.size, id: \.self) { number in
                            HStack {
                                Button(action: self.assign(to: number)) {
                                    Text(String(number + 1))
                                    .bold()
                                }
                                .modifier(BellAssigmentViewModifier(isAvailible: (self.assignments[number] == "")))
                            }
                        }
                    }
                .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: {
            self.selectedUser = self.userName
        })
        .clipped()
        .padding()
        .background(Color.white.cornerRadius(5).shadow(color: .gray, radius: 20, x: 0, y: 0))
    }
    
    func assign(to bell:Int) -> () -> () {
        return {
            self.assignments[bell] = self.selectedUser
            self.updateView.toggle()
        }
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
                .padding(9)
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
