//
//  HomeView.swift
//  NewRingingRoom
//
//  Created by Matthew on 22/04/2022.
//

import SwiftUI

enum TabViewType {
    case ring, help, store, settings
}

struct HomeView: View {
    
    @EnvironmentObject var router: Router<MainRoute>
    
    @Binding var user: User
    let apiService: APIService
    
    @State private var showingPrivacyPolicyView = false
    
    init(user: Binding<User>, apiService: APIService) {
        print("Init")
        self._user = user
        self.apiService = apiService
        self._tabViewSelection = State(initialValue: .ring)
    }
    
    @State var tabViewSelection: TabViewType
    
    var body: some View {
        TabView(selection: $tabViewSelection) {
            TowersView(user: $user, apiService: apiService)
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
            AccountView(user: user, apiService: apiService)
                .tag(TabViewType.settings)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title)
                    Text("Account")
                }
        }
        .onAppear {
            tabViewSelection = .ring
            print("Called")
        }
        .sheet(isPresented: $showingPrivacyPolicyView, content: {
            PrivacyPolicyWebView(isPresented: $showingPrivacyPolicyView)
            
        })

        .accentColor(Color.main)

    }
}
