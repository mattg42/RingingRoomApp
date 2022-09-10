//
//  AssignmentsListView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/09/2022.
//

import SwiftUI

struct AssignmentsListView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    let bellPositions: [CGPoint]
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let geo: GeometryProxy
    
    var body: some View {
        if viewModel.bellMode == .ring {
            GeometryReader { assignmentsGeo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: -3) {
                        ForEach(viewModel.assignments.indices, id: \.self) { index in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.callout)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(" \(viewModel.assignments[index] != nil ? viewModel.users[viewModel.assignments[index]!]?.name ?? "" : "")")
                                    .font(.callout)
                                    .lineLimit(1)
                                    .frame(width: getWidth(), alignment: .leading)
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    
                }
                .offset(x: 0, y: viewModel.size == 5 ? -10 : 0)
                .frame(maxHeight: getHeight())
                .fixedSize()
                .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
            }
        } else {
            Text("Tap the bell that you would like to be positioned bottom right, or tap the rotate button again to cancel.")
                .multilineTextAlignment(.center)
                .frame(width: 180)
                .font(.body)
                .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
        }
    }
        
    func getHeight() -> CGFloat {
        
        guard bellPositions.count == viewModel.size else { return 0 }
        
        var returnValue :CGFloat = 0
        if viewModel.size == 5 {
            var top = viewModel.perspective
            top += 3
            if top > 5 {
                top -= 5
            }
            returnValue = bellPositions[viewModel.perspective - 1].y - bellPositions[top - 1].y
        } else if viewModel.perspective <= Int(viewModel.size/2) {
            returnValue = bellPositions[viewModel.perspective - 1].y - bellPositions[viewModel.perspective - 1 + Int(ceil(Double(viewModel.size / 2)))].y
        } else {
            returnValue = bellPositions[viewModel.perspective - 1].y - bellPositions[viewModel.perspective - 1 - Int(ceil(Double(viewModel.size / 2)))].y
        }
        returnValue -= 10
        
        if viewModel.size != 4 {
            returnValue -= imageHeight
        }
        
        return returnValue
    }
    
    func getWidth() -> CGFloat {
        
        guard bellPositions.count == viewModel.size else { return 0 }
        
        var returnValue: CGFloat = 0
        
        var leftBellNumber = viewModel.perspective + 2
        if leftBellNumber > viewModel.size {
            leftBellNumber -= viewModel.size
        }
        var rightBellNumber = viewModel.perspective - 1
        if rightBellNumber <= 0 {
            rightBellNumber += viewModel.size
        }
        let left = bellPositions[leftBellNumber-1].x
        let right = bellPositions[rightBellNumber-1].x
        
        returnValue = right - left
        if viewModel.size == 4 && viewModel.bellType == .hand {
            return returnValue
        }
        returnValue -= imageWidth
        if viewModel.size == 4 {
            return returnValue
        }
        if viewModel.size != 4 {
            returnValue -= 20
        }
        if ![4, 14, 16].contains(viewModel.size) {
            returnValue -= 30
        }
        returnValue = min(returnValue, 160)
        return returnValue
    }

}
