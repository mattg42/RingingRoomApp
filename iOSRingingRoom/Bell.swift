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
    
    var audioController = AudioController()
    
    var size = 1
    
    var perspective = 1
    
    @Published var setupComplete = false
    
    @Published var bellType:BellType = BellType.hand
    
    var baseRadius = 0
    
    var center = CGPoint(x: 0, y: 0)
    
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
    
    var assignments = [Ringer]()
    
    var bellPositions = [BellPosition]()
    
    var bellStates = [Bool]()
    
    func getNewPositions(radius:Double, center:CGPoint) {
        let angleIncrement:Double = 360/Double(size)
        let startAngle:Double = 360 - (-angleIncrement/2 + angleIncrement*Double(perspective))
        
        var newPositions = [BellPosition]()
        
        var currentAngle = startAngle
        for i in 0..<size {
            
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians) * radius)
            let y = CGFloat(cos(Angle(degrees: currentAngle).radians) * radius)
            
            let bellPos = BellPosition(pos: CGPoint(x: center.x + x, y: center.y + y), side: .right)
            print(currentAngle)
            if (0..<180).contains(currentAngle) {
                bellPos.side = .left
                print("changed")
            }
            newPositions.append(bellPos)
            currentAngle += angleIncrement
            if currentAngle > 360 {
                currentAngle -= 360
            }
        }
        
        for position in newPositions {
            print(position.side)
        }
        
        bellPositions = newPositions
        setupComplete = true
    }
    
    func bellRang(number:Int) {
        var fileName = String(number)
        fileName.prefix(bellType.rawValue.first)
        audioController.play(fileName)
        bellStates[number - 1].toggle()
    }
    
    func newSize(_ newSize:Int) {
        assignments = 
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
