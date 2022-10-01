//
//  MainView.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/04/2022.
//

import SwiftUI

enum TabViewType {
    case ring, help, store, settings
}

struct MainView: View {
    
    let user: User
    let apiService: APIService
    
    @State var showingPrivacyPolicyView = false
    
    var body: some View {
        TabView {
            TowersView(user: user, apiService: apiService)
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
            HelpView(showDismiss: false)
                .tag(TabViewType.help)
                .tabItem {
                    Image(systemName: "questionmark.circle")
                        .font(.title)
                    Text("Help")
                }
//            AccountView()
//                .tag(TabViewType.settings)
//                .tabItem {
//                    Image(systemName: "person.crop.circle.fill")
//                        .font(.title)
//                    Text("Account")
//                }
        }
        .sheet(isPresented: $showingPrivacyPolicyView, content: {
            PrivacyPolicyWebView(isPresented: $showingPrivacyPolicyView)
            
        })
//        .onOpenURL(perform: { url in
//            let pathComponents = url.pathComponents.dropFirst()
//            print(pathComponents)
//            if let firstPath = pathComponents.first {
//                if firstPath == "privacy" {
//                    showingPrivacyPolicyView = true
//                } else if let towerID = Int(firstPath) {
//                    if NetworkManager.token != nil {
//                        joinTower(id: towerID)
//                    }
//                }
//            }
//        })
        .accentColor(Color.main)
    }
}
