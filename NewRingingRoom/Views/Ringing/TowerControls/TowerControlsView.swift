//
//  TowerControlsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 14/07/2022.
//

import SwiftUI

struct TowerControlsView:View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.sizeCategory) var sizeCategory
    
    @Environment(\.scenePhase) var scenePhase

    var isSplit:Bool {
        get {
            !(horizontalSizeClass == .compact || (UIApplication.shared.orientation?.isPortrait ?? true))
        }
    }
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    @State private var permitHostMode:Bool = false
    
    @State private var updateView = false
    
    @State private var bellTypeSelection = 0
    
    @State private var selectedUser = 0
    
    @State private var newAssignment = false
    
    @State private var towerSelectionCount = 0
    @State private var bellTypeSelectionCount = 0
        
    @State private var showingUsers = false
    
    init(width:CGFloat) {
        print("new towerControls")
        self.width = width
    }
    
    @State var width:CGFloat = 0
        
    @State var hostModeTimer:Timer? = nil
    
    @State var changeHostMode = true
    
    @State var showingAudioSlider = false
    
    //    @State var width = 0
    
    @State var speakerSliders = ".3"
    
    @AppStorage("volume") var volume = 1.0
    
    var backgroundColor: some View {
        get {
            if isSplit {
                return AnyView(EmptyView())
            } else {
                return AnyView(Color.primary.colorInvert())
            }
        }
    }
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        
                        HStack(alignment: .top) {
                            if !isSplit {
                                HelpButton()
                                    .opacity(viewModel.isLargeSize ? 1 : 0)
                                    .disabled(!viewModel.isLargeSize)
                            }
                            Button(action: {
                                withAnimation {
                                    showingAudioSlider.toggle()
                                }
                            }) {
                                ZStack(alignment: .leading) {
                                    ZStack {
                                        Color.main.cornerRadius(5)
                                        Image(systemName: "speaker.3").padding(3).font(Font.callout.weight(.bold))
                                            .hidden()
                                    }.fixedSize()
                                    Image(systemName: "speaker\(speakerSliders)")
                                        .font(Font.callout.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(3)
                                }.fixedSize()
                                    .onAppear {
                                        getNumberOfLines()
                                    }
                            }
                            Spacer()
                            ZStack(alignment: .top) {
                                HStack {
                                    Spacer()
                                    Text(String(viewModel.towerInfo.towerID)).lineLimit(1).minimumScaleFactor(0.5)
                                    Button(action: {
                                        let pasteboard = UIPasteboard.general
                                        pasteboard.string = String(viewModel.towerInfo.towerID)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .foregroundColor(.primary)
                                    Spacer()
                                }
                                HStack(spacing: 0) {
                                    Slider(value: $volume, in: 0.0...1.0)
                                        .frame(maxWidth: showingAudioSlider ? .infinity : 0)
                                        .opacity(showingAudioSlider ? 1 : 0)
                                        .background(backgroundColor)
                                        .padding(.top, -3.5)
                                    Spacer()
                                }
                            }
                            Spacer()
                            if !isSplit {
                                MenuButton(keepSize: true, mode: .ring).opacity(0).disabled(true)
                            }
                            
                        }
                        //                    .background(Color.blue)
                        //                    .padding(.top, -3.5)
                        .padding(.bottom, 3)
                    } else {
                        HStack(alignment: .center) {
                            if !isSplit {
                                HelpButton()
                                    .opacity(0)
                                    .disabled(true)
                                Spacer()
                                
                            }
                            
                            ZStack(alignment: .leading) {
                                ZStack {
                                    Image(systemName: "speaker.3").padding(3).font(Font.callout.weight(.bold))
                                        .hidden()
                                }.fixedSize()
                                Image(systemName: "speaker\(speakerSliders)")
                                    .font(Font.callout.weight(.bold))
                                    .foregroundColor(.primary)
                                //                                            .padding(3)
                            }.fixedSize()
                                .onAppear {
                                    getNumberOfLines()
                                }
                                .padding(.trailing, -3)
                            Slider(value: $volume, in: 0.0...1.0)
                                .frame(maxWidth: 250)
                            //                                .opacity(showingAudioSlider ? 1 : 0)
                                .background(backgroundColor)
                            Spacer()
                            Text(String(viewModel.towerInfo.towerID)).lineLimit(1).minimumScaleFactor(0.5)
                            Button(action: {
                                let pasteboard = UIPasteboard.general
                                pasteboard.string = String(viewModel.towerInfo.towerID)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .foregroundColor(.primary)
                            if !isSplit {
                                Spacer()
                                MenuButton(keepSize: true, mode: .ring).opacity(0).disabled(true)
                            }
                            
                        }
                        .padding(.top, -3.5)
                        .padding(.bottom, 3)
                    }
                    
                    if hasPermissions() {
                        HStack {
                            if viewModel.towerInfo.hostModePermitted && viewModel.towerInfo.isHost {
                                HStack {
                                    Toggle("Host Mode", isOn: .init(get: { viewModel.hostMode }, set: {
                                        if !(hostModeTimer?.isValid ?? false) {
                                            viewModel.hostMode = $0
                                            viewModel.send(event: "c_host_mode", with: ["new_mode": viewModel.hostMode, "tower_id": viewModel.towerInfo.towerID])
                                        }
                                    }))
                                    .toggleStyle(SwitchToggleStyle(tint: .main))
                                    .fixedSize()
                                    Spacer()
                                }
                            }
                            Picker(selection: .init(get: {
                                viewModel.bellType
                            }, set: {
                                bellTypeChanged(to: $0)
                            }), label: Text("Bell type picker")) {
                                ForEach(BellType.allCases) { bellType in
                                    Text(bellType.rawValue)
                                        .id(bellType)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.bottom, 7)
                        
                        HStack {
                            Picker(selection: .init(get: {
                                viewModel.size
                            }, set: {
                                sizeChanged(to: $0)
                            }), label: Text("Tower size picker")) {
                                ForEach(viewModel.towerInfo.towerSizes, id: \.self) { size in
                                    Text(String(size))
                                        .id(size)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                        }
                        .padding(.bottom, 7)
                    }
                    if viewModel.towerControlsViewSelection == .users {
                        UsersView()
                    } else {
                        ChatView()
                    }
                }
                
            }
            .onChange(of: viewModel.showingTowerControls, perform: { _ in
                print(viewModel.users)
            })
            .onChange(of: volume) { _ in
                print("volume changed")
                let mappedVolume = pow(Float(volume), 3)
                viewModel.changeVolume(to: mappedVolume)
                getNumberOfLines()
            }

        }
        //        .background(Color.red)
    }
    
    func getNumberOfLines() {
        switch volume {
        case 0:
            speakerSliders = ""
        case 0..<1/3:
            speakerSliders = ".1"
        case 1/3..<2/3:
            speakerSliders = ".2"
        case 2/3...1:
            speakerSliders = ".3"
        default:
            speakerSliders = ".2"
        }
    }
    
    func hasPermissions() -> Bool {
        if viewModel.towerInfo.isHost {
            return true
        } else if viewModel.hostMode {
            return false
        } else {
            return true
        }
    }
    
    func update() {
        self.updateView.toggle()
        print("updated tower controls")
    }
    
    func bellTypeChanged(to bellType: BellType) {
        print("changing belltype")
        viewModel.send(event: "c_audio_change", with: ["new_audio": bellType.rawValue, "tower_id": viewModel.towerInfo.towerID])
    }
    
    func sizeChanged(to size: Int) {
        viewModel.send(event: "c_size_change", with: ["new_size": size, "tower_id": viewModel.towerInfo.towerID])
    }
    
}
