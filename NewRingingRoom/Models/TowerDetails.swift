//
//  TowerInfo.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation

enum Muffled {
    case none, half, full
}

struct TowerInfo {
    let additionalSizesEnabled: Bool
    
    var towerSizes: [Int] {
        additionalSizesEnabled ? [4, 5, 6, 8, 10, 12, 14, 16] : [4, 6, 8, 10, 12]
    }
    
    let halfMuffled: Bool
    let hostModePermitted: Bool
    let isHost: Bool
    let serverAddress: String
    let towerID: Int
    let towerName: String
    let muffled: Muffled
    
    init(towerDetails: APIModel.TowerDetails, isHost: Bool) {
        self.isHost = isHost
        self.additionalSizesEnabled = towerDetails.additional_sizes_enabled
        self.halfMuffled = towerDetails.half_muffled
        self.hostModePermitted = towerDetails.host_mode_permitted
        self.serverAddress = towerDetails.server_address
        self.towerID = towerDetails.tower_id
        self.towerName = towerDetails.tower_name
        if towerDetails.fully_muffled {
            muffled = .full
        } else if towerDetails.half_muffled {
            muffled = .half
        } else {
            muffled = .none
        }
    }
}
