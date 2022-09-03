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
    var body: some View {
        ZStack {
            Color("ringingBackground")
            
            HStack {
                TowerNameView()
                
                HStack {
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
                
                RopeCircleView()
                
                Spacer()
                
                RingingButtonsView()
            }
        }
        .sheet(isPresented: $showingTowerControls) {
            TowerControlsView()
        }
        .onAppear {
            viewModel.connect()
        }
    }
}
