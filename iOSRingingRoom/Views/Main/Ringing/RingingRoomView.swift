//
//  RingingRoomView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

enum RingingMenuView: Identifiable, CaseIterable {
    
    var id: Self { self }
    
    case users, controls, chat
    //    ,wheatley
    
    var title: String {
        switch self {
        case .users:
            return "Users"
        case .chat:
            return "Chat"
        case .controls:
            return "Controls"
            //        case .wheatley:
            //            return "Wheatley"
        }
    }
    
    @ViewBuilder var view: some View {
        switch self {
        case .users:
            UsersView()
        case .chat:
            ChatView()
        case .controls:
            ControlsView()
            //        case .wheatley:
            //            Text("W")
        }
    }
    
    var image: String {
        switch self {
        case .users:
            "person.3.fill"
        case .controls:
            "gear"
        case .chat:
            "text.bubble.fill"
            //        case .wheatley:
            //            "bell.fill"
        }
    }
    
}

struct HelpButton: View {
    @State private var showingHelp = false
    
    var body: some View {
        Button {
            showingHelp = true
        } label: {
            ZStack {
                Color.main
                    .cornerRadius(5)
                
                Text("Help")
                    .font(.body.bold())
                    .padding(.horizontal, 3.5)
                    .foregroundColor(.white)
                    .padding(2)
                    .minimumScaleFactor(0.7)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .sheet(isPresented: $showingHelp, content: {
            HelpView(showDismiss: true)
        })
    }
}

struct SetAtHandButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    var body: some View {
        Button {
            viewModel.send(.setBells)
        } label: {
            ZStack {
                Color.main
                    .cornerRadius(5)
                
                Text("Set at hand")
                    .font(.body.bold())
                    .padding(.horizontal, 3.5)
                    .foregroundColor(.white)
                    .padding(2)
                    .minimumScaleFactor(0.7)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}


struct RingingRoomMenuView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var state: RingingRoomState
    
    @State var menuView: RingingMenuView
    
    var showDone: Bool
    
    var body: some View {
        
        TabView(selection: $menuView) {
            
            ForEach(RingingMenuView.allCases) { menu in
                NavigationView {
                    menu.view
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            if showDone {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                        }
                        .navigationTitle(menu.title)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tag(menu)
                .tabItem {
                    Label {
                        Text(menu.title)
                    } icon: {
                        Image(systemName: menu.image)
                    }
                }
                .badge(menu == .chat ? state.newMessages : 0)
            }
        }
    }
}

import SwiftUI
struct RingingRoomView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @Binding var user: User
    
    let apiService: APIService
    
    var body: some View {
        ZStack {
            Color(.ringingRoomBackground)
                .ignoresSafeArea(.all)
            
            GeometryReader { geo in
                if sizeClass == .regular && geo.frame(in: .global).width > geo.frame(in: .global).height {
                    HStack {
                        RingingRoomMenuView(menuView: .users, showDone: false)
                            .frame(width: 350)
                        RingingView(wide: true)
                    }
                } else {
                    RingingView(wide: false)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        
        .onAppear {
            viewModel.connect()
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                print("cocnnecting again")
                viewModel.connect()
            } else {
                viewModel.disconnect()
            }
        }
        .onChange(of: viewModel.connected ) { _ in
            Task(priority: .medium) {
                await ErrorUtil.do(networkRequest: true) {
                    user.towers = try await apiService.getTowers()
                }
            }
        }
    }
}

struct RingingView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    @EnvironmentObject var monitor: NetworkMonitor
    @EnvironmentObject var router: Router<MainRoute>
    
    @State private var showingConnectionErrorAlert = false
    
    var wide: Bool
    
    @State var menuView: RingingMenuView? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 5) {
                TowerNameView()
                
                ZStack {
                    HStack {
                        HelpButton()
                        
                        Spacer()
                    }
                    
                    SetAtHandButton()
                        .disabled(state.hostMode && !viewModel.towerInfo.isHost)
                    
                    HStack {
                        Spacer ()
                        
                        if wide {
                            Button(role: .destructive) {
                                viewModel.send(.leaveTower)
                                
                                router.moveTo(.home)
                            } label: {
                                ZStack {
                                    Color.main
                                        .cornerRadius(5)
                                    
                                    Text("Leave tower")
                                        .font(.body.bold())
                                        .padding(.horizontal, 3.5)
                                        .foregroundColor(.white)
                                        .padding(2)
                                        .minimumScaleFactor(0.7)
                                }
                                .fixedSize(horizontal: true, vertical: false)
                            }
                        } else {
                            if state.bellMode == .ring {
                                Menu {
                                    Section {
                                        ForEach(RingingMenuView.allCases) { menuViewType in
                                            Button(menuViewType.title) {
                                                menuView = menuViewType
                                            }
                                        }
                                    }
                                    Section {
                                        Button("Leave tower", role: .destructive) {
                                            viewModel.send(.leaveTower)
                                            
                                            router.moveTo(.home)
                                        }
                                    }
                                } label: {
                                    ZStack {
                                        Color.main
                                            .cornerRadius(5)
                                        
                                        Image(systemName: "line.3.horizontal")
                                            .font(.title)
                                            .padding(3.5)
                                            .foregroundColor(.white)
                                            .padding(2)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .fixedSize()
                                }
                                .fullScreenCover(item: $menuView) { thing in
                                    RingingRoomMenuView(menuView: thing, showDone: true)
                                }
                                
                            } else {
                                Button {
                                    state.bellMode = .ring
                                } label: {
                                    ZStack {
                                        Color.main
                                            .cornerRadius(5)
                                        
                                        Image(systemName: "line.3.horizontal")
                                            .font(.title)
                                            .padding(3.5)
                                            .padding(2)
                                            .minimumScaleFactor(0.7)
                                            .opacity(0)
                                        Text("Cancel")
                                            .font(.body.bold())
                                            .padding(.horizontal, 3.5)
                                            .foregroundColor(.white)
                                            .padding(2)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .fixedSize()
                                }
                            }
                            
                        }
                    }
                    
                }
                .fixedSize(horizontal: false, vertical: true)
                
                ZStack {
                    RopeCircleView()
                    if !wide {
                        HStack {
                            Spacer()
                            VStack {
                                if state.newMessages > 0 {
                                    Button {
                                        menuView = .chat
                                    } label: {
                                        ZStack {
                                            Image(systemName: "bubble.left.fill")
                                                .accentColor(Color.main)
                                                .font(.title)
                                            
                                            Text(String(state.newMessages))
                                                .foregroundColor(.white)
                                                .bold()
                                                .offset(x: 0, y: -2)
                                        }
                                    }
                                    .padding(.top, -2)
                                    .padding(.trailing, -3)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                RingingButtonsView()
            }
            .padding([.horizontal, .bottom], 5)
            
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.3)
                
                ZStack {
                    Rectangle()
                        .fill(Color(.ringingButtonBackground))
                        .cornerRadius(10)
                    
                    VStack(spacing: 14.0) {
                        Text("""
Your device is not connected
to the internet.
""").bold()
                        Text("""
This alert will disappear
when the internet
connection is restored.
""")
                    }
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding()
                }
                .fixedSize()
            }
            .opacity(showingConnectionErrorAlert ? 1 : 0)
        }
        .onChange(of: monitor.status, perform: { newValue in
            showingConnectionErrorAlert = newValue != .satisfied
        })
    }
}
