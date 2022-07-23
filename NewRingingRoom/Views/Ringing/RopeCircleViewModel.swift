//
//  RopeCircleViewModel.swift
//  NewRingingRoom
//
//  Created by Matthew on 14/07/2022.
//

import SwiftUI

class RopeCircleViewModel: ObservableObject {
    
    @Published var imageSize = 0.0
    @Published var assignmentsWidth = 0.0
    @Published var assignmentsHeight = 0.0
    
    var radius = 0.0

    @Published var bellPositions = [CGPoint]()
    
    func updateImage(screenSize: CGSize, centre: CGPoint, size: Int, bellType: BellType, perspective: Int) {
        calculateImageSize(screenSize: screenSize, size: size, bellType: bellType)
        calculateBellPositions(centre: centre, size: size, bellType: bellType, perspective: perspective)
    }

    func calculateImageSize(screenSize: CGSize, size: Int, bellType: BellType) {
        print("new image size")
        var newImageSize = 0.0
        var newRadius = Double(min(screenSize.width/2, screenSize.height/2))
        newRadius = min(newRadius, 300)
        let originalRadius = newRadius
        let theta = Double.pi/Double(size)
        newImageSize = sin(theta) * newRadius * 2
        (newImageSize, newRadius) = reduceOverlap(width: screenSize.width, height: screenSize.height, imageSize: newImageSize, radius: newRadius, theta: theta, size: size, bellType: bellType)
        newImageSize = min(newImageSize, originalRadius*0.6)
        (imageSize, radius) = reduceOverlap(width: screenSize.width, height: screenSize.height, imageSize: newImageSize, radius: newRadius, theta: theta, size: size, bellType: bellType)
        radius = min(radius, 350)
    }
    
    func calculateBellPositions(centre: CGPoint, size: Int, bellType: BellType, perspective: Int) {
        
        let angleIncrement:Double = 360/Double(size)
        let startAngle:Double = 360 - (-angleIncrement/2 + angleIncrement*Double(perspective))
        
        var newPositions = [CGPoint]()
                
        var currentAngle = startAngle
        
        for _ in 0..<size {
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians)) * radius
            var y = CGFloat(cos(Angle(degrees: currentAngle).radians)) * radius
            
            if size % 4 == 0 {
                if ((90.0)...(270.0)).contains(currentAngle) {
                    y -= 7.5
                } else {
                    y += 7.5
                }
            }
            
            let bellPos = CGPoint(x: centre.x + x, y: centre.y + y)
            
            newPositions.append(bellPos)
            currentAngle += angleIncrement
            if currentAngle > 360 {
                currentAngle -= 360
            }
        }
        
        bellPositions = newPositions
    }
    
    func reduceOverlap(width:CGFloat, height:CGFloat, imageSize:Double, radius:Double, theta:Double, size: Int, bellType: BellType) -> (Double, Double) {
        var vOverlap = 0.0
        var hOverlap = 0.0
        
        var maxOverlap = 0.0
        
        var newRadius = radius
        var newImageSize = imageSize
        
        
        var a = radius
        
        if size % 2 == 0 {
            a = cos(theta) * newRadius
        }
        
        if bellType == .tower {
            vOverlap = a + imageSize/2 - Double(height)/2
        } else {
            vOverlap = a + (imageSize*0.6)/2 - Double(height)/2
        }
        
        if size % 4 == 0 {
            vOverlap += 7.5
        }
        
        
        a = radius
        if size % 2 == 1 {
            a =  cos(theta/2) * newRadius
        } else if size % 4 == 0 {
            a = cos(theta) * newRadius
        }
        if bellType == .tower {
            hOverlap = a + (imageSize/3)/2 - Double(width)/2
        } else {
            hOverlap = a + (imageSize*0.6)/2 - Double(width)/2
        }
        if size == 4 {
            hOverlap += 30
        }
        
        maxOverlap = max(vOverlap, hOverlap)
        
        if size == 4 {
            if maxOverlap >= -20 {
                newRadius = radius - 5
                
                newImageSize = sin(theta) * newRadius * 2
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta, size: size, bellType: bellType)
            } else if maxOverlap < -25 {
                
                newRadius = radius + 5
                
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta, size: size, bellType: bellType)
                
                
            } else {
                return (newImageSize, newRadius)
            }
        } else {
            
            if maxOverlap >= -5 {
                newRadius = radius - 5
                
                newImageSize = sin(theta) * newRadius * 2
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta, size: size, bellType: bellType)
            } else if maxOverlap < -7.5 {
                
                newRadius = radius + 2.5
                
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta, size: size, bellType: bellType)
                
                
            } else {
                return (newImageSize, newRadius)
            }
        }
    }
    
    func getAssignmentsHeight(size: Int, perspective: Int, bellType: BellType, imageHeight: CGFloat) {
        
        var returnValue:CGFloat = 0
        if bellPositions.count == size {
            if size == 5 {
                var top = perspective
                top += 3
                if top > 5{
                    top -= 5
                }
                returnValue = bellPositions[perspective - 1].y - bellPositions[top-1].y
                
            } else if perspective <= Int(size/2) {
                returnValue = (bellPositions[perspective - 1].y - bellPositions[perspective - 1 + Int(ceil(Double(size/2)))].y)
            } else {
                returnValue = (bellPositions[perspective - 1].y - bellPositions[perspective - 1 - Int(ceil(Double(size/2)))].y)
            }
        }
        returnValue -= 10
        
        if size != 4 {
            returnValue -= imageHeight
        }
        
        assignmentsHeight = returnValue
    }
    
    func getAssignmentsWidth(size: Int, perspective: Int, bellType: BellType, imageWidth: CGFloat) {
        var returnValue:CGFloat = 0
        
        if bellPositions.count == size {
            var leftBellNumber = perspective + 2
            if leftBellNumber > size {
                leftBellNumber -= size
            }
            var rightBellNumber = perspective - 1
            if rightBellNumber <= 0 {
                rightBellNumber += size
            }
            let left = bellPositions[leftBellNumber-1].x
            let right = bellPositions[rightBellNumber-1].x
            
            returnValue = right - left
            if size == 4 && bellType == .hand {
                assignmentsWidth = returnValue
            } else if size == 4 {
                returnValue -= imageWidth
                assignmentsWidth = returnValue
            } else {
                
                returnValue -= 20
                if ![4, 14, 16].contains(size) {
                    returnValue -= 30
                }
                returnValue = min(returnValue, 160)
                
                assignmentsWidth = returnValue
            }
        }
    }
}
