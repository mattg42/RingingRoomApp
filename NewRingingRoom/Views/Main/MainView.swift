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
    
    @State private var user: User
    let apiService: APIService
    
    @StateObject var router: Router<MainRoute>
    
    var body: some View {
        Group {
            switch router.currentRoute {
            case .home:
                HomeView(user: $user, apiService: apiService)
            case .ringing(let viewModel):
                RingingRoomView(user: $user, apiService: apiService)
                    .environmentObject(viewModel)
                    .environmentObject(viewModel.state)
                    .environmentObject(viewModel.towerControlsState)
            case .joinTower(let towerID, let towerDetails):
                JoinTowerView(user: $user, apiService: apiService, towerID: towerID, towerDetails: towerDetails)
            }
        }
        .environmentObject(router)
        .onOpenURL(perform: { url in
            let pathComponents = url.pathComponents.dropFirst()
            print(pathComponents)
            if let firstPath = pathComponents.first {
                if let towerID = Int(firstPath) {
                    router.moveTo(.joinTower(towerID: towerID, towerDetails: nil))
                }
            }
        })
    }
}
