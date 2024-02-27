//
//  AssignmentsListView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/09/2022.
//

import SwiftUI

struct AssignmentsListView: View {
    
    @EnvironmentObject var state: RingingRoomState
    
    let bellPositions: [CGPoint]
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let geo: GeometryProxy
    
    @State private var assignmentsWidth: CGFloat = .zero
    @State private var assignmentsHeight: CGFloat = .zero
    
    var body: some View {
         Group {
            if state.bellMode == .ring {
                GeometryReader { assignmentsGeo in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: -3) {
                            ForEach(state.assignments.indices, id: \.self) { index in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.callout)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .frame(width: 20, alignment: .trailing)
                                    
                                    Text(" " + (state.assignments[index] != nil ? state.users.first(where: {$0.ringerID == state.assignments[index]!})?.name ?? "" : ""))
                                        .font(.callout)
                                        .lineLimit(1)
                                        .frame(width: assignmentsWidth, alignment: .leading)
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        
                    }
                    .offset(x: 0, y: state.size == 5 ? -10 : 0)
                    .frame(maxHeight: assignmentsHeight)
                    .fixedSize()
                    .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                }
            } else {
                Text("Tap the bell that you would like to be positioned bottom right.")
                    .multilineTextAlignment(.center)
                    .frame(width: 180)
                    .font(.body)
                    .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
            }
        }
         .onChange(of: bellPositions) { newValue in
             getHeight(bellPositions: newValue)
             getWidth(bellPositions: newValue)
         }
    }
        
    func getHeight(bellPositions: [CGPoint]) {
        
        guard bellPositions.count == state.size else { return }
        
        var height: CGFloat = 0
        if state.size == 5 {
            var top = state.perspective
            top += 3
            if top > 5 {
                top -= 5
            }
            height = bellPositions[state.perspective - 1].y - bellPositions[top - 1].y
        } else if state.perspective <= Int(state.size/2) {
            height = bellPositions[state.perspective - 1].y - bellPositions[state.perspective - 1 + Int(ceil(Double(state.size / 2)))].y
        } else {
            height = bellPositions[state.perspective - 1].y - bellPositions[state.perspective - 1 - Int(ceil(Double(state.size / 2)))].y
        }
        height -= 10
        
        if state.size != 4 {
            height -= imageHeight
        }
        assignmentsHeight = height
    }
    
    func getWidth(bellPositions: [CGPoint]) {
        
        guard bellPositions.count == state.size else { return }
        
        var width: CGFloat = 0
        
        var leftBellNumber = state.perspective + 2
        if leftBellNumber > state.size {
            leftBellNumber -= state.size
        }
        var rightBellNumber = state.perspective - 1
        if rightBellNumber <= 0 {
            rightBellNumber += state.size
        }
        let left = bellPositions[leftBellNumber-1].x
        let right = bellPositions[rightBellNumber-1].x
        
        width = right - left
        if state.size == 4 && state.bellType == .hand {
            assignmentsWidth = width
            return
        }
        width -= imageWidth
        if state.size == 4 {
            assignmentsWidth = width
            return
        }
        if state.size != 4 {
            width -= 20
        }
        if ![4, 14, 16].contains(state.size) {
            width -= 30
        }
        width = min(width, 160)
        assignmentsWidth = width
    }

}
