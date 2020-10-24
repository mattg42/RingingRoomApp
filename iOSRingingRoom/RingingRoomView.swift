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

    var backgroundColor:Color {
        get {
            if colorScheme == .light {
                return Color(red: 211/255, green: 209/255, blue: 220/255)
            } else {
                return Color(white: 0.085)
            }
        }
    }
    
    init() {
        print("new ringingroom view")
    }
    
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    var manager = SocketIOManager.shared
    
    @ObservedObject var chatManager = ChatManager.shared
    
    @State var showingTowerControls = false
    
    @State var titleHeight:CGFloat = 0
    
    var ringingView = RingingView()
    
    @State var text = ""
    
    @State var towerControls = TowerControlsView()
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            ringingView
                .padding(.top, titleHeight)

            Color.primary.colorInvert().edgesIgnoringSafeArea(.all)
                .offset(x: showingTowerControls ? 0 : -UIScreen.main.bounds.width, y: 0)
            towerControls
                .padding(.top, titleHeight)
                .padding(.horizontal, 5)
                .offset(x: showingTowerControls ? 0 : -UIScreen.main.bounds.width, y: 0)
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack {
                        Rectangle()
                            .fill(Color.main)
                            .cornerRadius(5)
                        Text(bellCircle.towerName)
                        .colorInvert()
                        .font(Font.custom("Simonetta-Black", size: 30))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .scaleEffect(0.9)
                        .padding(.vertical, 4)
                    }
//                    .padding(.top, -5)
                    .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 5)
                    .onAppear {
                        self.titleHeight = geo.frame(in: .global).midY * 2
                    }
                }
                .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                Spacer()
            }
            VStack {
                HStack {
                    Spacer()
                    if chatManager.newMessages > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.main)
                                .frame(width: 27, height: 27)
                            Text(String(chatManager.newMessages))
                                .foregroundColor(.white)
                                .bold()
                        }
                    }
                    Button(action: {
                        withAnimation {
                            self.showingTowerControls.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.largeTitle)
                            //                                            .bold()
                            .foregroundColor(.primary)
                            .padding(5)
                    }
                }
                Spacer()

            }
            .padding(.top, titleHeight)

        }
    }
    
}

struct RingingView:View {
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    var manager = SocketIOManager.shared
    
    init() {
        print("new ringingView")
    }
    
    var ropeCircle = RopeCircle()
    
    var body: some View {
        VStack {
            Spacer()
            ropeCircle
            Spacer()
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    Button(action: {
                        makeCall("Bob")
                    }) {
                        CallButton(call: "Bob")

                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                    Button(action: {
                        makeCall("Single")
                    }) {
                        CallButton(call: "Single")

                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                    Button(action: {
                        makeCall("That's all")
                    }) {
                        CallButton(call: "That's all")

                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                }
                HStack(spacing: 5.0) {
                    Button(action: {
                        makeCall("Look to")
                    }) {
                        CallButton(call: "Look to")

                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                    Button(action: {
                        makeCall("Go")
                    }) {
                        CallButton(call: "Go")

                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                    Button(action: {
                        makeCall("Stand next")
                    }) {
                        CallButton(call: "Stand")

                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                }
                if bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                    HStack(spacing: 5.0) {
                        ForEach(0..<bellCircle.size, id: \.self) { i in
                            if bellCircle.assignments[bellCircle.size-1-i].userID == User.shared.ringerID {
                                Button(action: {
                                    ringBell(bellCircle.size-i)
                                }) {
                                    RingButton(number: String(bellCircle.size-i))
                                }
                                .buttonStyle(TouchDown(isAvailible: true))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 5)
            
        }
        .onAppear {
            print("ringingview appeared")
        }
        .onDisappear {
            print("ringingview disappeared")
        }
    }
    
    func makeCall(_ call:String) {
        manager.socket.emit("c_call", ["call":call, "tower_id":bellCircle.towerID])

    }
    
    func ringBell(_ number:Int) {
        manager.socket.emit("c_bell_rung", ["bell": number, "stroke": (bellCircle.bellStates[number - 1]), "tower_id": bellCircle.towerID])
//        bellCircle.timer.tolerance = 0
//        bellCircle.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true, block: { _ in
//            bellCircle.counter += 1
//        })
    }
    
}

struct CallButton:View {
    
    var call:String
    
    var body: some View {
        ZStack {
            Color.primary.colorInvert().cornerRadius(5)
            Text(call)
                .foregroundColor(.primary)
                
        }
        .frame(maxHeight: 35)
    }
}

struct RingButton:View {
    
    var number:String
    
    var body: some View {
        ZStack {
            Color.primary.colorInvert().cornerRadius(5)
            Text(number)
                .foregroundColor(.primary)
                .bold()
        }
        .frame(maxHeight: 70)
    }
}

struct RopeCircle:View {
    
    @Environment(\.colorScheme) var colorScheme

    init() {
        print("rope circle")
    }
    
    var backgroundColor:Color {
        get {
            if colorScheme == .light {
                return Color(red: 211/255, green: 209/255, blue: 220/255)
            } else {
                return Color(white: 0.085)
            }
        }
    }
    
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    @State private var manager = SocketIOManager.shared
    
    var test = 1
        
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if bellCircle.gotBellPositions {
                    ForEach(0..<bellCircle.size, id: \.self) { bellNumber in
                        Button(action: {
                            self.ringBell(bellNumber+1)
                        }) {
                            HStack(spacing: 0) {
                                Text(String(bellNumber+1))
                                    .opacity(bellCircle.bellPositions[bellNumber].side == .left ? 0 : 1)
                                Image(self.getImage(bellNumber)).resizable()
                                    .frame(width: (bellCircle.bellType == .tower) ? 25 : 60, height: (bellCircle.bellType == .tower) ? 75 : 60)
                                    .rotation3DEffect(
                                        .degrees( (bellCircle.bellType == .tower) ? 0 : bellCircle.bellPositions[bellNumber].side == .left ? 180 : 0),
                                        axis: (x: 0.0, y: 1.0, z: 0.0),
                                        anchor: .center,
                                        perspective: 1.0
                                    )
                                    .padding(.horizontal, (bellCircle.bellType == .tower) ? 0 : -5)
                                Text(String(bellNumber+1))
                                    .opacity(bellCircle.bellPositions[bellNumber].side == .right ? 0 : 1)
                            }
                        }
                        .buttonStyle(TouchDown(isAvailible: true))
                        .foregroundColor(.primary)
                        .position(bellCircle.bellPositions[bellNumber].pos)
                    }
                    VStack {
                        ForEach(0..<bellCircle.assignments.count, id: \.self) { i in
                            HStack {
                                Text("\(i+1)")
                                    .font(.callout)
                                    .frame(width: 18, height:18, alignment: .trailing)
                                Text(" \(self.bellCircle.assignments[i].name)")
                                    .font(.callout)
                                    .frame(width: 155, height:18, alignment: .leading)
                            }
                            .foregroundColor(self.colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))

                        }
                    }
                    .position(bellCircle.center)
                        ZStack {
                            backgroundColor
                                .cornerRadius(15)
                                .blur(radius: 15, opaque: false)
                                .shadow(color: backgroundColor, radius: 10, x: 0.0, y: 0.0)
//                                .opacity(bellCircle.currentCall != "" ? 0.9 : 0)
                                .opacity(0.9)
//                            if bellCircle.currentCall != "" {

                            Text(bellCircle.currentCall)
                                .font(.largeTitle)
                                .bold()
                                .padding()
//                                .opacity(bellCircle.currentCall != "" ? 1 : 0)
//                                .background(backgroundColor)
//                                                    }
                        }
                        .opacity(bellCircle.callTextOpacity)
                        .fixedSize()
                }
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            SocketIOManager.shared.socket.emit("c_set_bells", ["tower_id":bellCircle.towerID])
                        }) {
                            ZStack {
                                Color.main.cornerRadius(5)
                                VStack {
                                    Text("Set at")
                                        .bold()
                                    Text("hand")
                                        .bold()
                                }
                                .foregroundColor(.white)
                                    .padding(3)
                            }
                            .fixedSize()
                        }
                        .padding(.bottom, -2)
                        .padding(.leading, 5)
                        Spacer()
                    }
                }
            }
            .onAppear {
                var center = CGPoint(x: geo.frame(in: .global).midX, y: geo.frame(in: .local).midY)
                center.y -= 23
                if center.y > 100 && center.x > 100 {
                    print(bellCircle.assignments)
                    if !bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
//                        print("reduced")
                        center.y -= 35
                    }
                    print("from .onappear")
                    bellCircle.center = center
                    bellCircle.baseRadius = CGFloat(UIScreen.main.bounds.width/2)
                    bellCircle.baseRadius = min(bellCircle.baseRadius, 340)
                    bellCircle.getNewPositions(radius: bellCircle.radius, center: bellCircle.center)
                }
            }
        }
    }
    
    func ringBell(_ number:Int) {
        manager.socket.emit("c_bell_rung", ["bell": number, "stroke": (bellCircle.bellStates[number - 1]), "tower_id": bellCircle.towerID])
//        bellCircle.timer.tolerance = 0
//        bellCircle.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true, block: { _ in
//            bellCircle.counter += 1
//        })
    }
    
    func getImage(_ number:Int) -> String {
           var imageName = bellCircle.bellType.rawValue.first!.lowercased() + "-" + (bellCircle.bellStates[number] ? "handstroke" : "backstroke")
        if imageName.first! == "t" && number == 0 && bellCircle.bellStates[number] {
            imageName += "-treble"
        }
        return imageName
    }
    
}

struct TouchDown: PrimitiveButtonStyle {
    var isAvailible:Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration
      .label
      .onLongPressGesture(
        minimumDuration: 0,
        perform: configuration.trigger
      )
        .opacity(isAvailible ? 1 : 0.35)
        .disabled(!isAvailible)
  }
}


extension CGFloat {
    func radians() -> CGFloat {
        (self * CGFloat.pi)/180
    }
}

extension String {
    func prefix(_ prefix:String) -> String {
        return prefix + self
    }
}

struct TowerControlsView:View {
    @State private var presentingHelp = false

    @ObservedObject var bellCircle = BellCircle.current

    @State private var permitHostMode:Bool = false

    @State private var updateView = false

    @State private var bellTypeSelection = 0

    @State private var selectedUser = 0

    @State private var newAssigment = false

    @State private var selectedView = 1

    @State private var towerSelectionCount = 0
    @State private var bellTypeSelectionCount = 0

    var bellTypes = [BellType.tower, BellType.hand]
    var towerSizes = [4, 6, 8, 10, 12]

    @State private var showingUsers = false

    @State private var viewOffset:CGFloat = 0
    @State private var keyboardHeight:CGFloat = 0
    @State private var messageFieldYPosition:CGFloat = 0

    init() {
        print("new towerControls")
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Picker(selection: .init(get: {self.bellTypes.firstIndex(of: self.bellCircle.bellType)!}, set: {self.bellTypeChanged(value:$0)}), label: Text("Bell type picker")) {
                        ForEach(0..<2) { i in
                            Text(self.bellTypes[i].rawValue)
                        }
                    }
                    .fixedSize()
                    //                            .padding(.horizontal)
                    //                            .padding(.top, 7)
                    .pickerStyle(SegmentedPickerStyle())
                    Text(String(bellCircle.towerID))
                    Button(action: {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = String(self.bellCircle.towerID)
                    }) {
                        Text("Copy")
                    }
                    .foregroundColor(.main)
                    Spacer()
                }
                .padding(.bottom, 3)
                if !self.bellCircle.hostModeEnabled || bellCircle.isHost {
                    HStack {


                        Picker(selection: .init(get: {(self.bellCircle.size-4)/2}, set: {self.sizeChanged(value:$0)}), label: Text("Tower size picker")) {
                            ForEach(0..<5) { i in
                                Text(String(self.towerSizes[i]))
                            }
                        }
                        //                            .fixedSize()
                        //                            .padding(.horizontal)
                        //                                .padding(.top, 10)
                        .pickerStyle(SegmentedPickerStyle())

                    }
                    .padding(.top, 5)
                    .padding(.bottom, -6)
                }
                if bellCircle.isHost && self.permitHostMode {
                    Toggle(isOn: .init(get: {self.bellCircle.hostModeEnabled}, set: { newValue in
                        SocketIOManager.shared.socket.emit("c_host_mode", ["new_mode":newValue, "tower_id":self.bellCircle.towerID])
                    }) ) {
                        Text("Enable host mode")
                    }
                }

                    TabView(selection: $selectedView) {
                        UsersView(selectedView: $selectedView)
                            .shadow(color: Color.gray.opacity(0.4), radius: 7, x: 0, y: 0)
                            .padding(.vertical)
                            .padding(.bottom, 35)
                            .tag(1)
                            .padding(.horizontal, 5)

                        ChatView(selectedView: $selectedView)
                            .shadow(color: Color.gray.opacity(0.4), radius: 7, x: 0, y: 0)
                            .padding(.horizontal, 5)
                            .padding(.vertical)
                            .padding(.bottom, 35)
                            .tag(2)
                    }
                    .padding(.horizontal, -5)
                    .onChange(of: selectedView, perform: { _ in
                        if selectedView == 1 {
                            ChatManager.shared.canSeeMessages = false
                        } else {
                            withAnimation {
                                ChatManager.shared.canSeeMessages = true
                            }
                        }
                    })
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            VStack {
                Spacer()
                HStack {
                    Button(action: self.leaveTower) {
                        Text("Leave Tower")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                    }
                    .background(Color.main.cornerRadius(5))
                    Spacer()
                    Button(action:  {
                        self.presentingHelp = true
                    }) {
                        Text("Help")
                            .bold()
                    }
                    .sheet(isPresented: self.$presentingHelp) {
                        HelpView(asSheet: true, isPresented: self.$presentingHelp)
                    }
                }
            }
            .padding(.bottom, 12)
//            .onReceive(Publishers.keyboardHeight) {
//                self.keyboardHeight = $0
//                print(self.keyboardHeight)
//                let offset = self.keyboardHeight - self.messageFieldYPosition
//                print("offset: ",offset)
//                if offset <= 0 {
//                    withAnimation(.easeIn(duration: 0.24)) {
//                        self.viewOffset = 0
//                    }
//                } else {
//                    withAnimation(.easeOut(duration: 0.35)) {
//                        self.viewOffset = -offset
//                    }
//                }
//            }
        }
    }

    func update() {
        self.updateView.toggle()
        print("updated tower controls")
    }

    func leaveTower() {
        SocketIOManager.shared.leaveTower()
    }

    func bellTypeChanged(value:Int) {
        print("changing belltype")
        SocketIOManager.shared.socket.emit("c_audio_change", ["new_audio":self.bellTypes[value].rawValue, "tower_id":self.bellCircle.towerID])
     //
    }

    func sizeChanged(value:Int) {
        SocketIOManager.shared.socket.emit("c_size_change", ["new_size":value*2+4, "tower_id":self.bellCircle.towerID])
    //    self.size = self.towerSizes[self.towerSizeSelection]
//        if self.usersView != nil {
//            print("trying to update")
//            self.usersView!.size = self.size
//        }
    }

}

struct UsersView:View {

//    @State private var showingUsers:Bool

    @ObservedObject var bellCircle = BellCircle.current

    @Environment(\.colorScheme) var colorScheme

    @State private var selectedUser = 0

    @Binding var selectedView:Int

    @State private var updateView = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Users")
                    .font(.title3)
                    .fontWeight(.heavy)
//                    .bold()
                    .padding(.leading, 4)
                Spacer()
                if available() {
                    Button(action: {
                        var tempUsers = self.bellCircle.users
                        for assignedUser in self.bellCircle.assignments {
                            if assignedUser.name != "" {
                                tempUsers.removeRingerForID(assignedUser.userID)
                            }
                        }
                        for i in 0..<self.bellCircle.size {
                            if self.bellCircle.assignments[i].name == "" {
                                let index = Int.random(in: 0..<tempUsers.count)
                                let user = tempUsers[index]
                                SocketIOManager.shared.socket.emit("c_assign_user", ["user":user.name, "bell":i+1, "tower_id":self.bellCircle.towerID])
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
                            .foregroundColor(.white)
                            .background(Color.main.cornerRadius(5))
                            .lineLimit(1)
                    }

                }
                Button(action: {
                    withAnimation {
                        self.selectedView = 2
                    }
                }) {
                    Text("Chat")
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.main)
            }
//            if self.showingUsers {
                ScrollView(showsIndicators: false) {

                    HStack(alignment: .top) {
                        VStack(spacing: 7) {
                            ForEach(self.bellCircle.users) { user in
                                RingerView(user: user, selectedUser: (self.selectedUser == user.userID))
                                    .opacity(self.available() ? 1 : (user.userID == self.selectedUser) ? 1 : 0.35)
                                    .onTapGesture(perform: {
                                        if self.available() {
                                            self.selectedUser = user.userID
                                        }
                                    })

                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 9)
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
                                    .modifier(BellAssigmentViewModifier(isAvailible: (self.bellCircle.assignments[number].name == "")))
                                    //.background(.black)
                                }
                            }
                        }
                        .padding(.horizontal, 7)
                        .background(Color(white: (self.colorScheme == .light) ? 0.86 : 0.13).cornerRadius(5))
                    }
                }
//                .padding(.top, 2)
                .padding(.horizontal, 7)
//            }
        }
        .onAppear(perform: {
            print("users view initialized")
            self.selectedUser = User.shared.ringerID
        })
        .clipped()
        .padding(7)
        .background(Color.primary.colorInvert().cornerRadius(5))
    }

    func canUnassign(_ number:Int) -> Bool {
        if self.bellCircle.assignments.count == bellCircle.size {
            return (self.bellCircle.assignments[number].name != "") && (self.available() || self.bellCircle.assignments[number].name == User.shared.name)
        } else {
            return false
        }
    }

    func available() -> Bool {
        return bellCircle.isHost || !self.bellCircle.hostModeEnabled
    }

    func assign(_ id:Int, to bell:Int) -> () -> () {
        return {
            print("assigning")
            SocketIOManager.shared.socket.emit("c_assign_user", ["user":id, "bell":bell, "tower_id":self.bellCircle.towerID])
        }
    }

    func unAssign(bell:Int) {
        print("unassigning")
        SocketIOManager.shared.socket.emit("c_assign_user", ["user":0, "bell":bell, "tower_id":self.bellCircle.towerID])
    }



}

struct RingerView:View {

    var user:Ringer
    var selectedUser:Bool

    @ObservedObject var bellCircle = BellCircle.current

    var body: some View {
        HStack {
            Text(!bellCircle.assignments.containsRingerForID(user.userID) ? "-" : self.getString(indexes: bellCircle.assignments.allIndecesOfRingerForID(user.userID)!))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(user.name)
                .fontWeight(self.selectedUser ? .bold : .regular)
                .lineLimit(1)
                .layoutPriority(2)
            Spacer()
        }
        .foregroundColor(self.selectedUser ? Color.main : Color.primary)
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

    @State private var updateView = false
    
//    @State private var showingChat = false {
//        didSet {
//            self.chatManager.canSeeMessages = self.showingChat
//            if self.showingChat == true {
//                self.chatManager.newMessages = 0
//            }
//            hideKeyboard()
//        }
//    }

//    @State private var arrowDown = false

    @ObservedObject var chatManager = ChatManager.shared

    @State private var currentMessage = ""

    @Binding var selectedView:Int

    var body: some View {
        VStack {
            HStack {
                    Text("Chat")
                        .font(.title3)
                        .fontWeight(.heavy)
//                        .bold()
                .padding(.leading, 7)
                Spacer()
                Text("") //to position chat correctly
                    .padding(7)
                    .opacity(0)
                Button(action: {
                    withAnimation {
                        self.selectedView = 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                    Text("Users")
                }
                .foregroundColor(.main)
            }
//            if self.showingChat {
                ScrollView {
                    ScrollViewReader { value in
                        VStack {
                            if chatManager.messages.count > 0 {
                                ForEach(0..<chatManager.messages.count, id: \.self) { i in
                                    HStack {
                                        Text(chatManager.messages[i])
                                            .id(i)
                                        Spacer()
                                    }
//                                      .background(Color.blue)
                                }
                                .onAppear {
                                    value.scrollTo(chatManager.messages.count - 1)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 8)
//                .background(Color.red)
                HStack(alignment: .center) {
//                    GeometryReader { geo in
                        TextField("Message", text: self.$currentMessage, onEditingChanged: { selected in
                            //  self.textFieldSelected = selected
                        })
                        .padding(.top, -13)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .shadow(color: Color.white.opacity(0), radius: 1, x: 0, y: 0)
//                        .onAppear {
//                            let yPos = geo.frame(in: .global).maxY  + geo.frame(in: .global).height + 18
//                            messageFieldYPosition = UIScreen.main.bounds.height - (yPos)
//                        }
//                    }
//                    .fixedSize(horizontal: false, vertical: true )
                        Button("Send") {
                            self.sendMessage()
                        }
                        .foregroundColor(Color.main)
                }
                .padding(.horizontal, 3)
                .padding(.bottom, 7)
            }
//        }
//        .ignoresSafeArea()
//        .edgesIgnoringSafeArea(.all)
        .clipped()
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(Color.primary.colorInvert().cornerRadius(5))
    }

    func sendMessage() {
        //send message
        SocketIOManager.shared.socket.emit("c_msg_sent", ["user":User.shared.name, "email":User.shared.email, "msg":currentMessage, "tower_id":BellCircle.current.towerID])
        currentMessage = ""
    }
}

struct GeometryGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        GeometryReader { geometry in
            Group { () -> AnyView in
                DispatchQueue.main.async {
                    self.rect = geometry.frame(in: .global)
                }

                return AnyView(Color.clear)
            }
        }
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


