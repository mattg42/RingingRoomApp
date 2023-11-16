//
//  RingingRoomView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

enum RingingMenuView: Identifiable, CaseIterable {
    
    var id: Self { self }
    
    case users, settings, chat
//    ,wheatley
    
    var title: String {
        switch self {
        case .users:
            return "Users"
        case .chat:
            return "Chat"
        case .settings:
            return "Settings"
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
        case .settings:
            SettingsView()
//        case .wheatley:
//            Text("W")
        }
    }
    
    var image: String {
        switch self {
        case .users:
            "person.3.fill"
        case .settings:
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

struct TowerControlsButton: View {
    @State private var showingTowerControls = false

    var body: some View {
        Button("Controls") {
            showingTowerControls = true
        }
        .ringingControlButtonStyle()
        .fullScreenCover(isPresented: $showingTowerControls) {
            TowerControlsView()
        }
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
    
    @State var menuView: RingingMenuView
    
    var body: some View {
        
        TabView(selection: $menuView) {
            
            ForEach(RingingMenuView.allCases) { menu in
                NavigationView {
                    menu.view
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            Button("Done") {
                                dismiss()
                            }
                        }
                        .navigationTitle(menu.title)
                    
                    
                    
                }
                .tag(menu)
                .tabItem {
                    Label {
                        Text(menu.title)
                    } icon: {
                        Image(systemName: menu.image)
                    }

                }
                
            }
            
            
            
        }
        
        //        .ignoresSafeArea()
        
    }
}

import SwiftUI
struct RingingRoomView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    @EnvironmentObject var monitor: NetworkMonitor
    @EnvironmentObject var router: Router<MainRoute>

    @Environment(\.scenePhase) var scenePhase
        
    @Binding var user: User
    let apiService: APIService
    
    @State private var showingConnectionErrorAlert = false
    
    @State private var menuView: RingingMenuView? = nil
    
    var body: some View {
        ZStack {
            Color(.ringingRoomBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                TowerNameView()
                
                ZStack {
                    HStack {
                        HelpButton()

                        Spacer()
                    }
                    
                    SetAtHandButton()
                    
                    HStack {
                        Spacer ()
                        
//                        TowerControlsButton()
                        
                        if state.bellMode == .ring {
                            Menu {
                                Section {
                                    Button("Users") {
                                        menuView = .users
                                    }
                                    
                                    Button("Settings") {
                                        menuView = .settings
                                    }
                                    
                                    Button("Chat") {
                                        menuView = .chat
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
                                RingingRoomMenuView(menuView: thing)
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
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)

                
                Spacer()
                
                RopeCircleView()
                    
                Spacer()
                    
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
        .ignoresSafeArea(.keyboard)

        .onAppear {
            viewModel.connect()
        }
        .onChange(of: monitor.status, perform: { newValue in
            showingConnectionErrorAlert = newValue != .satisfied
        })
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
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
