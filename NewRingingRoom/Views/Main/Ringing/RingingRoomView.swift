//
//  RingingRoomView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

import SwiftUI
struct RingingRoomView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var monitor: NetworkMonitor
    
    @Environment(\.scenePhase) var scenePhase
    
//    @Binding var user: User
//    let apiService: APIService
        
    @State var showingTowerControls = false
    @State var showingHelp = false
    @State var showingConnectionErrorAlert = false
    
    var body: some View {
        ZStack {
            Color("ringingBackground")
                .ignoresSafeArea(.all)
            
            VStack {
                TowerNameView()
                
                HStack {
                    Button {
                        showingHelp = true
                    } label: {
                        ZStack {
                            Color.main
                                .cornerRadius(5)
                            
                            Text("Help")
                                .foregroundColor(.white)
                                .bold()
                                .padding(3)
                        }
                        .fixedSize()
                    }

                    
                    Spacer()
                    
                    Button {
                        showingTowerControls = true
                    } label: {
                        ZStack {
                            Color.main
                                .cornerRadius(5)
                            
                            Text("Controls")
                                .foregroundColor(.white)
                                .bold()
                                .padding(3)
                        }
                        .fixedSize()
                    }

                }
                .sheet(isPresented: $showingHelp, content: {
                    HelpView(showDismiss: true)
                })
                
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
                        .fill(Color("ringingButtonBackground"))
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
        .fullScreenCover(isPresented: $showingTowerControls) {
            //                        Button("BAck") { showingTowerControls = false }
            TowerControlsView()
        }
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
    }
}
