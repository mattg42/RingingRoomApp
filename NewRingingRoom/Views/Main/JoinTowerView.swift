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
    
    @EnvironmentObject var router: Router<MainRoute>
    
    let towerID: Int
    let towerDetails: APIModel.TowerDetails?
    
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
                connectToTower(towerDetails: towerDetails, isHost: true)
            } else {
                let towerDetails = try await apiService.getTowerDetails(towerID: id)
                let isHost = user.towers.first(where: { $0.towerID == id })?.host ?? false
                
                connectToTower(towerDetails: towerDetails, isHost: isHost)
            }
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
}
