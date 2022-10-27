//
//  MainView.swift
//  NewRingingRoom
//
//  Created by Matthew on 27/10/2022.
//

import SwiftUI

struct MainView: View {
    
    init(user: User, apiService: APIService) {
        self.user = user
        self.apiService = apiService
    }
    
    @State var user: User
    let apiService: APIService
    
    @StateObject var router = Router<MainRoute>(defaultRoute: .home)

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
            }
        }
        .environmentObject(router)
    }
}
