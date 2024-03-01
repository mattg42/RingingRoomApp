//
//  WheatleyState.swift
//  Ringing Room
//
//  Created by Matthew on 21/02/2024.
//

import Foundation
import Combine

class WheatleyState: ObservableObject {
    @Published var rowGen = RowGen.method(WheatleyMethod(title: "", stage: 0, notation: "", url: "", bob: [Int: String](), single: [Int: String]()))
    @Published var pealSpeed = 0
    
    @Published var fixedStrikingInterval = true
    @Published var wholePullAndOff = true
    @Published var stopAtRounds = true
    @Published var callComposition = true
    @Published var wheatleyIsRunning = false
}
