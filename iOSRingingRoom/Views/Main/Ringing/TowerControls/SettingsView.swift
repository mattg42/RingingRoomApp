//
//  SettingsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 10/09/2022.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    @EnvironmentObject var router: Router<MainRoute>

    @Environment(\.dismiss) var dismiss
    
    @SceneStorage("volume") var volume = UserDefaults.standard.optionalDouble(forKey: "volume") ?? 1
    
    @SceneStorage("size") var size = 0
    @SceneStorage("bellType") var bellType = BellType.tower
    @SceneStorage("hostMode") var hostMode = false
    
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
            
            Section(footer: state.hostMode && !viewModel.towerInfo.isHost ? Text("Host mode is enabled. Only hosts can change tower settings or assign bells.") : Text("")) {
                if viewModel.towerInfo.hostModePermitted && viewModel.towerInfo.isHost {
                    Toggle("Host mode", isOn: $hostMode)
                        .onAppear {
                            hostMode = state.hostMode
                        }
                        .onChange(of: state.hostMode) { newValue in
                            if hostMode != newValue {
                                hostMode = newValue
                            }
                        }
                        .onChange(of: hostMode) { newValue in
                            if state.hostMode != newValue {
                                print("sending")
                                viewModel.send(.hostModeSet(to: newValue))
                                
                                // The server doesn't emit s_host_mode_ to the sender, so we update the state here
                                state.hostMode = hostMode
                            }
                        }
                }
                
                
                Picker("Number of bells", selection: $size) {
                    ForEach(viewModel.towerInfo.towerSizes, id: \.self) { size in
                        Text("\(size)")
                            .tag(size)
                    }
                }
                .disabled(state.hostMode && !viewModel.towerInfo.isHost)
                .onAppear {
                    size = state.size
                }
                .onChange(of: state.size) { newValue in
                    if size != newValue {
                        size = newValue
                    }
                }
                .onChange(of: size) { newValue in
                    if state.size != newValue {
                        viewModel.send(.sizeChange(to: newValue))
                    }
                }
                
                
                Picker("Bell type", selection: $bellType) {
                    ForEach(BellType.allCases) { bell in
                        Text(bell.rawValue)
                            .tag(bell)
                    }
                }
                .disabled(state.hostMode && !viewModel.towerInfo.isHost)
                .onAppear {
                    bellType = state.bellType
                }
                .onChange(of: state.bellType) { newValue in
                    if bellType != newValue {
                        bellType = newValue
                    }
                }
                .onChange(of: bellType) { newValue in
                    if state.bellType != newValue {
                        viewModel.send(.audioChange(to: newValue))
                    }
                }
            }

            Section {
                Button("Change perspective") {
                    state.bellMode = .rotate
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
