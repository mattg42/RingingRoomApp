//
//  SettingsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 10/09/2022.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var router: AppRouter
    
    @Environment(\.dismiss) var dismiss
    
    @State var volume = UserDefaults.standard.optionalDouble(forKey: "volume") ?? 1
    
    @State var size = 0
    @State var bellType = BellType.tower
    @State var hostMode = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Tower ID: \(String(viewModel.towerInfo.towerID))")
                    Spacer()
                    Button("Copy") {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = String(viewModel.towerInfo.towerID)
                    }
                }
            }
            Section {
                Slider(value: $volume, in: 0.0...1.0, minimumValueLabel: Image(systemName: "speaker.fill"), maximumValueLabel: Image(systemName: "speaker.3.fill"), label: { Text("Volume slider") })
                    .onChange(of: volume) { newValue in
                        viewModel.changeVolume(to: newValue)
                    }
            }
            
            Section {
                Toggle("Host mode", isOn: $hostMode)
                    .onAppear {
                        hostMode = viewModel.hostMode
                    }
                    .onChange(of: viewModel.hostMode) { newValue in
                        if hostMode != newValue {
                            hostMode = newValue
                        }
                    }
                    .onChange(of: hostMode) { newValue in
                        if viewModel.hostMode != newValue {
                            viewModel.send(.hostModeSet(to: newValue))
                        }
                    }
                
                Picker("Number of bells", selection: $size) {
                    ForEach(viewModel.towerInfo.towerSizes, id: \.self) { size in
                        Text("\(size)")
                            .tag(size)
                    }
                }
                .onAppear {
                    size = viewModel.size
                }
                .onChange(of: viewModel.size) { newValue in
                    if size != newValue {
                        size = newValue
                    }
                }
                .onChange(of: size) { newValue in
                    if viewModel.size != newValue {
                        viewModel.send(.sizeChange(to: newValue))
                    }
                }
                
                
                Picker("Bell type", selection: $bellType) {
                    ForEach(BellType.allCases) { bell in
                        Text(bell.rawValue)
                            .tag(bell)
                    }
                }
                .onAppear {
                    bellType = viewModel.bellType
                }
                .onChange(of: viewModel.bellType) { newValue in
                    if bellType != newValue {
                        bellType = newValue
                    }
                }
                .onChange(of: bellType) { newValue in
                    if viewModel.bellType != newValue {
                        viewModel.send(.audioChange(to: newValue))
                    }
                }
            }
            
            Section {
                Button("Set at hand") {
                    viewModel.send(.setBells)
                    dismiss.callAsFunction()
                }
            }
            
            Section {
                Button("Leave tower") {
                    viewModel.send(.userLeft)
                    dismiss.callAsFunction()
                    
                    router.moveTo(.main(user: viewModel.user, apiService: viewModel.apiService))
                }
            }
        }
    }
}
