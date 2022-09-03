////
////  RingingView.swift
////  NewRingingRoom
////
////  Created by Matthew on 14/07/2022.
////
//
//import Foundation
//import SwiftUI
//import AVFoundation
//import Combine
//import Network
//
//enum ActiveSheet: Identifiable {
//    case privacy, help
//    
//    var id: Int {
//        hashValue
//    }
//}
//
//private struct IsLargeSizeKey: EnvironmentKey {
//    static let defaultValue: Bool = false
//}
//
//extension EnvironmentValues {
//    var isLargeSize: Bool {
//        get { self[IsLargeSizeKey.self] }
//        set { self[IsLargeSizeKey.self] = newValue }
//    }
//}
//
//struct RingingRoomView: View {
//    
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//    
//    @Environment(\.sizeCategory) var sizeCategory
//    @Environment(\.scenePhase) var scenePhase
//    
//    var backgroundColor:Color {
//        get {
//            if colorScheme == .light {
//                return Color(red: 211/255, green: 209/255, blue: 220/255)
//            } else {
//                return Color(white: 0)
//            }
//        }
//    }
//    
//    @State var titleHeight:CGFloat = 0
//    
//    @State var changedSizeCategory = false
//            
//    var isSplit:Bool {
//        get {
//            !(horizontalSizeClass == .compact || (UIApplication.shared.orientation?.isPortrait ?? true))
//        }
//    }
//    
//    @State var isLargeSize = false
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    
//    @State var showingControls = false
//    
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                backgroundColor.edgesIgnoringSafeArea(.all)
//                VStack {
//                    TowerNameView(name: viewModel.towerInfo.towerName)
//                    HStack {
//                        Spacer()
//                        Button {
//                            showingControls = true
//                        } label: {
//                            
//                            ZStack {
//                                Color.main
//                                    .cornerRadius(5)
//                                Text("Controls")
//                                    .bold()
//                                    .padding(.horizontal, 3.5)
//                                    .foregroundColor(.white)
//                                    .padding(2)
//                                    .minimumScaleFactor(0.7)
//                            }
//                            .fixedSize()
//                            
//                        }
//                    }
//                    RingingView()
//                    Spacer()
//                }
//                .padding(7)
////                ZStack {
////                    if isSplit {
////                        HStack(spacing: 5) {
////                            TowerControlsView(width: geo.size.width * 0.2)
////                                .frame(width: 350)
////                            VStack(spacing: 0) {
////                                TowerNameView(name: viewModel.towerInfo.towerName)
////                                    .padding(.bottom, 5)
////                                HStack {
////                                    Spacer()
////                                    Button("Controls") {
////                                        showingControls = true
////                                    }
////                                }
////                            }
////                        }
////                    }
////                }
////                Image(systemName: "bubble.left.fill")
////                    .accentColor(Color.main)
////                    .font(.title)
////                Text(String(viewModel.newMessages))
////
////                    .foregroundColor(.white)
////                    .bold()
////                    .offset(x: 0, y: -2)
//            }
//            .padding(-2)
//        }
//        .onAppear {
//            viewModel.connect()
//        }
//        .sheet(isPresented: $showingControls) {
//            TowerControlsView(width: 0)
//                .padding()
//        }
//    }
//}
//
//struct SetAtHandButton:View {
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//        
//    var body: some View {
//        Button(action: {
//            viewModel.send(event: "c_set_bells", with: ["tower_id": viewModel.towerInfo.towerID])
//        }) {
//            ZStack {
//                Color.main
//                    .cornerRadius(5)
//                Text("Set at hand")
//                    .bold()
//                    .padding(.horizontal, 3.5)
//                    .foregroundColor(.white)
//                    .padding(2)
//                    .minimumScaleFactor(0.7)
//            }
//            .fixedSize()
//        }
//    }
//}
//
//struct TowerNameView:View {
//    
//    let name: String
//    
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .fill(Color.main)
//                .cornerRadius(5)
//            Text(name)
//                .foregroundColor(.white)
//                .font(Font.custom("Simonetta-Black", size: 30))
//                .lineLimit(1)
//                .minimumScaleFactor(0.5)
//                .scaleEffect(0.9)
//                .padding(.vertical, 4)
//        }
//        .fixedSize(horizontal: false, vertical: true)
//    }
//}
//
//enum MenuButtonMode {
//    case ring, controls
//}
//
//struct MenuButton:View {
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    
//    var keepSize:Bool
//    
//    var mode: MenuButtonMode = .controls
//    
//    var body: some View {
//        Button(action: {
//            withAnimation {
//                viewModel.showingTowerControls.toggle()
//                
//                if !viewModel.showingTowerControls {
//                    hideKeyboard()
//                }
//            }
//        }) {
//            ZStack {
//                Color.main.cornerRadius(5)
//                
//                if keepSize {
//                    if mode == .ring {
//                        ToRing()
//                    } else {
//                        ToControls()
//                    }
//                } else {
//                    if viewModel.showingTowerControls {
//                        ToRing()
//                    } else {
//                        ToControls()
//                    }
//                }
//            }
//            .clipped()
//            .fixedSize()
//        }
//    }
//}
//
//struct ToControls:View {
//    var body: some View {
//        HStack {
//            Text("Controls")
//                .bold()
//                .minimumScaleFactor(0.7)
//            
//            Image(systemName: "chevron.right")
//        }
//        .padding(2)
//        .padding(.horizontal, 3.5)
//        .foregroundColor(Color.white)
//    }
//}
//
//struct ToRing:View {
//    var body: some View {
//        HStack {
//            Image(systemName: "chevron.left")
//            Text("Ring")
//            
//                .bold()
//                .minimumScaleFactor(0.7)
//            
//        }
//        .padding(2)
//        .padding(.horizontal, 3.5)
//        .foregroundColor(Color.white)
//    }
//}
//
//struct HelpButton:View {
//    @State var showingHelp = false
//    
//    var body: some View {
//        Button(action: {
//            showingHelp = true
//        }) {
//            ZStack {
//                Color.main.cornerRadius(5)
//                Text("Help")
//                    .bold()
//                    .padding(2)
//                    .padding(.horizontal, 3.5)
//                    .foregroundColor(Color.white)
//                    .minimumScaleFactor(0.7)
//                
//            }
//            .fixedSize()
//        }
//        .sheet(isPresented: $showingHelp) {
//            HelpView(asSheet: true)
//                .accentColor(.main)
//        }
//    }
//}
//
//struct LeaveButton:View {
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    @EnvironmentObject var appRouter: AppRouter
//    
//    var body: some View {
//        Button(action: leaveTower) {
//            ZStack {
//                Color.main.cornerRadius(5)
//                Text("Leave")
//                    .bold()
//                    .padding(2)
//                    .padding(.horizontal, 3.5)
//                    .foregroundColor(Color.white)
//                    .minimumScaleFactor(0.7)
//                
//            }
//            .fixedSize()
//        }
//    }
//    
//    func leaveTower() {
//        viewModel.send(event: "c_user_left", with: ["user_name": viewModel.user.username, "user_token": viewModel.apiService.token, "anonymous_user": false, "tower_id": viewModel.towerInfo.towerID])
//        
//        viewModel.disconnect()
//        appRouter.moveTo(.main(user: viewModel.user, apiService: viewModel.apiService))
//    }
//}
//
//enum BellMode {
//    case ring, rotate
//    
//    mutating func toggle() {
//        if self == .ring {
//            self = .rotate
//        } else {
//            self = .ring
//        }
//    }
//}
//
//extension CGPoint {
//    func truncate(places : Int) -> CGPoint {
//        return CGPoint(x: self.x.truncate(places: places), y: self.y.truncate(places: places))
//    }
//}
//
//extension CGFloat {
//    func truncate(places : Int) -> CGFloat {
//        return CGFloat(floor(pow(10.0, CGFloat(places)) * self)/pow(10.0, CGFloat(places)))
//    }
//}
//
//extension CGSize {
//    func truncate(places : Int) -> CGSize {
//        return CGSize(width: self.width.truncate(places: places), height: self.height.truncate(places: places))
//    }
//}
