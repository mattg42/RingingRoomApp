//
//  MainView.swift
//  NewRingingRoom
//
//  Created by Matthew on 27/10/2022.
//

import SwiftUI

struct MainView: View {
    
    init(
        user: User,
        apiService: APIService,
        route: MainRoute,
        makeSocketTransport: @escaping @MainActor (URL) -> any SocketTransport = { SocketIOService(url: $0) },
        makeAudioPlayer: @escaping @MainActor () -> any AudioPlaying = { AudioService() },
        preferences: any PreferencesStoring = UserDefaultsPreferences(),
        alertPresenter: any AlertPresenting = SystemAlertPresenter(),
        scheduler: any TaskScheduling = LiveTaskScheduler()
    ) {
        self.user = user
        self.apiService = apiService
        self._router = StateObject(wrappedValue: Router<MainRoute>(defaultRoute: route))
        self.makeSocketTransport = makeSocketTransport
        self.makeAudioPlayer = makeAudioPlayer
        self.preferences = preferences
        self.alertPresenter = alertPresenter
        self.scheduler = scheduler
    }
    
    @State private var user: User
    let apiService: APIService
    let makeSocketTransport: @MainActor (URL) -> any SocketTransport
    let makeAudioPlayer: @MainActor () -> any AudioPlaying
    let preferences: any PreferencesStoring
    let alertPresenter: any AlertPresenting
    let scheduler: any TaskScheduling

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
                JoinTowerView(
                    user: $user,
                    apiService: apiService,
                    towerID: towerID,
                    towerDetails: towerDetails,
                    makeSocketTransport: makeSocketTransport,
                    makeAudioPlayer: makeAudioPlayer,
                    preferences: preferences,
                    alertPresenter: alertPresenter,
                    scheduler: scheduler
                )
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
        .onChange(of: pendingDeepLinkRouter.pendingTowerID) {
            openPendingTowerIfNeeded()
        }
    }

    private func openPendingTowerIfNeeded() {
        guard let towerID = pendingDeepLinkRouter.consumeTowerID() else { return }
        router.moveTo(.joinTower(towerID: towerID, towerDetails: nil))
    }
}
