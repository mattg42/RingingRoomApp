//
//  Bell.swift
//  iOSRingingRoom
//
//  Created by Matthew on 17/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

enum Side {
    case left, right
}

enum BellType:String {
    case tower = "Tower", hand = "Hand"
}


class BellCircle: ObservableObject {
    static var current = BellCircle()
    
    static var sounds = [
        BellType.tower : [
        4: ["5","6","7","8"],
        6: ["3","4","5","6","7","8"],
        8: ["1","2sharp","3","4","5","6","7","8"],
        10: ["3","4","5","6","7","8","9","0","E","T"],
        12: ["1","2","3","4","5","6","7","8","9","0","E","T"]
        ],
        BellType.hand : [
        4: ["5","6","7","8"],
        6: ["7","8","9","0","E","T"],
        8: ["5","6","7","8","9","0","E","T"],
        10: ["3","4","5","6","7","8","9","0","E","T"],
        12: ["1","2","3","4","5","6","7","8","9","0","E","T"]
        ]
    ]
    
    var towerID = 0
    var towerName = ""
    
    var isHost = false
    var hostModeEnabled = false
    
    var audioController = AudioController()
    
    @Published var size = 1
    
    var perspective = 1
    
    @Published var setupComplete = false
    
    @Published var bellType:BellType = BellType.tower
    
    var baseRadius:CGFloat = 0
    
    var center = CGPoint(x: 0, y: 0)
    
    var timer = Timer()
    var counter = 0.000
    
    var radius:CGFloat {
        get {
            var returnValue = self.baseRadius
            returnValue -= 20
            if bellType == .hand {
                switch self.size {
                case 6:
                    returnValue -= 20
                case 10:
                    returnValue -= 10
                case 12:
                    returnValue -= 5
                default:
                    returnValue -= 0
                }
            }
            return returnValue
        }
    }
    
    var users = [Ringer]()
    
    @Published var currentCall = ""
    var callTimer = Timer()
    
    var assignments = [Ringer]()
    
    var bellPositions = [BellPosition]()
    
    @Published var bellStates = [Bool]()
    
    func getNewPositions(radius:CGFloat, center:CGPoint) {
        let angleIncrement:Double = 360/Double(size)
        let startAngle:Double = 360 - (-angleIncrement/2 + angleIncrement*Double(perspective))
        
        var newPositions = [BellPosition]()
        
        var currentAngle = startAngle
        for _ in 0..<size {
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians)) * radius
            let y = CGFloat(cos(Angle(degrees: currentAngle).radians)) * radius
            
            let bellPos = BellPosition(pos: CGPoint(x: center.x + x, y: center.y + y), side: .right)
            if (0..<180).contains(currentAngle) {
                bellPos.side = .left
            }
            newPositions.append(bellPos)
            currentAngle += angleIncrement
            if currentAngle > 360 {
                currentAngle -= 360
            }
        }
        
        print(center)
        for pos in newPositions {
            print(pos.pos)
        }
        print("got new positions")
        bellPositions = newPositions
        setupComplete = true
    }
    
    func bellRang(number:Int, bellStates:[Bool]) {
        print(counter)
        var fileName = BellCircle.sounds[bellType]![size]![number-1]
        fileName = fileName.prefix(String(bellType.rawValue.first!))
        audioController.play(fileName)
//        objectWillChange.send()
        self.bellStates = bellStates
    }
    
    func callMade(_ call:String) {
        audioController.play("C" + call)
        currentCall = call
        callTimer.invalidate()
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { _ in
            self.currentCall = ""
        })
    }
    
    func newSize(_ newSize:Int) {
        if newSize > size {
            for _ in 0..<(newSize - size) {
                assignments.append(Ringer.blank)
            }
        } else if newSize < size {
            assignments = Array(assignments[..<newSize])
        }
        bellStates = Array(repeating: true, count: newSize)
        size = newSize
        getNewPositions(radius: radius, center: center)
    }
    
}

class BellPosition {
    var pos:CGPoint
    var side:Side
    
    init(pos:CGPoint, side:Side) {
        self.pos = pos
        self.side = side
    }
}
