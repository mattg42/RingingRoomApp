//
//  MainView.swift
//  NewRingingRoom
//
//  Created by Matthew on 27/10/2022.
//

import SwiftUI

struct MainView: View {
    
    init(user: User, apiService: APIService, autoJoinTower: Int?) {
        self.user = user
        self.apiService = apiService
        self.autoJoinTower = autoJoinTower
    }
    
    @State var user: User
    let apiService: APIService
    
    @StateObject var router = Router<MainRoute>(defaultRoute: .home)

    @State var autoJoinTower: Int?
    
    var body: some View {
        Group {
            switch router.currentRoute {
            case .home:
                HomeView(user: $user, apiService: apiService, autoJoinTower: $autoJoinTower)
            case .ringing(let viewModel):
                RingingRoomView()
                    .environmentObject(viewModel)
                    .environmentObject(viewModel.state)
                    .environmentObject(viewModel.towerControlsState)
            }
        }
        .environmentObject(router)
    }
}
