//
//  MainView.swift
//  NewRingingRoom
//
//  Created by Matthew on 27/10/2022.
//

import SwiftUI

struct MainView: View {
    
    init(user: User, apiService: APIService, route: MainRoute) {
        self.user = user
        self.apiService = apiService
        self._router = StateObject(wrappedValue: Router<MainRoute>(defaultRoute: route))
    }
    
    @State var user: User
    let apiService: APIService
    
    @StateObject var router: Router<MainRoute>
    
    var body: some View {
        Group {
            switch router.currentRoute {
            case .home:
                HomeView(user: $user, apiService: apiService)
            case .ringing(let viewModel):
                RingingRoomView()
                    .environmentObject(viewModel)
                    .environmentObject(viewModel.state)
                    .environmentObject(viewModel.towerControlsState)
            case .joinTower(let towerID, let towerDetails):
                JoinTowerView(user: $user, apiService: apiService, towerID: towerID, towerDetails: towerDetails)
            }
        }
        .environmentObject(router)
    }
}
