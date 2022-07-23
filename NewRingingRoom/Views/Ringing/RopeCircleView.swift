//
//  RopeCircleView.swift
//  NewRingingRoom
//
//  Created by Matthew on 14/07/2022.
//

import SwiftUI

struct RopeCircle:View {
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor:Color {
        get {
            if colorScheme == .light {
                return Color(red: 211/255, green: 209/255, blue: 220/255)
            } else {
                return Color(white: 0.085)
            }
        }
    }
    
    @EnvironmentObject var ringingRoomViewModel: RingingRoomViewModel
    
    @StateObject var viewModel = RopeCircleViewModel()
    
    var isSplit:Bool {
        get {
            !(horizontalSizeClass == .compact || (UIApplication.shared.orientation?.isPortrait ?? true))
        }
    }
    
    @AppStorage("autoRotate") var autoRotate: Bool = true
    
    @State var currentCall = ""
    @State var callTextOpacity = 0.0
    
    @State var perspective = 1
        
    var centre = CGPoint(x: 0, y: 0)
    
    @State var bellMode = BellMode.ring
    
    var imageWidth: CGFloat {
        if ringingRoomViewModel.bellType == .tower {
            return CGFloat(viewModel.imageSize)/3
        } else {
            return CGFloat(viewModel.imageSize) * 0.7
        }
    }
    
    var imageHeight: CGFloat {
        if ringingRoomViewModel.bellType == .tower {
            return CGFloat(viewModel.imageSize)
        } else {
            return CGFloat(viewModel.imageSize) * 0.6
        }
    }
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if viewModel.bellPositions.count == ringingRoomViewModel.size {
                    ForEach(0..<ringingRoomViewModel.size, id: \.self) { bellNumber in
                        Button(action: {
                            if bellMode == .ring {
                                ringingRoomViewModel.ringBell(number: bellNumber + 1)
                            } else {
                                perspective = bellNumber+1
                                bellMode = .ring
                            }
                        }) {
                            HStack(spacing: 0) {
                                Text(String(bellNumber+1))
                                    .opacity(isLeft(bellNumber) ? 0 : 1)
                                    .font(getFont())
                                Image(getImage(bellNumber))
                                    .antialiased(true)
                                    .resizable()
                                    .frame(width: imageWidth, height: imageHeight)
                                    .rotation3DEffect(
                                        .degrees((ringingRoomViewModel.bellType == .tower) ? 0 : isLeft(bellNumber) ? 180 : 0),
                                        axis: (x: 0.0, y: 1.0, z: 0.0),
                                        anchor: .center,
                                        perspective: 1.0
                                    )
                                    .padding(.horizontal, (ringingRoomViewModel.bellType == .tower) ? 0 : -5)
                                
                                Text(String(bellNumber+1))
                                    .opacity(isLeft(bellNumber) ? 1 : 0)
                                    .font(getFont())
                            }
                            
                        }
                        .disabled(bellMode == .ring ? !canRing(bellNumber) : false)
                        .opacity(bellMode == .ring ? canRing(bellNumber) ? 1 : 0.35 : 1)
                        .buttonStyle(TouchDown(isAvailable: true, callButton:false))
                        .foregroundColor(.primary)
                        .position(viewModel.bellPositions[bellNumber])
                    }
                }
                if bellMode == .ring {
                    GeometryReader { assignmentsGeo in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: -3) {
                                ForEach(0..<ringingRoomViewModel.assignments.count, id: \.self) { i in
                                    HStack {
                                        Text("\(i+1)")
                                            .font(.callout)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .frame(width: 20, alignment: .trailing)
                                        Text("\(ringingRoomViewModel.assignments[i]?.name ?? "")")
                                            .font(.callout)
                                            .lineLimit(1)
                                            .frame(width: viewModel.assignmentsWidth, alignment: .leading)

                                    }
                                    .foregroundColor(colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))
                                }.fixedSize(horizontal:true, vertical:false)

                            }.fixedSize(horizontal:true, vertical:false)

                        }
                        .offset(x: 0, y: ringingRoomViewModel.size == 5 ? -10 : 0)
                        .frame(maxHeight: viewModel.assignmentsHeight)
                        .fixedSize()

                        .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                    }
                } else {
                    Text("Tap the bell that you would like to be positioned bottom right, or tap the rotate button again to cancel.")
                        .multilineTextAlignment(.center)
                        .frame(width: 180)
                        .font(.body)
                        .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.9) : Color(white: 0.1))
                }
                
                ZStack {
                    backgroundColor
                        .cornerRadius(15)
                        .blur(radius: 15, opaque: false)
                        .shadow(color: backgroundColor, radius: 10, x: 0.0, y: 0.0)
                        .opacity(0.9)

                    Text(currentCall)
                        .font(.largeTitle)
                        .bold()
                        .padding()

                }
                .opacity(callTextOpacity)
                .fixedSize()
                .position(CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY))

                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Button(action: {
                            bellMode.toggle()
                            //put into change perspective mode
                        }) {
                            ZStack {
                                Color.main.cornerRadius(10)
                                Image("Arrow.4.circle.white").resizable()
                                    .frame(width: 37, height: 37)
                            }
                            .fixedSize()
                        }
                        .animation(nil)
                    }
                }
                .padding()
            }
            .onChange(of: geo.size) { newSize in
                viewModel.updateImage(screenSize: newSize, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY), size: ringingRoomViewModel.size, bellType: ringingRoomViewModel.bellType, perspective: perspective)
            }
            .onChange(of: ringingRoomViewModel.size) { newSize in
                viewModel.updateImage(screenSize: geo.size, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY), size: newSize, bellType: ringingRoomViewModel.bellType, perspective: perspective)
            }
            .onChange(of: ringingRoomViewModel.bellType) { newBellType in
                viewModel.updateImage(screenSize: geo.size, centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY), size: ringingRoomViewModel.size, bellType: newBellType, perspective: perspective)
            }
            .onChange(of: imageWidth) { _ in
                viewModel.getAssignmentsWidth(size: ringingRoomViewModel.size, perspective: perspective, bellType: ringingRoomViewModel.bellType, imageWidth: imageWidth)
            }
            .onChange(of: imageHeight) { _ in
                viewModel.getAssignmentsHeight(size: ringingRoomViewModel.size, perspective: perspective, bellType: ringingRoomViewModel.bellType, imageHeight: imageHeight)
            }
            .onChange(of: perspective) { newPerspective in
                viewModel.calculateBellPositions(centre: CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY), size: ringingRoomViewModel.size, bellType: ringingRoomViewModel.bellType, perspective: newPerspective)
            }
        }
        .onChange(of: ringingRoomViewModel.call) { call in
            if call.isEmpty {
                currentCall = call
                callTextOpacity  = 1
            } else {
                withAnimation {
                    callTextOpacity = 0
                }
            }
        }
        .onChange(of: ringingRoomViewModel.assignments) { assignments in
            if autoRotate {
                if let ringer  = ringingRoomViewModel.ringer {
                    perspective = (assignments.allIndicesOfRinger(ringer).first ?? 0) + 1
                }
            }
        }
    }
    
 
    
    func getFont() -> Font {
        if horizontalSizeClass == .compact &&  verticalSizeClass == .compact {
            if ringingRoomViewModel.size > 13 {
                return .footnote
            }
            
        }
        return .body
    }
    
    func isLeft(_ num:Int) -> Bool {
        if perspective <= Int(ringingRoomViewModel.size/2) {
            return (perspective..<perspective+Int(ringingRoomViewModel.size/2)).contains(num)
        } else {
            return !(perspective-Int(ringingRoomViewModel.size/2)..<perspective).contains(num)
        }
    }
    
    func canRing(_ number:Int) -> Bool {
        if ringingRoomViewModel.towerInfo.isHost {
            return true
        } else if ringingRoomViewModel.hostMode {
            if ringingRoomViewModel.assignments[number] == ringingRoomViewModel.ringer {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    func getImage(_ number:Int) -> String {
        var imageName = ringingRoomViewModel.bellType.rawValue.first!.lowercased() + "-" + (ringingRoomViewModel.bellStates[number].boolValue ? "handstroke" : "backstroke")
        if imageName.first! == "t" && number == 0 && ringingRoomViewModel.bellStates[number].boolValue {
            imageName += "-treble"
        }
        return imageName
    }
    
}
