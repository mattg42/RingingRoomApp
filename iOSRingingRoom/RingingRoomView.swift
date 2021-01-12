//
//  RingingRoomView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 08/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

struct RingingRoomView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var backgroundColor:Color {
        get {
            if colorScheme == .light {
                return Color(red: 211/255, green: 209/255, blue: 220/255)
            } else {
                return Color(white: 0)
            }
        }
    }
    
    init() {
        print("new ringingroom view")
    }
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    var interfaceOrientation: UIInterfaceOrientation? {
        get {
            guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                #if DEBUG
                fatalError("Could not obtain UIInterfaceOrientation from a valid windowScene")
                #else
                return nil
                #endif
            }
            return orientation
        }
    }
    
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    var manager = SocketIOManager.shared
    
    @ObservedObject var chatManager = ChatManager.shared
    
    @State var showingTowerControls = false
    
    @State var titleHeight:CGFloat = 0
    
    var ringingView = RingingView()
    
    @State var text = ""
    
    @State var towerControls = TowerControlsView()
    
    var isSplit:Bool {
        get {
            !(horizontalSizeClass == .compact || (interfaceOrientation?.isPortrait ?? true))
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                if isSplit {
                    HStack(spacing: 0.0) {
                        towerControls
                            .padding(5)
                        VStack(spacing: 0) {
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
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 5)
                            .padding(.bottom, 5)
                            HStack {
                                LeaveButton()
                                    .padding(.leading, 5)
                                Spacer()
                                HelpButton()
                                Spacer()
                                Button(action: {
                                    SocketIOManager.shared.socket.emit("c_set_bells", ["tower_id":bellCircle.towerID])
                                }) {
                                    ZStack {
                                        Color.main.cornerRadius(5)
                                        //                                 VStack {
                                        Text("Set at hand")
                                            .bold()
                                            .padding(.horizontal, 3.5)
                                            //                                    Text("hand")
                                            //                                        .bold()
                                            //                                }
                                            .foregroundColor(.white)
                                            .padding(2)
                                    }
                                    .fixedSize()
                                }
                                .padding(.trailing, 5)
                            }
                            ringingView
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        //                GeometryReader { geo in
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
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 5)
                        .opacity(0)
                        //                    .onAppear {
                        //                        self.titleHeight = geo.frame(in: .global).midY * 2
                        //                    }
                        //                }
                        //                .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            LeaveButton()
                                .padding(.leading, 5)
                            Spacer()
                            HelpButton()
                            Spacer()
                            Button(action: {
                                SocketIOManager.shared.socket.emit("c_set_bells", ["tower_id":bellCircle.towerID])
                            }) {
                                ZStack {
                                    Color.main.cornerRadius(5)
                                    //                                 VStack {
                                    Text("Set at hand")
                                        .bold()
                                        .padding(.horizontal, 3.5)
                                        //                                    Text("hand")
                                        //                                        .bold()
                                        //                                }
                                        .foregroundColor(.white)
                                        .padding(2)
                                }
                                .fixedSize()
                            }
                            Spacer()
                            MenuButton()
                                .opacity(0)
                        }
                        ringingView
                    }
                    
                    Color.primary.colorInvert().edgesIgnoringSafeArea(.all)
                        .offset(x: showingTowerControls ? 0 : -(geo.frame(in: .local).width), y: 0)
                    
                    VStack(spacing: 3) {
                        //                GeometryReader { geo in
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
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 5)
                        //                    .onAppear {
                        //                        self.titleHeight = geo.frame(in: .global).midY * 2
                        //                    }
                        //                }
                        //                .fixedSize(horizontal: false, vertical: true)
                        ZStack {
                            
                            VStack {
                                HStack(alignment: .top) {
                                    Spacer()
                                    VStack(spacing: 1) {
                                        
                                        Button(action: {
                                            withAnimation {
                                                self.showingTowerControls.toggle()
                                                
                                                
                                                if !self.showingTowerControls {
                                                    hideKeyboard()
                                                    chatManager.canSeeMessages = false
                                                } else {
                                                    if bellCircle.towerControlsViewSelection == 2 {
                                                        chatManager.canSeeMessages = true
                                                    }
                                                }
                                            }
                                        }) {
                                            MenuButton()
                                        }
                                        if chatManager.newMessages > 0 {
                                            Button(action: {
                                                if !self.showingTowerControls {
                                                    self.showingTowerControls = true
                                                }
                                                bellCircle.towerControlsViewSelection = 2
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.main)
                                                        .frame(width: 27, height: 27)
                                                    Text(String(chatManager.newMessages))
                                                        .foregroundColor(.white)
                                                        .bold()
                                                }
                                            }
                                            //                                .padding(.trailing, 5)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            towerControls
                                .padding(.horizontal, 5)
                                .offset(x: showingTowerControls ? 0 : -(geo.frame(in: .local).width), y: 0)
                        }
                    }
                }
            }
            .onAppear {
                if bellCircle.autoRotate {
                    if !bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                        bellCircle.perspective = 1
                    }
                
                }
        }
        }
    }
    
}

struct MenuButton:View {
    var body: some View {
        Image(systemName: "line.horizontal.3")
            .font(.largeTitle)
            //                                            .bold()
            .foregroundColor(.primary)
            .padding(5)
    }
}

struct HelpButton:View {
    @State var presentingHelp = false
    
    var body: some View {
        Button(action: {
            self.presentingHelp = true
        }) {
            ZStack {
                Color.main.cornerRadius(5)
//                    .fixedSize()
                Text("Help")
                .bold()
                    .padding(2)
                    .padding(.horizontal, 3.5)
                    .foregroundColor(Color.white)
            }
            .fixedSize()
        }
        .sheet(isPresented: self.$presentingHelp) {
            HelpView(asSheet: true, isPresented: self.$presentingHelp)
                .accentColor(.main)
        }
    }
}

struct LeaveButton:View {
    
    var body: some View {
        Button(action:  {
            SocketIOManager.shared.leaveTower()
        }) {
            ZStack {
                Color.main.cornerRadius(5)
//                    .fixedSize()
                Text("Leave Tower")
                .bold()
                    .padding(2)
                    .padding(.horizontal, 3.5)
                    .foregroundColor(Color.white)
            }
            .fixedSize()
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
            if bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                HStack(spacing: 5.0) {
                    ForEach(0..<bellCircle.size, id: \.self) { i in
                        if bellCircle.assignments[bellCircle.size-1-i].userID == User.shared.ringerID {
                            Button(action: {
                                self.bellCircle.ringBell(bellCircle.size-i)
                            }) {
                                RingButton(number: String(bellCircle.size-i))
                            }
                            .buttonStyle(TouchDown(isAvailible: true))
                        }
                    }
                }
                .padding(.horizontal, 5)

            }
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
            }
            .disabled(!canCall())
            .opacity(canCall() ? 1 : 0.35)
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
    
    func canCall() -> Bool {
        if bellCircle.isHost {
            return true
        } else if bellCircle.hostModeEnabled {
            if bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
}

struct CallButton:View {
    
    var call:String
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(white: colorScheme == .light ? 1 : 0.085).cornerRadius(5)
            Text(call)
                .foregroundColor(.primary)
                
        }
        .frame(maxHeight: horizontalSizeClass == .regular ? 45 : 30)
    }
}

struct RingButton:View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Environment(\.colorScheme) var colorScheme
    
    var number:String
    
    var body: some View {
        ZStack {
            Color(white: colorScheme == .light ? 1 : 0.085).cornerRadius(5)
            Text(number)
                .foregroundColor(.primary)
                .font(horizontalSizeClass == .regular ? .largeTitle : .title3)
                .bold()
        }
        .frame(maxHeight: horizontalSizeClass == .regular ? 150 : 70)
    }
}

struct RopeCircle:View {
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

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
    
    var ropeSize:CGFloat {
        get {
            if horizontalSizeClass == .regular && interfaceOrientation ?? .portrait == .portrait {
                return 75
            } else {
                switch bellCircle.size {
                case 14:
                    return 69
                case 16:
                    return 63
                default:
                    return 75
                }
            }
        }
    }
    var handBellSize:CGFloat {
        get {
            switch bellCircle.size {
            case 16:
                return 48
            default:
                return 60
            }
        }
    }
    
    var imageWidth:CGFloat {
        get {
            if bellCircle.bellType == .tower {
                return ropeSize/3
            } else {
                return handBellSize
            }
        }
    }
    
    var imageHeight:CGFloat {
        get {
            if bellCircle.bellType == .tower {
                return ropeSize
            } else {
                return handBellSize
            }
        }
    }
    
    var interfaceOrientation: UIInterfaceOrientation? {
        get {
            guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                #if DEBUG
                fatalError("Could not obtain UIInterfaceOrientation from a valid windowScene")
                #else
                return nil
                #endif
            }
            return orientation
        }
    }
    
    var isSplit:Bool {
        get {
            !(horizontalSizeClass == .compact || (interfaceOrientation?.isPortrait ?? true))
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
//                                if bellCircle.gotBellPositions {
                ForEach(0..<bellCircle.size, id: \.self) { bellNumber in
                    //                        Text("Hi")
                    Button(action: {
                        if self.bellCircle.bellMode == .ring {
                            self.bellCircle.ringBell(bellNumber+1)
                        } else {
                            self.bellCircle.perspective = bellNumber+1
                            self.bellCircle.bellMode = .ring
                        }
                    }) {
                        HStack(spacing: 0) {
                            Text(String(bellNumber+1))
                                .opacity(isLeft(bellNumber) ? 0 : 1)
                                .font(bellCircle.size > 13 ? .callout : .body)
                            Image(self.getImage(bellNumber)).resizable()
                                .frame(width: imageWidth, height: imageHeight)
                                .rotation3DEffect(
                                    .degrees((bellCircle.bellType == .tower) ? 0 : isLeft(bellNumber) ? 180 : 0),
                                    axis: (x: 0.0, y: 1.0, z: 0.0),
                                    anchor: .center,
                                    perspective: 1.0
                                )
                                .padding(.horizontal, (bellCircle.bellType == .tower) ? 0 : -5)

                            Text(String(bellNumber+1))
                                .opacity(isLeft(bellNumber) ? 1 : 0)
                                .font(bellCircle.size > 13 ? .callout : .body)
                        }
                        .disabled(!canRing(bellNumber))
                        .opacity(canRing(bellNumber) ? 1 : 0.35)
                    }
                    .buttonStyle(TouchDown(isAvailible: true))
                    .foregroundColor(.primary)
                    .position(self.bellCircle.getNewPositions(radius: bellCircle.getRadius(baseRadius: min(geo.frame(in: .local).width/2 - imageWidth/2, geo.frame(in: .local).height/2  - (20 + imageWidth/2)), iPad: isSplit), center: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))[bellNumber]) // bellCircle.getRadius(baseRadius: min(geo.frame(in: .local).width/2 - imageWidth/2, geo.frame(in: .local).height/2) - imageHeight/2, iPad: isSplit)
                    //                        .position(self.bellCircle.getNewPositions(radius: geo.frame(in: .local).height/2 - imageHeight/2, center: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))[bellNumber].pos) // bellCircle.getRadius(baseRadius: min(geo.frame(in: .local).width/2 - imageWidth/2, geo.frame(in: .local).height/2) - imageHeight/2, iPad: isSplit)
                }
                if bellCircle.bellMode == .ring {
                    ScrollView {
                        ForEach(0..<bellCircle.assignments.count, id: \.self) { i in
                            HStack {
                                Text("\(i+1)")
                                    .font(.callout)
                                    .frame(width: 25, height:18, alignment: .trailing)
                                Text(" \(self.bellCircle.assignments[i].name)")
                                    .font(.callout)
                                    .frame(width: 165, height:18, alignment: .leading)
                            }
                            .foregroundColor(self.colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))

                        }
                    }
                    .disabled(bellCircle.size > 11 ? false : true)
                    .frame(maxHeight: getHeight()
                    )
                    .fixedSize()

                    .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                } else {
                    Text("Tap the bell that you would like to be positioned bottom right, or tap the rotate button again to cancel.")
                        .multilineTextAlignment(.center)
                        .frame(width: 180)
                        .font(.title2)
                        .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                        .foregroundColor(self.colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))
                }
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
                .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
//                                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            self.bellCircle.bellMode.toggle()
                            //put into change perspective mode
                        }) {
                            //                            Text("Rotate bell circle")
                            ZStack {
                                Color.main.cornerRadius(10)
                                //                    .fixedSize()
                                Image("Arrow.4.circle.white").resizable()
                                    .frame(width: 45, height: 45)
                                //                                VStack(spacing: -5) {
                                //                                    Text("Rotate")
                                //                                    Text("perspective")
                                //                                }
                                ////                                .bold()
                                //                                .padding(1.5)
                                //                                    .padding(.horizontal, 3)
                                //                                    .foregroundColor(Color.white)
                            }
                            .fixedSize()
                            //                            Text("Set at hand")
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
        }
//        .background (Color.green)
        .onReceive(orientationChanged, perform: { _ in
            bellCircle.objectWillChange.send()
        })
    }
    
    func getHeight() -> CGFloat {
        return bellCircle.gotBellPositions ? (bellCircle.perspective <= Int(bellCircle.size/2) ?
                                                            bellCircle.bellPositions[bellCircle.perspective - 1].y - bellCircle.bellPositions[bellCircle.perspective - 1 + Int(ceil(Double(bellCircle.size/2)))].y :
                                                            bellCircle.bellPositions[bellCircle.perspective - 1].y - bellCircle.bellPositions[bellCircle.perspective - 1 - Int(ceil(Double(bellCircle.size/2)))].y) - imageHeight - CGFloat(15) : 20
    }
    
    func isLeft(_ num:Int) -> Bool {
        if bellCircle.perspective <= Int(bellCircle.size/2) {
            return (bellCircle.perspective..<bellCircle.perspective+Int(bellCircle.size/2)).contains(num)
        } else {
            return !(bellCircle.perspective-Int(bellCircle.size/2)..<bellCircle.perspective).contains(num)
        }
    }
    
    func canRing(_ number:Int) -> Bool {
        if bellCircle.isHost {
            return true
        } else if bellCircle.hostModeEnabled {
            if bellCircle.assignments[number].userID == User.shared.ringerID {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    func getImage(_ number:Int) -> String {
           var imageName = bellCircle.bellType.rawValue.first!.lowercased() + "-" + (bellCircle.bellStates[number] ? "handstroke" : "backstroke")
        if imageName.first! == "t" && number == 0 && bellCircle.bellStates[number] {
            imageName += "-treble"
        }
        return imageName
    }
    
}

enum BellMode {
    case ring, rotate
    
    mutating func toggle() {
        if self == .ring {
            self = .rotate
        } else {
            self = .ring
        }
    }
}

//struct Bells:View {
//
//    @ObservedObject var bellCircle = BellCircle.current
//
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//
//    @Environment(\.colorScheme) var colorScheme
//
//    var body: some View {
//
//    }
//
//
//}

struct TouchDown: PrimitiveButtonStyle {
    var isAvailible:Bool
    
    @State var opacity:Double = 1
    @State var disabled = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .onLongPressGesture(
                minimumDuration: 0.0000001,
                pressing: { isPressed in
                    print("animating")
                    if isPressed {
                        configuration.trigger()
                        opacity = 0.35
                        withAnimation(.linear(duration: 0.25)) {
                            opacity = 1
                        }
                        disabled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            disabled = false
                        }
                    }
                    
                },
                perform: {}
            )
            .opacity(isAvailible ? opacity : 0.35)
            .disabled(isAvailible ? disabled : true)
    }
}

extension CGFloat {
    func radians() -> CGFloat {
        (self * CGFloat.pi)/180
    }
}

extension String {
    mutating func prefix(_ prefix:String) {
        self = prefix + self
    }
}

struct TowerControlsView:View {
    @ObservedObject var bellCircle = BellCircle.current

    @State private var permitHostMode:Bool = false

    @State private var updateView = false

    @State private var bellTypeSelection = 0

    @State private var selectedUser = 0

    @State private var newAssigment = false
    
    @State private var towerSelectionCount = 0
    @State private var bellTypeSelectionCount = 0

    var bellTypes = [BellType.tower, BellType.hand]
    var towerSizes = [4, 5, 6, 8, 10, 12, 14, 16]

    
    
    @State private var showingUsers = false

    init() {
        print("new towerControls")
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Spacer()
                    Text(String(bellCircle.towerID))
                    Button(action: {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = String(self.bellCircle.towerID)
                    }) {
                        Text("Copy")
                    }
                    .foregroundColor(.main)
                    Spacer()
//                    if hasPermissions() {
//                    MenuButton()
//                        .opacity(0)
//                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 7)
//                .padding(.top, -4)
                HStack {
                    Picker(selection: .init(get: {
                        self.bellCircle.halfMuffled
                    }, set: {
                        self.bellCircle.halfMuffled = $0
                    }), label: Text("Half-muffled")){
                        Text("Half-muffled").tag(true)
                        Text("Open").tag(false)
                    }
                    .fixedSize()
                    .pickerStyle(SegmentedPickerStyle())
                    if hasPermissions() {
                    Picker(selection: .init(get: {self.bellTypes.firstIndex(of: self.bellCircle.bellType)!}, set: {self.bellTypeChanged(value:$0)}), label: Text("Bell type picker")) {
                        ForEach(0..<2) { i in
                            Text(self.bellTypes[i].rawValue)
                        }
                    }
                    .fixedSize()
                    //                            .padding(.horizontal)
                    //                            .padding(.top, 7)
                    .pickerStyle(SegmentedPickerStyle())
                    }
                    Spacer()

                }
                .padding(.bottom, 7)
                    if hasPermissions() {
                        HStack {
                            
                            
                            Picker(selection: .init(get: { towerSizes.firstIndex(of: bellCircle.size) ?? 6 }, set: {self.sizeChanged(value:$0)}), label: Text("Tower size picker")) {
                                ForEach(0..<towerSizes.count) { i in
                                    Text(String(self.towerSizes[i]))
                                }
                            }
                            //                            .fixedSize()
                            //                            .padding(.horizontal)
                            //                                .padding(.top, 10)
                            .pickerStyle(SegmentedPickerStyle())
                            
                        }
                        .padding(.bottom, 7)
                    }
    //                if bellCircle.isHost && bellCircle.hostModePermitted {
    //                    Toggle(isOn: .init(get: {self.bellCircle.hostModeEnabled}, set: { newValue in
    //                        SocketIOManager.shared.socket.emit("c_host_mode", ["new_mode":newValue, "tower_id":self.bellCircle.towerID])
    //                    }) ) {
    //                        Text("Enable host mode")
    //                    }
    //                }
                if bellCircle.towerControlsViewSelection == 1 {
                    UsersView()
                } else {
                    ChatView()
                }
//                TabView(selection: .init(get: {
//                    return bellCircle.towerControlsViewSelection
//                }, set: {
//                    bellCircle.towerControlsViewSelection = $0
//                })) {
////                    Text("df")
//                    UsersView()
////                        .padding(.vertical)
//                        .padding(.bottom, self.bellCircle.keyboardShowing ? 5 : 102)
//                        .tag(1)
//                        .padding(.horizontal, 5)
//                        .tabItem {
//                            Image(systemName: "person")
//                            Text("Users")
//                        }
////                    Text("tab")
////                        .onAppear {
////                            print("text appeared")
////                        }
//                    ChatView()
//                        .padding(.horizontal, 5)
//                        .padding(.bottom, self.bellCircle.keyboardShowing ? 5 : 102)
//                        .tag(2)
//                        .tabItem {
//                            Image(systemName: "text.bubble")
//                            Text("Chat")
//                        }
//                }
////                .tabViewStyle(PageTabViewStyle())
////                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
//                .padding(.top, self.bellCircle.keyboardShowing ? -77 : 0)
//                .padding(.bottom, -145)
//                .onAppear {
//                    print("tab view appeared")
//                }
//                .padding(.horizontal, -5)
//                .accentColor(.main)
            }
        }
    }

    func hasPermissions() -> Bool {
        if bellCircle.isHost {
            return true
        } else if bellCircle.hostModeEnabled {
            return false
        } else {
            return true
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
        SocketIOManager.shared.socket.emit("c_size_change", ["new_size":towerSizes[value], "tower_id":self.bellCircle.towerID])
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

    @State private var updateView = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
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
                                SocketIOManager.shared.socket.emit("c_assign_user", ["user":user.userID, "bell":i+1, "tower_id":self.bellCircle.towerID])
                                tempUsers.remove(at: index)
                            }
                        }
                    }) {
                        Text("Fill In")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
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
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .foregroundColor(.white)
                            .background(Color.main.cornerRadius(5))
                            .lineLimit(1)
                    }

                }
                Spacer()
                Button(action: {
                        self.bellCircle.towerControlsViewSelection = 2
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
                            ForEach(0..<self.bellCircle.assignments.count, id: \.self) { number in
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
            print("users view appeared")
            if self.selectedUser == 0 {
                self.selectedUser = User.shared.ringerID
            }
        })
        .clipped()
        .padding(7)
        .background(horizontalSizeClass == .regular ? Color(white: colorScheme == .light ? 1 : 0.08).cornerRadius(5) : Color(white: colorScheme == .light ? 0.94 : 0.08).cornerRadius(5))
        .onDisappear {
            print("users view disappeared")
        }
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

    @Environment(\.colorScheme) var colorScheme
    
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

    var body: some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .center) {
                    Text("Chat")
                        .font(.title3)
                        .fontWeight(.heavy)
//                        .bold()
                .padding(.leading, 7)
                Spacer()
                Text("Fill In")
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .lineLimit(1)
                    .opacity(0)
                Spacer()
                Button(action: {
                    BellCircle.current.towerControlsViewSelection = 1
                }) {
                    Image(systemName: "chevron.left")
                    Text("Users")
                }
                .foregroundColor(.main)
            }
            .padding(.bottom, 5)
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
//                        .padding(.top, -13)
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
        .background(Color(white: colorScheme == .light ? 0.94 : 0.045).cornerRadius(5))
        .onAppear {
            print("chat view appeared")
        }
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

struct chatNotification:View {
    
    var sender = ""
    var message = ""
    
    var body: some View {
        Capsule()
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global))
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


