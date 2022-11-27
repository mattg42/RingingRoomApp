//
//  RopeCircleView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

import SwiftUI

struct RopeCircleView: View {
    
    @EnvironmentObject var state: RingingRoomState
    
    @State private var imageSize: CGFloat = 0
    @State private var radius: CGFloat = 0
    @State private var bellPositions = [CGPoint]()

    
    var body: some View {
        if state.ringer != nil {
            GeometryReader { geo in
                ZStack {
                    BellsView(bellPositions: bellPositions, imageWidth: imageWidth(size: imageSize, bellType: state.bellType), imageHeight: imageHeight(size: imageSize, bellType: state.bellType))
                        .onChange(of: state.size) { _ in
                            calculateImageSize(size: geo.size)
                            getNewPositions(radius: radius, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                        }
                        .onChange(of: state.perspective) { _ in
                            getNewPositions(radius: radius, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                            
                        }
                        .onChange(of: state.bellType) { _ in
                            calculateImageSize(size: geo.size)
                            getNewPositions(radius: radius, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                        }
                        .onChange(of: geo.size) { _ in
                            calculateImageSize(size: geo.size)
                            getNewPositions(radius: radius, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                        }
                        .onAppear {
                            print("Rope circle appeared")
                        }
                    
                    AssignmentsListView(bellPositions: bellPositions, imageWidth: imageWidth(size: imageSize, bellType: state.bellType), imageHeight: imageHeight(size: imageSize, bellType: state.bellType), geo: geo)
                    
                    CallView()
                        .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                        .onAppear {
                            calculateImageSize(size: geo.size)
                            getNewPositions(radius: radius, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                            print("calculated")
                        }
                }
            }
        }
    }
    
    // MARK: - Bell image methods
    
    func imageWidth(size: CGFloat, bellType: BellType) -> CGFloat {
        if bellType == .tower {
            return size / 3
        } else {
            return size * 0.7
        }
    }
    
    func imageHeight(size: CGFloat, bellType: BellType) -> CGFloat {
        if bellType == .tower {
            return size
        } else {
            return size * 0.6
        }
    }
    
    func getNewPositions(radius: CGFloat, centre:CGPoint) {
        
        let angleIncrement = 360.0 / Double(state.size)
        let startAngle = 360 - (-angleIncrement / 2 + angleIncrement * Double(state.perspective))
        
        var newPositions = [CGPoint]()
                
        var currentAngle = startAngle
        
        for _ in 0..<state.size {
            let x = -CGFloat(sin(Angle(degrees: currentAngle).radians)) * radius
            var y = CGFloat(cos(Angle(degrees: currentAngle).radians)) * radius
            
            if state.size % 4 == 0 {
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
    
    func calculateImageSize(size: CGSize) {
        var newImageSize: CGFloat = 0.0
        
        var newRadius = min(size.width/2, size.height/2)
        
        newRadius = min(newRadius, 300)
        
        let originalRadius = newRadius
        let theta = CGFloat.pi / CGFloat(state.size)
        
        newImageSize = sin(theta) * newRadius * 2
        (newImageSize, newRadius) = reduceOverlap(width: size.width, height: size.height, imageSize: newImageSize, radius: newRadius, theta: theta)
        
        newImageSize = min(newImageSize, originalRadius*0.6)
        
        (imageSize, radius) = reduceOverlap(width: size.width, height: size.height, imageSize: newImageSize, radius: newRadius, theta: theta)
    }
    
    func reduceOverlap(width: CGFloat, height: CGFloat, imageSize: CGFloat, radius: CGFloat, theta: Double) -> (CGFloat, CGFloat) {
        var vOverlap = 0.0
        var hOverlap = 0.0
        
        var maxOverlap = 0.0
        
        var newRadius = radius
        var newImageSize = imageSize
        
        
        var a = radius
        
        if state.size % 2 == 0 {
            a = cos(theta) * newRadius
        }
        
        vOverlap = a + imageHeight(size: imageSize, bellType: state.bellType) / 2 - height / 2
        
        if state.size % 4 == 0 {
            vOverlap += 7.5
        }
        
        a = radius
        if state.size % 2 == 1 {
            a =  cos(theta/2) * newRadius
        } else if state.size % 4 == 0 {
            a = cos(theta) * newRadius
        }
        
        hOverlap = a + imageWidth(size: imageSize, bellType: state.bellType) / 2 - width / 2
        
        if state.size == 4 {
            hOverlap += 30
        }
        
        maxOverlap = max(vOverlap, hOverlap)
        print(vOverlap, hOverlap, maxOverlap)
        
        if state.size == 4 {
            if maxOverlap >= -20 {
                newRadius = radius - 5
                
                newImageSize = sin(theta) * newRadius * 2
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
            } else if maxOverlap < -25 {
                
                newRadius = radius + 5
                
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
                
                
            } else {
                return (newImageSize, newRadius)
            }
        } else {
            
            if maxOverlap >= -5 {
                newRadius = radius - 5
                
                newImageSize = sin(theta) * newRadius * 2
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
            } else if maxOverlap < -7.5 {
                
                newRadius = radius + 2.5
                
                return reduceOverlap(width: width, height: height, imageSize: newImageSize, radius: newRadius, theta: theta)
                
                
            } else {
                return (newImageSize, newRadius)
            }
        }
    }
}
