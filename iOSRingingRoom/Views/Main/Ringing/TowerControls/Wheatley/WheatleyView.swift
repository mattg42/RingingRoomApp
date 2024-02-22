//
//  WheatleyView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import Foundation
import SwiftUI

struct WheatleyView: View {
    @EnvironmentObject var wheatleyState: WheatleyState
    @EnvironmentObject var viewModel: RingingRoomViewModel

    @State var hours = 2
    @State var minutes = 55
    @State var pealSpeed = 175
    
    @State var fixedStrikingInterval = true
    @State var wholePullAndOff = true
    @State var stopAtRounds = true
    
    var wheatleyText: LocalizedStringKey {
        // Needs to be split up to get the markdown link working
        let urlString = "After 'Look To', Wheatley will ring [\(wheatleyState.rowGen.title)](https://rsw.me.uk/blueline/methods/view/\(wheatleyState.rowGen.url))."
        return LocalizedStringKey(urlString)
    }
    
    var body: some View {
        Form {
            Section {
                Text(wheatleyText)
                    .tint(.main)
                NavigationLink("Change method") {
                    WheatleySearchView()
                }
            }
            
            Section(header: Text("Peal Speed")) {
                HStack(spacing: 0) {
                    Stepper(value: Binding(get: {
                        return hours
                    }, set: { newValue in
                        if newValue == 8 {
                            minutes = 0
                        }
                        hours = newValue
                        
                        pealSpeed = hours * 60 + minutes
                    }), in: 1...8, step: 1) {
                        Text("\(hours) hrs")
                    }
                    .fixedSize()
                    Spacer()
                    Stepper(value: Binding(get: {
                        return minutes
                    }, set: { newValue in
                        if newValue == -5 {
                            if hours > 1 {
                                hours -= 1
                                minutes = 55
                            } else {
                                minutes = 0
                            }
                        } else if newValue == 60 {
                            if hours < 8 {
                                hours += 1
                                minutes = 0
                            }
                        } else {
                            if hours == 8 {
                                minutes = 0
                            } else {
                                minutes = newValue
                            }
                        }
                        pealSpeed = hours * 60 + minutes
                    }), in: -5...60, step: 5) {
                        HStack {
                            Spacer()
                            
                            Text("\(minutes) min")
                                .lineLimit(1)
                        }
                    }
                }
                .onChange(of: pealSpeed) { newValue in
                    if wheatleyState.pealSpeed != newValue {
                        viewModel.send(.setWheatleySetting(setting: .pealSpeed(pealSpeed)))
                    }
                }
                .onChange(of: wheatleyState.pealSpeed) { newValue in
                    hours = newValue / 60
                    minutes = newValue % 60
                }
                .onAppear {
                    hours = wheatleyState.pealSpeed / 60
                    minutes = wheatleyState.pealSpeed % 60
                }
                
                Toggle("Fixed striking interval", isOn: $fixedStrikingInterval)
                    .onAppear {
                        fixedStrikingInterval = wheatleyState.fixedStrikingInterval
                    }
                    .onChange(of: wheatleyState.fixedStrikingInterval) { newValue in
                        if fixedStrikingInterval != newValue {
                            fixedStrikingInterval = newValue
                        }
                    }
                    .onChange(of: fixedStrikingInterval) { newValue in
                        if wheatleyState.fixedStrikingInterval != newValue {
                            viewModel.send(.setWheatleySetting(setting: .fixedStrikingInterval(newValue)))

                            wheatleyState.fixedStrikingInterval = fixedStrikingInterval
                        }
                    }
            }
            
            Section {
                Toggle("Whole pull and off", isOn: $wholePullAndOff)
                    .onAppear {
                        wholePullAndOff = wheatleyState.wholePullAndOff
                    }
                    .onChange(of: wheatleyState.wholePullAndOff) { newValue in
                        if wholePullAndOff != newValue {
                            wholePullAndOff = newValue
                        }
                    }
                    .onChange(of: wholePullAndOff) { newValue in
                        if wheatleyState.wholePullAndOff != newValue {
                            viewModel.send(.setWheatleySetting(setting: .useUpDownIn(newValue)))
                            
                            wheatleyState.wholePullAndOff = wholePullAndOff
                        }
                    }
                
                Toggle("Stop at rounds", isOn: $stopAtRounds)
                    .onAppear {
                        stopAtRounds = wheatleyState.stopAtRounds
                    }
                    .onChange(of: wheatleyState.stopAtRounds) { newValue in
                        if stopAtRounds != newValue {
                            stopAtRounds = newValue
                        }
                    }
                    .onChange(of: stopAtRounds) { newValue in
                        if wheatleyState.stopAtRounds != newValue {
                            viewModel.send(.setWheatleySetting(setting: .stopAtRounds(newValue)))
                            
                            wheatleyState.stopAtRounds = stopAtRounds
                        }
                    }
            }
            
            Section {
                Button("Reset Wheatley", role: .destructive) {
                    viewModel.send(.resetWheatley)
                }
            }
        }
    }
}
