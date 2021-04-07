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
import Network

enum ActiveSheet: Identifiable {
    case privacy, help
    
    var id: Int {
        hashValue
    }
}

struct RingingRoomView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Environment(\.sizeCategory) var sizeCategory

    @Environment(\.scenePhase) var scenePhase
    
    var monitor = NWPathMonitor()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton = Alert.Button.cancel()
    
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
        
    @State var titleHeight:CGFloat = 0
    
    var ringingView = RingingView()
    
    @State var changedSizeCategory = false
    
    @State var text = ""
    
//    @State var towerControls = TowerControlsView()
    
    var isSplit:Bool {
        get {
            !(horizontalSizeClass == .compact || (interfaceOrientation?.isPortrait ?? true))
        }
    }
    
    @State var showingPrivacyPolicyView = false

    

    
    @State var activeSheet: ActiveSheet?

    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                ZStack {
                if isSplit {
                    HStack(spacing: 5) {
                        TowerControlsView(width: geo.size.width * 0.2, activeSheet: $activeSheet)
                            .frame(width: 350)
                        VStack(spacing: 0) {
                            TowerNameView()
                            .padding(.bottom, 5)
                            HStack {
                                LeaveButton()
                                
                                Spacer()
                                HelpButton(activeSheet: $activeSheet)
                                Spacer()
                                SetAtHandButton()
                            }
                            ringingView
                        }.padding(.leading, 5)
//                        .padding(.bottom, 5)
//                        .frame(width: geo.size.width * 0.67, height: geo.size.height)
                        .ignoresSafeArea(.keyboard, edges: .all)
                    }
                    .padding(5)
//                    .padding(.bottom, 25)
                } else {
                    VStack(spacing: 0) {
                        TowerNameView()
                            .padding(.horizontal, 5)
                            .padding(.bottom, 5)
                            .opacity(0)
                        HStack(spacing: 0) {
                            if !bellCircle.isLargeSize {
                            HelpButton(activeSheet: .constant(nil))
                                .opacity(0)
                                .disabled(true)
                            
                            Spacer(minLength: 0)
                            }
                            LeaveButton()
                                .onAppear {
                                    print("width", geo.size.width, UIScreen.main.bounds.width)
                                }
                            Spacer(minLength: 0)
                            SetAtHandButton()
                            Spacer(minLength: 0)
                            MenuButton(keepSize: true)
                                .opacity(0)
                                .disabled(true)
                        }
                        .padding(.horizontal, 5)
                        ringingView
                    }
                    .ignoresSafeArea(.keyboard, edges: .all)

                    
                    Color.primary.colorInvert().edgesIgnoringSafeArea(.all)
                        .offset(x: bellCircle.showingTowerControls ? 0 : -(geo.frame(in: .local).width), y: 0)
                    
                    VStack(spacing: 0) {
                        TowerNameView()
                            .padding(.bottom, 5)
                            .padding(.horizontal, 5)

                        ZStack {
                            TowerControlsView(width: .infinity, activeSheet: $activeSheet)
                                .padding(.horizontal, 5)
                                .padding(.bottom, 5)
                                .offset(x: bellCircle.showingTowerControls ? 0 : -(geo.frame(in: .local).width), y: 0)
                            VStack {
                                HStack(spacing: 0) {
                                    if !bellCircle.isLargeSize {
                                        HelpButton(activeSheet: $activeSheet)
                                    
                                    Spacer(minLength: 0)
                                    }
                                    LeaveButton()
                                        .opacity(0)
                                        .disabled(true)
                                    Spacer(minLength: 0)
                                    SetAtHandButton()
                                        .opacity(0)
                                        .disabled(true)
                                    Spacer(minLength: 0)
                                    MenuButton(keepSize: false)
                                }
                                .padding(.horizontal, 5)
                                if !bellCircle.showingTowerControls {
                                HStack {
                                    Spacer()
                                    if chatManager.newMessages > 0 {
                                        ChatNotificationButton()
                                            .padding(.leading, -5)
                                        
                                        //                                .padding(.trailing, 5)
                                    }
                                }
                                .padding(.horizontal, 5)
                                }
                                Spacer()
                            }

                        }
                    }
                }
                }.disabled(showingAlert)
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                        .opacity(0.3)
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .cornerRadius(10)
                        VStack(spacing: 14.0) {
                            Text("""
Your device is not connected
to the internet.
""").bold()
                            Text("""
This alert will disappear
when the internet
connection is restored.
""")
                        }.multilineTextAlignment(.center).font(.callout).padding()
                    }
                    .fixedSize()
                }
                .opacity(showingAlert ? 1 : 0)
                GeometryReader { geo2 in
                    HStack {
                        HelpButton(activeSheet: .constant(nil))

                        
                        Spacer(minLength: 0)
                        
                        LeaveButton()
                        Spacer(minLength: 0)
                        SetAtHandButton()
                        Spacer(minLength: 0)
                        MenuButton(keepSize: true)
                    }
                    .opacity(0)
                    .onAppear {
                        print("changed sizeCategory", geo2.size.width, UIScreen.main.bounds.width)
                        print(UIScreen.main.bounds.width)
                        bellCircle.isLargeSize = geo2.size.width > UIScreen.main.bounds.size.width
                    }
                    .onChange(of: sizeCategory, perform: { value in
                        print("changed sizeCategory", geo2.size.width)
                        bellCircle.isLargeSize = false
                        changedSizeCategory = true
                    })
                    .onChange(of: scenePhase, perform: { value in
                        print("changed scenePhase", geo2.size.width)
                        if changedSizeCategory {
                            changedSizeCategory = false
                            bellCircle.isLargeSize = geo2.size.width > UIScreen.main.bounds.size.width
                        }

                    })
                }.disabled(true)
                .fixedSize(horizontal: false, vertical: true)
            }
//            .alert(isPresented: $showingAlert) {
//                Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: alertCancelButton)
//            }
            .onDisappear {
                monitor.cancel()
            }
            .onAppear {
                if bellCircle.autoRotate {
                    if !bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                        bellCircle.perspective = 1
                    }
                
                }
                monitor.start(queue: DispatchQueue.monitor)
                monitor.pathUpdateHandler = { path in
                    if path.status == .unsatisfied {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingAlert = true
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingAlert = false
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                        switch item {
                        case .privacy:
                            PrivacyPolicyWebView(isPresented: .init(get: {activeSheet == .privacy}, set: {if !$0 {activeSheet = nil}}))

                            .accentColor(.main)
                        case .help:
                            HelpView(asSheet: true, isPresented: .init(get: {activeSheet == .help}, set: {if !$0 {activeSheet = nil}}))
                                .accentColor(.main)

                        }
                    }

            .onOpenURL(perform: { url in
                let pathComponents = Array(url.pathComponents.dropFirst())
                print(pathComponents)
                if pathComponents.first ?? "" == "privacy" {
                    activeSheet = .privacy
                }
            })
        }
    }
    
    func noInternetAlert() {
        alertTitle = "Connection error"
        alertMessage = "Your device is not connected to the internet. You will be reconnected to the tower when you regain internet."
        alertCancelButton = .cancel(Text("OK"), action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                if monitor.currentPath.status == .unsatisfied {
                    noInternetAlert()
                } else {
                    manager.socket?.connect()
                }
            })
        })
        showingAlert = true
    }
    
}

struct ChatNotificationButton:View {
    
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    @ObservedObject var chatManager = ChatManager.shared
    
    var body: some View {
        Button(action: {
            if !bellCircle.showingTowerControls {
                bellCircle.showingTowerControls = true
            }
            bellCircle.towerControlsViewSelection = 2
        }) {
            ZStack {
                Image(systemName: "bubble.left.fill")
                    .accentColor(Color.main)
                    .font(.title)
                Text(String(chatManager.newMessages))
                    
                    .foregroundColor(.white)
                    .bold()
                    .offset(x: 0, y: -2)
            }
            .padding(-2)
        }
    }
}

struct SetAtHandButton:View {
    
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    var manager = SocketIOManager.shared
    
    var body: some View {
        Button(action: {
            SocketIOManager.shared.socket?.emit("c_set_bells", ["tower_id":bellCircle.towerID])
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
                    .minimumScaleFactor(0.7)
            }
            .fixedSize()
        }
    }
}

struct TowerNameView:View {

    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.main)
                .cornerRadius(5)
            Text(bellCircle.towerName)
                .foregroundColor(.white)
                .font(Font.custom("Simonetta-Black", size: 30))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .scaleEffect(0.9)
                .padding(.vertical, 4)
        }
        //                    .padding(.top, -5)
        .fixedSize(horizontal: false, vertical: true)
//        .padding(.horizontal, 5)
    }
}

enum MenuButtonMode {
    case ring, controls
}

struct MenuButton:View {
        
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    
    @ObservedObject var chatManager = ChatManager.shared
        
    var keepSize:Bool
    
    var mode:MenuButtonMode = .controls
    
    var body: some View {
        Button(action: {
            withAnimation {
                bellCircle.showingTowerControls.toggle()
                
                
                if !bellCircle.showingTowerControls {
                    hideKeyboard()
                    chatManager.canSeeMessages = false
                } else {
                    if bellCircle.towerControlsViewSelection == 2 {
                        chatManager.canSeeMessages = true
                    }
                }
            }
        }) {
            ZStack {
                Color.main.cornerRadius(5)
    //                    .fixedSize()
                
                if keepSize {
                    if mode == .ring {
                        ToRing()
                    } else {
                        ToControls()
                    }
                } else {
                    if bellCircle.showingTowerControls {
                        ToRing()

                    } else {
                        ToControls()
                    }
                }
            }
            .clipped()
            .fixedSize()
        }
    }
}

struct ToControls:View {
    var body: some View {
        HStack {
            Text("Controls")
                .bold()
                .minimumScaleFactor(0.7)

            Image(systemName: "chevron.right")
        }
            .padding(2)
            .padding(.horizontal, 3.5)
            .foregroundColor(Color.white)
    }
}

struct ToRing:View {
    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
            Text("Ring")

                .bold()
                .minimumScaleFactor(0.7)

        }
            .padding(2)
            .padding(.horizontal, 3.5)
            .foregroundColor(Color.white)
    }
}

struct HelpButton:View {
    @Binding var activeSheet:ActiveSheet?
    
    var body: some View {
        Button(action: {
            self.activeSheet = .help
        }) {
            ZStack {
                Color.main.cornerRadius(5)
//                    .fixedSize()
                Text("Help")

                .bold()
                    .padding(2)
                    .padding(.horizontal, 3.5)
                    .foregroundColor(Color.white)
                    .minimumScaleFactor(0.7)

            }
            .fixedSize()
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
                Text("Leave")
                .bold()
                    .padding(2)
                    .padding(.horizontal, 3.5)
                    .foregroundColor(Color.white)
                    .minimumScaleFactor(0.7)

            }
            .fixedSize()
        }
    }
}

struct RingingView:View {
    @ObservedObject var bellCircle:BellCircle = BellCircle.current
    

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var manager = SocketIOManager.shared
    
    init() {
        print("new ringingView")
    }
    
    var ropeCircle = RopeCircle()
    
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
        VStack {
            Spacer()
            ropeCircle
            Spacer()

            if interfaceOrientation?.isPortrait ?? true {
                if horizontalSizeClass == .compact {
                    if bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                        HStack(spacing: 5.0) {
                            ForEach(0..<bellCircle.size, id: \.self) { i in
                                if bellCircle.assignments[bellCircle.size-1-i].userID == User.shared.ringerID {
                                    Button(action: {
                                        self.bellCircle.ringBell(bellCircle.size-i)
                                    }) {
                                        RingButton(number: String(bellCircle.size-i))
                                    }
                                    .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                                    .onAppear {
                                        print("ring button", bellCircle.assignments.ringers, User.shared.ringerID)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        
                    }
                    HorizontalCallButtons()
                        .disabled(!canCall())
                        .opacity(canCall() ? 1 : 0.35)
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                } else {
                    HorizontalCallButtons()
                        .disabled(!canCall())
                        .opacity(canCall() ? 1 : 0.35)
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                    if bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                        HStack(spacing: 5.0) {
                            ForEach(0..<bellCircle.size, id: \.self) { i in
                                if bellCircle.assignments[bellCircle.size-1-i].userID == User.shared.ringerID {
                                    Button(action: {
                                        self.bellCircle.ringBell(bellCircle.size-i)
                                    }) {
                                        RingButton(number: String(bellCircle.size-i))
                                    }
                                    .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                                    .onAppear {
                                        print("ring button", bellCircle.assignments.ringers, User.shared.ringerID)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        
                    }
                }
            } else {
                if bellCircle.assignments.containsRingerForID(User.shared.ringerID) {
                    HStack(alignment: .bottom, spacing: 5.0) {
                        VerticalCallButtons(size: .infinity)
                            .frame(width: 310)
                        .disabled(!canCall())
                        .opacity(canCall() ? 1 : 0.35)

                        ForEach(0..<bellCircle.size, id: \.self) { i in
                            if bellCircle.assignments[bellCircle.size-1-i].userID == User.shared.ringerID {
                                Button(action: {
                                    self.bellCircle.ringBell(bellCircle.size-i)
                                }) {
                                    RingButton(number: String(bellCircle.size-i))
                                }
                                .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                            }
                        }
//                        .padding(.vertical, 5)
                        .padding(.top, 5)
//                        .padding(.bottom, -5)
                    }
                    
                    .frame(height: 150)

                    .padding(.horizontal, 5)

                } else {
                    VerticalCallButtons(size: .infinity)
                    .disabled(!canCall())
                    .opacity(canCall() ? 1 : 0.35)
                    .padding(.horizontal, 5)
                        .padding(.bottom, -5)
                        .frame(height: 150)

                }

            }
            
        }
        .onAppear {
            print("ringingview appeared")
        }
        .onDisappear {
            print("ringingview disappeared")
        }
    }
    
    func makeCall(_ call:String) {
        manager.socket?.emit("c_call", ["call":call, "tower_id":bellCircle.towerID])

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

struct VerticalCallButtons:View {
    var size:CGFloat
    var body: some View {
        HStack {
            VStack(spacing: 5) {
                Button(action: {
                    makeCall("Bob")
                }) {
                    CallButton(call: "Bob")
                        .frame(maxWidth: size)
                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("Single")
                }) {
                    CallButton(call: "Single")
                        .frame(maxWidth: size)
                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("That's all")
                }) {
                    CallButton(call: "That's all")
                        .frame(maxWidth: size)
                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
            }
            VStack(spacing: 5.0) {
                Button(action: {
                    makeCall("Look to")
                }) {
                    CallButton(call: "Look to")
                        .frame(maxWidth: size)
                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("Go")
                }) {
                    CallButton(call: "Go")
                        .frame(maxWidth: size)
                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("Stand next")
                }) {
                    CallButton(call: "Stand")
                        .frame(maxWidth: size)
                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
            }
        }
    }
    
    func makeCall(_ call:String) {
        SocketIOManager.shared.socket?.emit("c_call", ["call":call, "tower_id":BellCircle.current.towerID])

    }
}

struct HorizontalCallButtons:View {
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Button(action: {
                    makeCall("Bob")
                }) {
                    CallButton(call: "Bob")

                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("Single")
                }) {
                    CallButton(call: "Single")

                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("That's all")
                }) {
                    CallButton(call: "That's all")

                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
            }
            HStack(spacing: 5.0) {
                Button(action: {
                    makeCall("Look to")
                }) {
                    CallButton(call: "Look to")

                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("Go")
                }) {
                    CallButton(call: "Go")

                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
                Button(action: {
                    makeCall("Stand next")
                }) {
                    CallButton(call: "Stand")

                }
                .buttonStyle(TouchDown(isAvailable: true, callButton:true))
            }
        }
    }
    
    func makeCall(_ call:String) {
        SocketIOManager.shared.socket?.emit("c_call", ["call":call, "tower_id":BellCircle.current.towerID])

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
//                                            Text("Hi")
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
                                .font(getFont())
                            Image(self.getImage(bellNumber)).antialiased(true).resizable()
                                .frame(width: getImageWidth(size: geo.size), height: getImageHeight(size: geo.size))
                                .rotation3DEffect(
                                    .degrees((bellCircle.bellType == .tower) ? 0 : isLeft(bellNumber) ? 180 : 0),
                                    axis: (x: 0.0, y: 1.0, z: 0.0),
                                    anchor: .center,
                                    perspective: 1.0
                                )
                                .padding(.horizontal, (bellCircle.bellType == .tower) ? 0 : -5)

                            Text(String(bellNumber+1))
                                .opacity(isLeft(bellNumber) ? 1 : 0)
                                .font(getFont())
                        }

                    }
                    .disabled(bellCircle.bellMode == .ring ? !canRing(bellNumber) : false)
                    .opacity(bellCircle.bellMode == .ring ? canRing(bellNumber) ? 1 : 0.35 : 1)
                    .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                    .foregroundColor(.primary)
                    .position(self.getBellPositionsAndSizes(frame: geo.frame(in: .local), centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))[bellNumber])
//                    .position(self.bellCircle.getNewPositions(radius: bellCircle.getRadius(baseRadius: min(geo.frame(in: .local).width/2 - imageWidth/2, geo.frame(in: .local).height/2  - (20 + imageWidth/2)), iPad: isSplit), centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))[bellNumber])
                }
                if bellCircle.bellMode == .ring {
                    GeometryReader { assignmentsGeo in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: -3) {
                                ForEach(0..<bellCircle.assignments.count, id: \.self) { i in
                                    HStack {
                                        Text("\(i+1)")
                                            .font(.callout)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .frame(width: 20, alignment: .trailing)
                                        Text(" \(self.bellCircle.assignments[i].name)")
                                            .font(.callout)
                                            .lineLimit(1)
                                            .frame(width: getWidth(geo: geo), alignment: .leading)
                                            
        //                                    .minimumScaleFactor(0.9)
                                    }
                                    .foregroundColor(self.colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))
                                }.fixedSize(horizontal:true, vertical:false)
                                
                            }.fixedSize(horizontal:true, vertical:false)
                            
                        }.offset(x: 0, y: bellCircle.size == 5 ? -10 : 0)
//                        .disabled(bellCircle.size > 11 ? false : true)
                        .frame(maxHeight: getHeight(geo: geo))
                        .fixedSize()

                        .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                    }
                } else {
                    Text("Tap the bell that you would like to be positioned bottom right, or tap the rotate button again to cancel.")
                        .multilineTextAlignment(.center)
                        .frame(width: 180)
                        .font(.body)
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
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
                        Button(action: {
                            self.bellCircle.bellMode.toggle()
                            //put into change perspective mode
                        }) {
                            //                            Text("Rotate bell circle")
                            ZStack {
                                Color.main.cornerRadius(10)
                                //                    .fixedSize()
                                Image("Arrow.4.circle.white").resizable()
                                    .frame(width: 37, height: 37)
                            }
                            .fixedSize()
                        }
                        //                            Text("Set at hand")

                        .position(x: geo.frame(in: .local).width - 30, y: bellCircle.bellPositions.count == bellCircle.size ? bellCircle.bellType == .tower ? bellCircle.bellPositions[bellCircle.perspective-1].y + CGFloat(bellCircle.imageSize)/2 - CGFloat(37/2) : bellCircle.bellPositions[bellCircle.perspective-1].y + (CGFloat(bellCircle.imageSize)*0.7)/2 - CGFloat(37/2) - 5 : 0)
                        .animation(nil)
//                    }
//                }
//                .padding(.horizontal, 5)
            }
        }
//        .background (Color.green)
        .onReceive(orientationChanged, perform: { _ in
            bellCircle.objectWillChange.send()
        })
    }
    
    func getImageWidth(size: CGSize) -> CGFloat {
        if size.truncate(places: 5) == bellCircle.oldScreenSize.truncate(places: 5) {
            if bellCircle.size == bellCircle.oldBellCircleSize {
                if bellCircle.bellType == bellCircle.oldBellType {
                    if bellCircle.bellType == .tower {
                        return CGFloat(bellCircle.imageSize)/3
                    } else {
                        return CGFloat(bellCircle.imageSize) * 0.7
                    }
                }

            }
        }
        
        var newImageSize = 0.0
        
        var newRadius = Double(min(size.width/2, size.height/2))
        
        newRadius = min(newRadius, 300)
//        radius *= 0.9
        
        let originalRadius = newRadius
        let theta = Double.pi/Double(bellCircle.size)
                
        newImageSize = sin(theta) * newRadius * 2
//
        (newImageSize, newRadius) = reduceOverlap(width: size.width, height: size.height, imageSize: newImageSize, radius: newRadius, theta: theta)
        
        newImageSize = min(newImageSize, originalRadius*0.6)
        
        (bellCircle.imageSize, bellCircle.radius) = reduceOverlap(width: size.width, height: size.height, imageSize: newImageSize, radius: newRadius, theta: theta)
        bellCircle.radius = min(bellCircle.radius, 350)

        bellCircle.oldScreenSize = size.truncate(places: 5)
        bellCircle.oldBellCircleSize = bellCircle.size
        
        if bellCircle.bellType == .tower {
            return CGFloat(bellCircle.imageSize)/3
        } else {
            return CGFloat(bellCircle.imageSize) * 0.7
        }

    }
    
    func getImageHeight(size: CGSize) -> CGFloat {
        if size.truncate(places: 5) == bellCircle.oldScreenSize {
            if bellCircle.size == bellCircle.oldBellCircleSize {
                if bellCircle.bellType == bellCircle.oldBellType {
                    if bellCircle.bellType == .tower {
                        return CGFloat(bellCircle.imageSize)
                    } else {
                        return CGFloat(bellCircle.imageSize) * 0.7
                    }
                }
            }
        }
        
        var newImageSize = 0.0
        
        var newRadius = Double(min(size.width/2, size.height/2))
        newRadius = min(newRadius, 300)
        let originalRadius = newRadius

        let theta = Double.pi/Double(bellCircle.size)
                
        newImageSize = sin(theta) * newRadius * 2
        
        (newImageSize, newRadius) = reduceOverlap(width: size.width, height: size.height, imageSize: newImageSize, radius: newRadius, theta: theta)
        
        newImageSize = min(newImageSize, originalRadius*0.6)

        (bellCircle.imageSize, bellCircle.radius) = reduceOverlap(width: size.width, height: size.height, imageSize: newImageSize, radius: newRadius, theta: theta)
        bellCircle.radius = min(bellCircle.radius, 350)
        bellCircle.oldScreenSize = size.truncate(places: 5)
        bellCircle.oldBellCircleSize = bellCircle.size
        
//        imageSize *= 1.2
        if bellCircle.bellType == .tower {
            return CGFloat(bellCircle.imageSize)
        } else {
            return CGFloat(bellCircle.imageSize) * 0.6
        }

    }
    
    func getBellPositionsAndSizes(frame:CGRect, centre:CGPoint) -> [CGPoint] {

            return self.bellCircle.getNewPositions(radius: CGFloat(bellCircle.radius), centre: centre)
    }
    
    func reduceOverlap(width:CGFloat, height:CGFloat, imageSize:Double, radius:Double, theta:Double) -> (Double, Double) {
        var vOverlap = 0.0
        var hOverlap = 0.0

        var maxOverlap = 0.0
        
        var newRadius = radius
        var newImageSize = imageSize
        
        
        var a = radius
        
        if bellCircle.size % 2 == 0 {
            a = cos(theta) * newRadius
        }
        
        if bellCircle.bellType == .tower {
            vOverlap = a + imageSize/2 - Double(height)/2
        } else {
            vOverlap = a + (imageSize*0.6)/2 - Double(height)/2
        }
        
        if bellCircle.size % 4 == 0 {
            vOverlap += 7.5
        }
        
        
        a = radius
        if bellCircle.size % 2 == 1 {
            a =  cos(theta/2) * newRadius
        } else if bellCircle.size % 4 == 0 {
            a = cos(theta) * newRadius
        }
        if bellCircle.bellType == .tower {
            hOverlap = a + (imageSize/3)/2 - Double(width)/2
        } else {
            hOverlap = a + (imageSize*0.6)/2 - Double(width)/2
        }
        if bellCircle.size == 4 {
            hOverlap += 30
        }
        
        maxOverlap = max(vOverlap, hOverlap)
        print(vOverlap, hOverlap, maxOverlap)
        
        if bellCircle.size == 4 {
            if maxOverlap >= -20 {
                newRadius = radius - 5

                newImageSize = sin(theta) * newRadius * 2
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
            } else if maxOverlap < -25 {
                
                newRadius = radius + 5
                
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
                
                
            } else {
                return (newImageSize, newRadius)
            }
        } else {
        
            if maxOverlap >= -5 {
                newRadius = radius - 5

                newImageSize = sin(theta) * newRadius * 2
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
            } else if maxOverlap < -7.5 {
                
                newRadius = radius + 2.5
                
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
                
                
            } else {
                return (newImageSize, newRadius)
            }
        }
    }
    
    func getHeight(geo:GeometryProxy) -> CGFloat {

        var returnValue:CGFloat = 0
        if bellCircle.bellPositions.count == bellCircle.size {
            if bellCircle.gotBellPositions {
                if bellCircle.size == 5 {
                        var top = bellCircle.perspective
                        top += 3
                        if top > 5{
                            top -= 5
                        }
                        returnValue = bellCircle.bellPositions[bellCircle.perspective - 1].y - bellCircle.bellPositions[top-1].y

                } else if bellCircle.perspective <= Int(bellCircle.size/2) {
                    returnValue = (bellCircle.bellPositions[bellCircle.perspective - 1].y - bellCircle.bellPositions[bellCircle.perspective - 1 + Int(ceil(Double(bellCircle.size/2)))].y)
                } else {
                    returnValue = (bellCircle.bellPositions[bellCircle.perspective - 1].y - bellCircle.bellPositions[bellCircle.perspective - 1 - Int(ceil(Double(bellCircle.size/2)))].y)
                }
            }
        }
        returnValue -= 10

        if bellCircle.size != 4 {
            returnValue -= getImageHeight(size: geo.size)
        }
//        if bellCircle.bellType == .hand {
//            if bellCircle.size > 13 {
//                returnValue = returnValue - 100
//            }
//        } else {
////            if bellCircle.size == 16 {
////                returnValue -= 80
////            }
//        }
        
        
        return returnValue
    }
    
    func getWidth(geo: GeometryProxy) -> CGFloat {
        var returnValue:CGFloat = 0

        if bellCircle.bellPositions.count == bellCircle.size {
            if bellCircle.gotBellPositions {
                var leftBellNumber = bellCircle.perspective + 2
                if leftBellNumber > bellCircle.size {
                    leftBellNumber -= bellCircle.size
                }
                var rightBellNumber = bellCircle.perspective - 1
                if rightBellNumber <= 0 {
                    rightBellNumber += bellCircle.size
                }
                var left = bellCircle.bellPositions[leftBellNumber-1].x
                var right = bellCircle.bellPositions[rightBellNumber-1].x
                
                returnValue = right - left
                if bellCircle.size == 4 && bellCircle.bellType == .hand {
                    return returnValue
                }
                returnValue -= getImageWidth(size: geo.size)
                if bellCircle.size == 4 {
                    return returnValue
                }
                if bellCircle.size != 4 {
                returnValue -= 20
                }
                if ![4, 14, 16].contains(bellCircle.size) {
                    returnValue -= 30
                }
                returnValue = min(returnValue, 160)
                return returnValue
            }
        }
        return 0
    }
    
    func getFont() -> Font {
        if horizontalSizeClass == .compact &&  verticalSizeClass == .compact {
            if bellCircle.size > 13 {
                return .footnote
            }
           
        }
        
        return .body
    
            
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
    
    @Environment(\.scenePhase) var scenePhase
    
    var isAvailable:Bool
    
    @State var opacity:Double = 1
    @State var disabled = false
    
    @State var timer:Timer? = nil
    
    var callButton:Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .gesture(
                DragGesture()
                    .onChanged({ gesture in
                        let distance = sqrt(pow(gesture.translation.width, 2) + pow(gesture.translation.height, 2))
                        print("gesture",    gesture.translation, distance)
                        if distance > 2 {
                            timer?.invalidate()
                        }
                    })
            )
            .onLongPressGesture(
                minimumDuration: 20,
                pressing: { isPressed in
                    print("animating")
                    if isPressed {
                        if callButton {
                        pressed(config: configuration)
                        } else {
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
                    }
                    
                },
                perform: {
//                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
//                        configuration.trigger()
//                        opacity = 0.35
//                        withAnimation(.linear(duration: 0.25)) {
//                            opacity = 1
//                        }
//                        disabled = true
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
//                            disabled = false
//                        }
//                    })
            
            }
            )
            .opacity(isAvailable ? opacity : 0.35)
            .disabled(isAvailable ? disabled : true)
            .onChange(of: scenePhase, perform: { phase in
                if phase != .active {
                    timer?.invalidate()
                }
            })
    }
    
    func pressed(config: Configuration) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: false, block: { _ in
            config.trigger()
            opacity = 0.35
            withAnimation(.linear(duration: 0.25)) {
                opacity = 1
            }
            disabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                disabled = false
            }
        })
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
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Environment(\.colorScheme) var colorScheme

    @Environment(\.sizeCategory) var sizeCategory
    
    @Environment(\.scenePhase) var scenePhase
    
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
    
    @ObservedObject var bellCircle = BellCircle.current

    @State private var permitHostMode:Bool = false

    @State private var updateView = false

    @State private var bellTypeSelection = 0

    @State private var selectedUser = 0

    @State private var newAssignment = false
    
    @State private var towerSelectionCount = 0
    @State private var bellTypeSelectionCount = 0

    var bellTypes = [BellType.tower, BellType.hand]
    var towerSizes:[Int] {
        bellCircle.towerSizes
    }

    
    
    @State private var showingUsers = false

    init(width:CGFloat, activeSheet:Binding<ActiveSheet?>) {
        print("new towerControls")
        self._activeSheet = activeSheet
        self.width = width
    }
    
    @State var width:CGFloat = 0
    
    @State var hostMode = BellCircle.current.hostModeEnabled
    
    @State var hostModeTimer:Timer? = nil
    
    @State var changeHostMode = true
    
    @State var showingAudioSlider = false
    
//    @State var width = 0
    
    @State var speakerSliders = ".3"
    
    @State var volume = UserDefaults.standard.optionalDouble(forKey: "volume") ?? 1
    
    @Binding var activeSheet: ActiveSheet?
    
    var backgroundColor: some View {
        get {
            if isSplit {
                return AnyView(EmptyView())
            } else {
                return AnyView(Color.primary.colorInvert())
            }
        }
    }
    

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    if UIDevice.current.userInterfaceIdiom == .phone {

                        HStack(alignment: .top) {
                            if !isSplit {
                            HelpButton(activeSheet: $activeSheet)
                                .opacity(bellCircle.isLargeSize ? 1 : 0)
                                .disabled(!bellCircle.isLargeSize)
                            }
                            Button(action: {
                                withAnimation {
                                    showingAudioSlider.toggle()
                                }
                            }) {
                                ZStack(alignment: .leading) {
                                    ZStack {
                                    Color.main.cornerRadius(5)
                                        Image(systemName: "speaker.3").padding(3).font(Font.callout.weight(.bold))
                                            .hidden()
                                    }.fixedSize()
                                    Image(systemName: "speaker\(speakerSliders)")
                                        .font(Font.callout.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(3)
                                }.fixedSize()
                                .onAppear {
                                    getNumberOfLines()
                                }
                            }
                            Spacer()
                            ZStack(alignment: .top) {
                                HStack {
                                Spacer()
                                Text(String(bellCircle.towerID)).lineLimit(1).minimumScaleFactor(0.5)
                                Button(action: {
                                    let pasteboard = UIPasteboard.general
                                    pasteboard.string = String(self.bellCircle.towerID)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .foregroundColor(.primary)
                                Spacer()
                            }
                                HStack(spacing: 0) {
                            Slider(value: $volume, in: 0.0...1.0)
                                .frame(maxWidth: showingAudioSlider ? .infinity : 0)
                            .opacity(showingAudioSlider ? 1 : 0)
                            .background(backgroundColor)
                                .padding(.top, -3.5)
                                Spacer()
                                }
                            }
                            Spacer()
                            if !isSplit {
                            
                                MenuButton(keepSize: true, mode: .ring).opacity(0).disabled(true)
                            }
                        
                    }
//                    .background(Color.blue)
//                    .padding(.top, -3.5)
                    .padding(.bottom, 3)
                    } else {
                            HStack(alignment: .center) {
                                if !isSplit {
                                HelpButton(activeSheet: .constant(nil))
                                    .opacity(0)
                                    .disabled(true)
                                    Spacer()

                                }
                                



                                    ZStack(alignment: .leading) {
                                        GeometryReader { geoSize in
                                        ZStack {
                                        backgroundColor
                                            Image(systemName: "speaker.3")
//                                                .padding(3)
                                                .font(Font.callout.weight(.bold))
                                                .hidden()
                                        }.fixedSize()

                                        }.fixedSize()
                                        Image(systemName: "speaker\(speakerSliders)")
                                            .font(Font.callout.weight(.bold))
                                            .foregroundColor(.primary)
//                                            .padding(3)
                                    }.fixedSize()
                                    .onAppear {
                                        getNumberOfLines()
                                    }
                                    .padding(.trailing, -3)
                                Slider(value: $volume, in: 0.0...1.0)
                                    .frame(maxWidth: 250)
//                                .opacity(showingAudioSlider ? 1 : 0)
                                .background(backgroundColor)
                                Spacer()
                                Text(String(bellCircle.towerID)).lineLimit(1).minimumScaleFactor(0.5)
                                Button(action: {
                                    let pasteboard = UIPasteboard.general
                                    pasteboard.string = String(self.bellCircle.towerID)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .foregroundColor(.primary)
                                if !isSplit {
                                    Spacer()
                                    MenuButton(keepSize: true, mode: .ring).opacity(0).disabled(true)
                                }
                                
                            }
                        .padding(.top, -3.5)
                        .padding(.bottom, 3)
                        }

                    if hasPermissions() {
                        HStack {
                            if bellCircle.hostModePermitted && bellCircle.isHost {
                                HStack {
                                    Toggle("Host Mode", isOn: .init(get: { hostMode }, set: {
                                        if !(hostModeTimer?.isValid ?? false) {
                                            hostMode = $0
                                            SocketIOManager.shared.socket?.emit("c_host_mode", ["new_mode": hostMode, "tower_id": bellCircle.towerID])
                                            hostModeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in hostModeTimer = nil})
                                        }
                                    }))
                                    .onChange(of: bellCircle.hostModeEnabled, perform: { value in
                                        if !bellCircle.hostModeEnabled == hostMode {
                                            hostMode = bellCircle.hostModeEnabled
                                        }
                                    })
                                    .toggleStyle(SwitchToggleStyle(tint: .main))
                                    .fixedSize()
                                    Spacer()
                                }
                            }
                            Picker(selection: .init(get: {self.bellTypes.firstIndex(of: self.bellCircle.bellType)!}, set: {self.bellTypeChanged(value:$0)}), label: Text("Bell type picker")) {
                                ForEach(0..<2) { i in
                                    Text(self.bellTypes[i].rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            }
                        .padding(.bottom, 7)

                            HStack {
                                
                                
                                Picker(selection: .init(get: { towerSizes.firstIndex(of: bellCircle.size) ?? 6 }, set: {self.sizeChanged(value:$0)}), label: Text("Tower size picker")) {
                                    ForEach(0..<towerSizes.count) { i in
                                        Text(String(self.towerSizes[i]))
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                            }
                            .padding(.bottom, 7)
                    }
                    if bellCircle.towerControlsViewSelection == 1 {
                        UsersView()
                    } else {
                        ChatView()
                    }
                }

            }

            .onChange(of: volume) { _ in
                print("volume changed")
                var mappedVolume = pow(Float(volume), 3)
                bellCircle.audioController.starling.engine.mainMixerNode.outputVolume = mappedVolume
                getNumberOfLines()
                UserDefaults.standard.setValue(volume, forKey: "volume")
            }
//            ZStack {
//                VStack(spacing: 0) {
//                    HStack(alignment: .center) {
//                        Spacer()
//                        Text(String(bellCircle.towerID))
//                        Button(action: {
//                            let pasteboard = UIPasteboard.general
//                            pasteboard.string = String(self.bellCircle.towerID)
//                        }) {
//                            Image(systemName: "doc.on.doc")
//                        }
//                        .foregroundColor(.primary)
//                        Spacer()
//    //                    if hasPermissions() {
//    //                    MenuButton()
//    //                        .opacity(0)
//    //                    }
//                    }
//                    .padding(.top, 4)
//                    .padding(.bottom, 7)
////                    ZStack {
////                        if !showingAudioSlider {
////                    HStack(alignment: .center) {
////                        Spacer()
//////                        HelpButton(activeSheet: .constant(nil)).disabled(true).opacity(0)
//////                        if showingAudioSlider {
//////                            Slider(value: .init(get: {
//////                                pow(bellCircle.audioController.starling.engine.mainMixerNode.outputVolume, 1/3)
//////                            }, set: {
//////                                bellCircle.audioController.starling.engine.mainMixerNode.outputVolume = pow($0, 3)
//////                            }), in: (0.1)...(1.0))
//////
//////                        }
////////                            if !showingAudioSlider {
//////                            Button(action: {
//////                                // toggle audio
//////                                withAnimation {
//////                                    showingAudioSlider.toggle()
//////                                }
//////                            }) {
//////                                ZStack {
//////                                    Color.main.cornerRadius(5)
//////                                    Image(systemName: "speaker.2")
//////                                        .font(Font.callout.weight(.bold))
//////                                        .foregroundColor(.white)
//////                                        .padding(4)
//////                                }.fixedSize()
//////                            }
////                        Text(String(bellCircle.towerID))
////                        Button(action: {
////                            let pasteboard = UIPasteboard.general
////                            pasteboard.string = String(self.bellCircle.towerID)
////                        }) {
////                            Image(systemName: "doc.on.doc")
////                        }
////                        .foregroundColor(.primary)
////                        Spacer()
////    //                    if hasPermissions() {
////    //                    MenuButton()
////    //                        .opacity(0)
////    //                    }
//////                    },
////                    .padding(.top, 4)
//////                        }
////
//////                        HStack(alignment: .center) {
//////
//////                                }
//////                            } else {
//////                                //                                HStack
//////
//////                            }
//////                            Spacer()
//////                            MenuButton(keepSize: false).opacity(0).disabled(true)
//////                        }.padding(.top, -3)
////                    }
////                    .padding(.bottom, 7)
//
//    //                .padding(.top, -4)
//                    if hasPermissions() {
//                        HStack {
//                            if bellCircle.hostModePermitted && bellCircle.isHost {
//                                Toggle("Host Mode", isOn: .init(get: { hostMode }, set: {
//                                    if !(hostModeTimer?.isValid ?? false) {
//                                        hostMode = $0
//                                        SocketIOManager.shared.socket?.emit("c_host_mode", ["new_mode": hostMode, "tower_id": bellCircle.towerID])
//                                        hostModeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in hostModeTimer = nil})
//                                    }
//                                }))
//                                .padding(.trailing, 20)
//                                .onChange(of: bellCircle.hostModeEnabled, perform: { value in
//                                    if !bellCircle.hostModeEnabled == hostMode {
//                                        hostMode = bellCircle.hostModeEnabled
//                                    }
//                                })
//                                .toggleStyle(SwitchToggleStyle(tint: .main))
//                                .fixedSize()
//                            }
//                            Picker(selection: .init(get: {self.bellTypes.firstIndex(of: self.bellCircle.bellType)!}, set: {self.bellTypeChanged(value:$0)}), label: Text("Bell type picker")) {
//                                ForEach(0..<2) { i in
//                                    Text(self.bellTypes[i].rawValue)
//                                }
//                            }
////                            .fixedSize()
//                            //                            .padding(.horizontal)
//                            //                            .padding(.top, 7)
//                            .pickerStyle(SegmentedPickerStyle())
//                            }
//                        .padding(.bottom, 7)
//
//                            HStack {
//
//
//                                Picker(selection: .init(get: { towerSizes.firstIndex(of: bellCircle.size) ?? 6 }, set: {self.sizeChanged(value:$0)}), label: Text("Tower size picker")) {
//                                    ForEach(0..<towerSizes.count) { i in
//                                        Text(String(self.towerSizes[i]))
//                                    }
//                                }
//                                //                            .fixedSize()
//                                //                            .padding(.horizontal)
//                                //                                .padding(.top, 10)
//                                .pickerStyle(SegmentedPickerStyle())
//
//                            }
//                            .padding(.bottom, 7)
//                    }
//        //                if bellCircle.isHost && bellCircle.hostModePermitted {
//        //                    Toggle(isOn: .init(get: {self.bellCircle.hostModeEnabled}, set: { newValue in
//        //                        SocketIOManager.shared.socket?.emit("c_host_mode", ["new_mode":newValue, "tower_id":self.bellCircle.towerID])
//        //                    }) ) {
//        //                        Text("Enable host mode")
//        //                    }
//        //                }
//                    if bellCircle.towerControlsViewSelection == 1 {
//                        UsersView()
//                    } else {
//                        ChatView()
//                    }
//    //                TabView(selection: .init(get: {
//    //                    return bellCircle.towerControlsViewSelection
//    //                }, set: {
//    //                    bellCircle.towerControlsViewSelection = $0
//    //                })) {
//    ////                    Text("df")
//    //                    UsersView()
//    ////                        .padding(.vertical)
//    //                        .padding(.bottom, self.bellCircle.keyboardShowing ? 5 : 102)
//    //                        .tag(1)
//    //                        .padding(.horizontal, 5)
//    //                        .tabItem {
//    //                            Image(systemName: "person")
//    //                            Text("Users")
//    //                        }
//    ////                    Text("tab")
//    ////                        .onAppear {
//    ////                            print("text appeared")
//    ////                        }
//    //                    ChatView()
//    //                        .padding(.horizontal, 5)
//    //                        .padding(.bottom, self.bellCircle.keyboardShowing ? 5 : 102)
//    //                        .tag(2)
//    //                        .tabItem {
//    //                            Image(systemName: "text.bubble")
//    //                            Text("Chat")
//    //                        }
//    //                }
//    ////                .tabViewStyle(PageTabViewStyle())
//    ////                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
//    //                .padding(.top, self.bellCircle.keyboardShowing ? -77 : 0)
//    //                .padding(.bottom, -145)
//    //                .onAppear {
//    //                    print("tab view appeared")
//    //                }
//    //                .padding(.horizontal, -5)
//    //                .accentColor(.main)
//                }
//            }
//            .fixedSize(horizontal: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, vertical: false)
//            .frame(minWidth: geo.size.width, maxWidth: width)
        }
//        .background(Color.red)
    }

    func getNumberOfLines() {
        switch volume {
        case 0:
            speakerSliders = ""
        case 0..<1/3:
            speakerSliders = ".1"
        case 1/3..<2/3:
            speakerSliders = ".2"
        case 2/3...1:
            speakerSliders = ".3"
        default:
            speakerSliders = ".2"
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
        SocketIOManager.shared.socket?.emit("c_audio_change", ["new_audio":self.bellTypes[value].rawValue, "tower_id":self.bellCircle.towerID])
     //
    }

    func sizeChanged(value:Int) {
        SocketIOManager.shared.socket?.emit("c_size_change", ["new_size":towerSizes[value], "tower_id":self.bellCircle.towerID])
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
    
    @ObservedObject var chatManager = ChatManager.shared
    
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
                        bellCircle.fillIn = true
                        var tempUsers = self.bellCircle.users
                        if !tempUsers.containsRingerForID(-1) {
                            for assignedUser in self.bellCircle.assignments {
                                if assignedUser.name != "" {
                                    tempUsers.removeRingerForID(assignedUser.userID)
                                }
                            }
                            for i in 0..<self.bellCircle.size {
                                if self.bellCircle.assignments[i].name == "" {
                                    let index = Int.random(in: 0..<tempUsers.count)
                                    let user = tempUsers[index]
                                    SocketIOManager.shared.socket?.emit("c_assign_user", ["user":user.userID, "bell":i+1, "tower_id":self.bellCircle.towerID])
                                    tempUsers.remove(at: index)
                                }
                            }
                        } else {
                            tempUsers.removeRingerForID(-1)
                            print(tempUsers.ringers)
                            for assignedUser in self.bellCircle.assignments {
                                if assignedUser.name != "" {
                                    tempUsers.removeRingerForID(assignedUser.userID)
                                }
                            }
                            print(tempUsers.ringers)
                            print(self.bellCircle.assignments.ringers)
                            var availableBells = self.bellCircle.assignments.allIndicesOfRingerForID(Ringer.blank.userID)
                            print(availableBells)
                            availableBells.shuffle()
                            tempUsers.shuffle()
                            for user in tempUsers {
                                if let bell = availableBells.first {
                                    SocketIOManager.shared.socket?.emit("c_assign_user", ["user":user.userID, "bell":bell+1, "tower_id":self.bellCircle.towerID])
                                    availableBells.removeFirst()
                                } else {
                                    break
                                }
                            }
                            for bell in availableBells {
                                SocketIOManager.shared.socket?.emit("c_assign_user", ["user":-1, "bell":bell+1, "tower_id":self.bellCircle.towerID])
                            }
                            
                        }
                    }) {
                        Text("Fill In")
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .lineLimit(1)
                    }
                    .background(Color.main.cornerRadius(5))
                    .disabled(!fillInAvailable())
                    .opacity(fillInAvailable() ? 1 : 0.35)
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
                if chatManager.newMessages > 0 {
                    ChatNotificationButton()
                }
            }
//            if self.showingUsers {
                ScrollView(showsIndicators: false) {

                    HStack(alignment: .top) {
                        VStack(spacing: 14) {
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
                        .padding(.top, 10)
                        VStack(alignment: .trailing, spacing: 7) {
                            ForEach(0..<self.bellCircle.assignments.count, id: \.self) { number in
                                HStack(alignment: .center, spacing: 5) {
                                    if self.canUnassign(number)  {
                                        Button(action: {
                                            self.unAssign(bell: number+1)
                                            self.updateView.toggle()
                                        }) {
                                            Text("X")
                                                .foregroundColor(.primary)
                                                .font(.title3)
                                                .fixedSize()
                                                .padding(.vertical, -4)
                                        }
//                                        .background(Color.green)
                                    }
                                    Button(action: self.assign(self.selectedUser, to: number + 1)) {
                                        ZStack {
                                            ZStack {
                                                Circle().fill(Color.main)

                                                Text("1")
                                                    .font(.callout)
                                                    .bold()
                                                    .opacity(0)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                            }
//                                            .fixedSize()


                                            Text(String(number + 1))
                                            .font(.callout)
                                            .bold()
                                                .foregroundColor(Color.white)

                                        }
                                        .fixedSize()
                                    }
                                    .disabled(!(self.bellCircle.assignments[number].name == ""))
                                    .opacity((self.bellCircle.assignments[number].name == "") ? 1 : 0.35)
                                    .animation(.linear(duration: 0.15))
                                    .fixedSize(horizontal: true, vertical: true)
                                    //.background(.black)
                                }
                            }
                            

                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
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
        .background(isSplit ? Color(white: colorScheme == .light ? 1 : 0.08).cornerRadius(5) : Color(white: colorScheme == .light ? 0.94 : 0.08).cornerRadius(5))
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
            SocketIOManager.shared.socket?.emit("c_assign_user", ["user":id, "bell":bell, "tower_id":self.bellCircle.towerID])
        }
    }

    func unAssign(bell:Int) {
        print("unassigning")
        SocketIOManager.shared.socket?.emit("c_assign_user", ["user":0, "bell":bell, "tower_id":self.bellCircle.towerID])
    }

    func fillInAvailable() -> Bool {
        if numberOfAvailableBells() <= 0 {
            return false
        } else {
            if bellCircle.users.containsRingerForID(-1) {
                return true
            } else {
                return numberOfAvailableRingers() >= numberOfAvailableBells()
            }
        }
    }
    
    func numberOfAvailableRingers() -> Int {
        var number = 0
        for ringer in bellCircle.users {
            if !bellCircle.assignments.containsRingerForID(ringer.userID) {
                number += 1
            }
        }
        return number
    }
    
    func numberOfAvailableBells() -> Int {
        return (bellCircle.assignments.allIndicesOfRingerForID(Ringer.blank.userID) ?? [Int]()).count
    }


}

struct RingerView:View {

    var user:Ringer
    var selectedUser:Bool

    @ObservedObject var bellCircle = BellCircle.current

    var body: some View {
        HStack {
            Text(!bellCircle.assignments.containsRingerForID(user.userID) ? "-" : self.getString(indexes: bellCircle.assignments.allIndicesOfRingerForID(user.userID)))
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

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var chatManager = ChatManager.shared

    @State private var currentMessage = ""
    
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
                        VStack(spacing: 5) {
                            if chatManager.messages.count > 0 {
                                ForEach(0..<chatManager.messages.count, id: \.self) { i in
                                    HStack {
                                        (Text(chatManager.messages[i].sender).bold() + Text(": \(chatManager.messages[i].message)"))
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
        .background(isSplit ? Color(white: colorScheme == .light ? 1 : 0.08).cornerRadius(5) : Color(white: colorScheme == .light ? 0.94 : 0.08).cornerRadius(5))
        .onAppear {
            print("chat view appeared")
        }
    }

    func sendMessage() {
        //send message
        SocketIOManager.shared.socket?.emit("c_msg_sent", ["user":User.shared.name, "email":User.shared.email, "msg":currentMessage, "tower_id":BellCircle.current.towerID])
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



struct BellAssignmentViewModifier:ViewModifier {
    var isAvailable:Bool
    
    func body(content: Content) -> some View {
        ZStack {
            Text("1")
                .font(.body)
                .padding(10)
                .opacity(0)
                .background(Circle().fill(Color.main))
                .foregroundColor(Color.main)
            content
                .disabled(isAvailable ? false : true)
                .animation(.linear(duration: 0.1))
                .foregroundColor(Color.white)
        }
        .opacity(isAvailable ? 1 : 0.35)
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


