//
//  DeeplinkView.swift
//  NewRingingRoom
//
//  Created by Matthew on 25/11/2022.
//

import SwiftUI

struct JoinTowerView: View {
    
//    init(user: Binding<User>, apiService: APIService, towerID: Int, towerDetails: APIModel.TowerDetails?) {
//        self._user = user
//        self.apiService = apiService
//        self.towerID = towerID
//        self.towerDetails = towerDetails
//    }
//
    @Binding var user: User
    let apiService: APIService
    let makeSocketTransport: @MainActor (URL) -> any SocketTransport
    let makeAudioPlayer: @MainActor () -> any AudioPlaying
    let preferences: any PreferencesStoring
    let alertPresenter: any AlertPresenting
    let scheduler: any TaskScheduling
    
    @EnvironmentObject var router: Router<MainRoute>
    
    let towerID: Int
    let towerDetails: APIModel.TowerDetails?

    init(
        user: Binding<User>,
        apiService: APIService,
        towerID: Int,
        towerDetails: APIModel.TowerDetails?,
        makeSocketTransport: @escaping @MainActor (URL) -> any SocketTransport = { SocketIOService(url: $0) },
        makeAudioPlayer: @escaping @MainActor () -> any AudioPlaying = { AudioService() },
        preferences: any PreferencesStoring = UserDefaultsPreferences(),
        alertPresenter: any AlertPresenting = SystemAlertPresenter(),
        scheduler: any TaskScheduling = LiveTaskScheduler()
    ) {
        self._user = user
        self.apiService = apiService
        self.towerID = towerID
        self.towerDetails = towerDetails
        self.makeSocketTransport = makeSocketTransport
        self.makeAudioPlayer = makeAudioPlayer
        self.preferences = preferences
        self.alertPresenter = alertPresenter
        self.scheduler = scheduler
    }
    
    var body: some View {
        Color(.ringingRoomBackground)
            .ignoresSafeArea()
            .task {
                await joinTower(id: towerID, towerDetails: towerDetails)
            }
    }
    
    func joinTower(id: Int, towerDetails: APIModel.TowerDetails?) async {
        await ErrorUtil.do(networkRequest: true) {
            if let towerDetails {
                try connectToTower(towerDetails: towerDetails, isHost: true)
            } else {
                let towerDetails = try await apiService.getTowerDetails(towerID: id)
                let isHost = user.towers.first(where: { $0.towerID == id })?.host ?? false
                
                try connectToTower(towerDetails: towerDetails, isHost: isHost)
            }
        }
    }
    
    func connectToTower(towerDetails: APIModel.TowerDetails, isHost: Bool) throws {
        guard let url = URL(string: towerDetails.server_address),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "ws", "wss"].contains(scheme),
              url.host != nil else {
            throw APIError.invalidURL(attemptedURL: towerDetails.server_address)
        }

        let towerInfo = TowerInfo(towerDetails: towerDetails, isHost: isHost)
        
        let socketIOService = makeSocketTransport(url)

        let ringingRoomViewModel = RingingRoomViewModel(
            socketIOService: socketIOService,
            router: router,
            towerInfo: towerInfo,
            apiService: apiService,
            user: user,
            audioService: makeAudioPlayer(),
            preferences: preferences,
            alertPresenter: alertPresenter,
            scheduler: scheduler
        )
        
        router.moveTo(.ringing(viewModel: ringingRoomViewModel))
    }
}
