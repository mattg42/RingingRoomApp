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
    var body: some View {
        TabView {
            RingView()
                .tabItem {
                    Image(systemName: "bell")
                        .font(.title)
                    Text("Ring")
            }
            TowersView()
                .tabItem {
                    Image(systemName: "list.bullet")
                        .font(.title)
                    Text("Towers")
            }
            StoreView()
                .tabItem {
                    Image(systemName: "cart")
                        .font(.title)
                    Text("Store")
            }
            HelpView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                        .font(.title)
                    Text("Help")
            }
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                        .font(.title)
                    Text("Settings")
            }
        }
        .accentColor(Color(red: 178/255, green: 39/255, blue: 110/255))
        
    }
}
