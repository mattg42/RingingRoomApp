//
//  RingingRoomView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

enum RingingMenuView: Identifiable {
    
    var id: Self { self }
    
    case users, chat, settings, wheatley
    
    var title: String {
        switch self {
        case .users:
            return "Users"
        case .chat:
            return "Chat"
        case .settings:
            return "Settings"
        case .wheatley:
            return "Wheatley"
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
        case .wheatley:
            fatalError("not implemented yet")
        }
    }
}

struct HelpButton: View {
    @State private var showingHelp = false

    var body: some View {
        Button("Help") {
            showingHelp = true
        }
        .ringingControlButtonStyle()
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
        Button("Set at hand") {
            viewModel.send(.setBells)
        }
        .ringingControlButtonStyle()
    }
}

import SwiftUI
struct RingingRoomView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
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
            
            VStack {
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
                        
                        Menu {
                            Button("Users") {
                                menuView = .users
                            }

                            
                            Button("Settings") {
                                menuView = .settings
                            }
                            
                            Button("Chat") {
                                menuView = .chat
                            }
                            
                            Button("Leave tower") {
                                viewModel.send(.leaveTower)
                                
                                router.moveTo(.home)
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
                        .fullScreenCover(item: $menuView) { item in
                            NavigationView {
                                item.view
                                    .navigationTitle(item.title)
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        Button("Back") {
                                            menuView = nil
                                        }
                                    }
                            }
                        }
                    }

                }
                
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
