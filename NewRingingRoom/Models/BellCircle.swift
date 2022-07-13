//
//  BellCircle.swift
//  NewRingingRoom
//
//  Created by Matthew on 13/07/2022.
//

import Foundation
import AVFoundation

enum BellType: String, CaseIterable {
    case tower = "Tower", hand = "Hand"
    
    var sounds: [Int: [String]] {
        switch self {
        case .tower:
            return [
                4: ["5","6","7","8"],
                5: ["4","5","6","7","8"],
                6: ["3","4","5","6","7","8"],
                8: ["1","2sharp","3","4","5","6","7","8"],
                10: ["3","4","5","6","7","8","9","0","E","T"],
                12: ["1","2","3","4","5","6","7","8","9","0","E","T"],
                14: ["e3", "e4", "1","2","3","4","5","6","7","8","9","0","E","T"],
                16: ["e1","e2","e3","e4","1","2","3","4","5","6","7","8","9","0","E","T"]
            ]
        case .hand:
            return [
                4: ["9","0","E","T"],
                5: ["8","9","0","E","T"],
                6: ["7", "8", "9", "0", "E", "T"],
                8: ["5", "6", "7", "8", "9", "0", "E", "T"],
                10: ["3", "4", "5", "6", "7", "8", "9", "0", "E", "T"],
                12: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "E", "T"],
                14: ["3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"],
                16: ["1", "2", "3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"],
            ]
        }
    }
}

enum BellStroke {
    case hand, back
    
    init(bool: Bool) {
        if bool { self = .hand }
        else { self = .back }
    }
    
    var boolValue: Bool {
        switch self {
        case .hand:
            return true
        case .back:
            return false
        }
    }
}

class BellCircle {
    internal init(towerInfo: TowerInfo, size: Int, bellType: BellType, users: [Ringer], assignments: [Ringer], bellStrokes: [BellStroke]) {
        self.towerInfo = towerInfo
        self.size = size
        self.bellType = bellType
        self.users = users
        self.assignments = assignments
        self.bellStrokes = bellStrokes
        
        self.socketIOService = SocketIOService(url: URL(string: towerInfo.serverAddress)!)
        self.socketIOService.delegate = self
    }
    
    var socketIOService: SocketIOService
    
    var towerInfo: TowerInfo
        
    var size: Int
    var bellType: BellType
    
    var users: [Ringer]
    var assignments: [Ringer]
    
    var bellStrokes: [BellStroke]
}

protocol BellCircleDelegate: AnyObject {
    func didConnectToServer()
    func sizeDidChange(to newSize: Int)
    func userDidEnter(_ ringer: Ringer)
    func userDidLeave(_ ringer: Ringer)
    func didReceiveGlobalState(_ globalState: [BellStroke])
    func didReceiveUserList(_ userList: [Ringer])
    func bellDidRing(number: Int, globalState: [BellStroke])
    func didAssign(ringerID: Int, to bell: Int)
    func audioDidChange(to: BellType)
    func hostModeDidChange(to: Bool)
    func didReceiveMessage(_ message: Message)
    func didReceiveCall(_ call: String)
}

extension BellCircle: BellCircleDelegate {
    func didConnectToServer() {
        <#code#>
    }
    
    func userDidEnter(_ ringer: Ringer) {
        <#code#>
    }
    
    func userDidLeave(_ ringer: Ringer) {
        <#code#>
    }
    
    func didReceiveGlobalState(_ globalState: [BellStroke]) {
        <#code#>
    }
    
    func didReceiveUserList(_ userList: [Ringer]) {
        <#code#>
    }
    
    func bellDidRing(number: Int, globalState: [BellStroke]) {
        <#code#>
    }
    
    func didAssign(ringerID: Int, to bell: Int) {
        <#code#>
    }
    
    func audioDidChange(to: BellType) {
        <#code#>
    }
    
    func hostModeDidChange(to: Bool) {
        <#code#>
    }
    
    func sizeDidChange(to newSize: Int) {
        <#code#>
    }
    
    func didReceiveMessage(_ message: Message) {
        <#code#>
    }
    
    func didReceiveCall(_ call: String) {
        <#code#>
    }
}
