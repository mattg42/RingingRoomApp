//
//  MainApp.swift
//  iOSRingingRoom
//
//  Created by Matthew on 06/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import SocketIO

struct MainApp: View {
        
    @Environment(\.scenePhase) var scenePhase
    
    @State private var isPresentingHelpView = true
        
    @State var autoJoinTower = false
    @State var autoJoinTowerID = 0

//    var ringView = RingView()
    var ringingRoomView = RingingRoomView()

    
    @ObservedObject var user = User.shared
    
    @ObservedObject var bellCircle = BellCircle.current
    
    @ObservedObject var controller = AppController.shared
        
    var body: some View {
        switch AppController.shared.state {
        case .login:
            if AppController.shared.loginState == .auto {
                AutoLogin()

            } else {
                WelcomeLoginScreen()
                    .accentColor(Color.main)

            }
        case .main:
            TabView(selection: .init(get: {
                controller.selectedTab
            }, set: {
                controller.selectedTab = $0
            })) {
                RingView()
                    .tag(TabViewType.ring)
                    .tabItem {
                        Image(systemName: "list.bullet")
                            .font(.title)
                        Text("Towers")
                    }
                StoreView()
                    .tag(TabViewType.store)
                    .tabItem {
                        Image(systemName: "cart")
                            .font(.title)
                        Text("Store")
                    }
                HelpView(asSheet: false, isPresented: self.$isPresentingHelpView)
                    .tag(TabViewType.help)
                    .tabItem {
                        Image(systemName: "questionmark.circle")
                            .font(.title)
                        Text("Help")
                    }
                SettingsView()
                    .tag(TabViewType.settings)
                    .tabItem {
                        Image(systemName: "gear")
                            .font(.title)
                        Text("Settings")
                    }
            }
            
            .accentColor(Color.main)
        case .ringing:
            ringingRoomView
                .onChange(of: scenePhase, perform: { phase in
                    print("new phase: \(phase)")
                    if phase == .active {
                        SocketIOManager.shared.refresh = true
                        SocketIOManager.shared.socket?.connect()
                    } else if phase == .background {
                        SocketIOManager.shared.socket?.disconnect()
                    }
                })
                .accentColor(Color.main)

        }
    }
}

enum TabViewType:Hashable {
    case ring, help, store, settings
}

extension Color {
    public static var main:Color {
        return Color(red: 178/255, green: 39/255, blue: 110/255)
    }
}

struct MainApp_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
