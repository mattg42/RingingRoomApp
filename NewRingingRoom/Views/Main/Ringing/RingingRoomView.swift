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
        
    @State private var showingTowerControls = false
    @State private var showingHelp = false
    @State private var showingConnectionErrorAlert = false
    
    var body: some View {
        ZStack {
            Color(.ringingRoomBackground)
                .ignoresSafeArea(.all)
            
            VStack {
                TowerNameView()
                
                ZStack {
                    HStack {
                        Button("Help") {
                            showingTowerControls = true
                        }
                        .buttonStyle(.ringingControlButton)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Button("Set at hand") {
                            showingTowerControls = true
                        }
                        .buttonStyle(.ringingControlButton)
                    }
                    
                    HStack {
                        Spacer ()
                        
                        Button("Controls") {
                            showingTowerControls = true
                        }
                        .buttonStyle(.ringingControlButton)
                    }
                    .sheet(isPresented: $showingHelp, content: {
                        HelpView(showDismiss: true)
                    })
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
