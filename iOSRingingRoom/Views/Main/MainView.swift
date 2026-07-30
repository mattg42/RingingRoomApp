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

    @EnvironmentObject private var appRouter: Router<AppRoute>
    @EnvironmentObject private var pendingDeepLinkRouter: PendingDeepLinkRouter
    
    @StateObject var router: Router<MainRoute>
    
    var body: some View {
        Group {
            switch router.currentRoute {
            case .home:
//                Text("Hi")
                HomeView(user: $user, apiService: apiService)
            case .ringing(let viewModel):
                RingingRoomView(user: $user, apiService: apiService)
                    .environmentObject(viewModel)
                    .environmentObject(viewModel.state)
                    .environmentObject(viewModel.wheatleyState)
            case .joinTower(let towerID, let towerDetails):
                JoinTowerView(user: $user, apiService: apiService, towerID: towerID, towerDetails: towerDetails)
            }
        }
        .environmentObject(router)
        .onAppear {
            apiService.sessionExpiredAction = { [weak appRouter] in
                appRouter?.moveTo(.login)
            }
            openPendingTowerIfNeeded()
        }
        .onDisappear {
            apiService.sessionExpiredAction = nil
        }
        .onChange(of: pendingDeepLinkRouter.pendingTowerID) { _ in
            openPendingTowerIfNeeded()
        }
    }

    private func openPendingTowerIfNeeded() {
        guard let towerID = pendingDeepLinkRouter.consumeTowerID() else { return }
        router.moveTo(.joinTower(towerID: towerID, towerDetails: nil))
    }
}
