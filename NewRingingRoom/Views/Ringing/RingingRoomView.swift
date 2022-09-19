//
//  RingingRoomView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/08/2022.
//

import SwiftUI
struct RingingRoomView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
        
    @State var showingTowerControls = false
    @State var showingHelp = false

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
                
                Spacer()
                
                if viewModel.ringer != nil {
                    RopeCircleView()
                    
                    Spacer()
                    
                    RingingButtonsView()
                }
            }
            .padding([.horizontal, .bottom], 5)
        }
        .fullScreenCover(isPresented: $showingTowerControls) {
            TowerControlsView()
        }
//        .sheet(isPresented: $showingHelp, content: {
//            HelpView(showDismiss: true)
//        })
        .onAppear {
            viewModel.connect()
        }
    }
}
