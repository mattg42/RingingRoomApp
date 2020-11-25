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
    
    @State private var selectedTab = TabViewType.ring
    
    @State private var isPresentingHelpView = true
        
    @State var autoJoinTower = false
    @State var autoJoinTowerID = 0

    var ringView = RingView()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ringView
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
        .onAppear {
            if autoJoinTower {
                User.shared.towerID = String(autoJoinTowerID)
                self.ringView.joinTower()
            }
        }
        .onOpenURL { url in
            guard let towerID = url.towerID else { return }
            self.selectedTab = TabViewType.ring
            User.shared.towerID = String(towerID)
            self.ringView.joinTower()
        }
        .accentColor(Color.main)
        
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
