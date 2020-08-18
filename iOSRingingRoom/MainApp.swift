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
        .accentColor(Color.main)
//        .onAppear(perform: {
//            UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
//        })
        
    }
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
