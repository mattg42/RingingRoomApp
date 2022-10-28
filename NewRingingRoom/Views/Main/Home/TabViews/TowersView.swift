//
//  RingView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

enum TowerListType: String, CaseIterable, Identifiable {
    case recent, bookmarked, created, host
    var id: Self { self }
}

struct TowersView: View {

    @Binding var user: User
    let apiService: APIService

    @State var showingTowerControls = false

    @State private var joinTowerShowing = false
    @State private var createTowerShowing = false
    
    @State private var towerID = ""
    @State private var towerName = ""

    @EnvironmentObject var router: Router<MainRoute>
    
    var body: some View {
            NavigationView {
                VStack(spacing: 8) {
                    HStack {
                        Text("(No tower management in this version)")
                        
                        Spacer()
                    }
                    .padding(.top, -20)
                    
                    HStack {
                        Text("Recent towers - tap to join").font(.headline)
                        
                        Spacer()
                    }
                    
                    ScrollView {
                        ScrollViewReader { reader in
                            VStack {
                                ForEach(user.towers) { tower in
                                    AsyncButton {
                                        await joinTower(id: tower.towerID)
                                    } label: {
                                        HStack() {
                                            Text(String(tower.towerName))
                                            Spacer()
                                        }
                                    }
                                    .contentShape(Rectangle())

                                    .foregroundColor(.main)
                                    .frame(height: 35)
                                    .padding(.horizontal)
                                    .cornerRadius(10)
                                    .id(tower.towerID)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 5)
                    
                    Divider()
                    
                    DisclosureGroup(isExpanded: $joinTowerShowing) {
                        HStack {
                            ZStack {
                                TextField("Tower ID", text: $towerID)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                    .onChange(of: towerID, perform: { value in
                                        if Int(towerID) == nil || towerID.contains("0") {
                                            towerID = towerID.filter("123456789".contains)
                                        }
                                    })
                                
                                if !towerID.isEmpty {
                                    HStack {
                                        Spacer()
                                        
                                        Button {
                                            towerID = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(5)
                                }
                            }
                            
                            AsyncButton {
                                await joinTower(id: Int(towerID)!)
                            } label: {
                                ZStack {
                                    Color.main
                                        .cornerRadius(5)
                                    
                                    Text("Join Tower")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .fixedSize(horizontal: false, vertical: true)
                    } label: {
                        Button {
                            withAnimation {
                                joinTowerShowing.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Join tower by ID")
                                    .font(.headline)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()
                    
                    DisclosureGroup(isExpanded: $createTowerShowing) {
                        ZStack {
                            TextField("Enter name of new tower", text: $towerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if towerName.count > 0 {
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        towerName = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(5)
                            }
                        }
                        .padding(.top, 8)
                        ZStack {
                            AsyncButton {
                                await createTower()
                            } label: {
                                ZStack {
                                    Color.main
                                        .cornerRadius(5)
                                    
                                    Text("Create Tower")
                                        .foregroundColor(.white)
                                }
                                .frame(height: 35)
                            }
                        }
                        .padding(.bottom, 6)
                    } label: {
                        Button {
                            withAnimation {
                                createTowerShowing.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Create new tower").font(.headline)
                                Spacer()
                            }
                        }
                    }
                    
                    .padding(.bottom, 9)
                }
                .padding([.horizontal, .top])
                .navigationTitle("Towers")
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func joinTower(id: Int) async {
        await ErrorUtil.do(networkRequest: true) {
            let towerDetails = try await apiService.getTowerDetails(towerID: id)
            let isHost = user.towers.first(where: { $0.towerID == id })?.host ?? false
            
            connectToTower(towerDetails: towerDetails, isHost: isHost)
        }
    }
    
    func connectToTower(towerDetails: APIModel.TowerDetails, isHost: Bool) {
        let towerInfo = TowerInfo(towerDetails: towerDetails, isHost: isHost)
        
        let socketIOService = SocketIOService(url: URL(string: towerDetails.server_address)!)
        
        let ringingRoomViewModel = RingingRoomViewModel(socketIOService: socketIOService, router: router, towerInfo: towerInfo, token: apiService.token, user: user)
        
        router.moveTo(.ringing(viewModel: ringingRoomViewModel))
        
        Task(priority: .medium) {
            await ErrorUtil.do(networkRequest: true) {
                let towers = try await apiService.getTowers()
                user.towers = towers
            }
        }
    }
    
    func createTower() async {
        await ErrorUtil.do(networkRequest: true) {
            let towerCreationDetails = try await apiService.createTower(called: towerName)
            let towerDetails = APIModel.TowerDetails(tower_id: towerCreationDetails.tower_id, tower_name: towerName, server_address: towerCreationDetails.server_address, additional_sizes_enabled: false, host_mode_permitted: false, half_muffled: false, fully_muffled: false)
            
            connectToTower(towerDetails: towerDetails, isHost: true)
        }
    }
}

struct Divider: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary)
            .opacity(0.4)
            .frame(height: 2)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension Array where Element == Int {
    mutating func removeFirstInstance(of element: Int) {
        for (index, ele) in self.enumerated() {
            if ele == element {
                self.remove(at: index)
                return
            }
        }
    }
    
}
