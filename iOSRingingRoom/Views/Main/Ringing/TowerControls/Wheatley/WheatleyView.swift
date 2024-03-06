//
//  WheatleyView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import Foundation
import SwiftUI

enum RowGenType: String, Identifiable, CaseIterable {
    var id: Self { self }
    case method, composition
}

struct WheatleyView: View {
    @EnvironmentObject var state: RingingRoomState
    @EnvironmentObject var wheatleyState: WheatleyState
    @EnvironmentObject var viewModel: RingingRoomViewModel

    @State var hours = 2
    @State var minutes = 55
    @State var pealSpeed = 175
    
    @State var fixedStrikingInterval = true
    @State var wholePullAndOff = true
    @State var stopAtRounds = true
    @State var callComposition = true
    
    @State var complibUrl = ""
    @State var selectedRowGenType = RowGenType.method
    
    @FocusState var isFocused: Bool
    
    func wheatleyMethodText(title: String, url: String) -> LocalizedStringKey {
        // Needs to be split up to get the markdown link working
        let urlString = "After 'Look To', Wheatley will ring [\(title)](https://rsw.me.uk/blueline/methods/view/\(url))."
        return LocalizedStringKey(urlString)
    }
    
    func wheatleyCompText(title: String, url: String) -> LocalizedStringKey {
        // Needs to be split up to get the markdown link working
        let urlString = "After 'Look To', Wheatley will ring [\(title)](\(url))."
        return LocalizedStringKey(urlString)
    }
    
    // TODO: disable controls whern wheatley is running
    var body: some View {
        Form {
            Section {
                switch wheatleyState.rowGen {
                case .method(let method):
                    Text(wheatleyMethodText(title: method.title, url: method.url))
                        .tint(.main)
                case .comp(let comp):
                    Text(wheatleyCompText(title: comp.title, url: comp.url))
                        .tint(.main)
                    Toggle("Wheatley makes calls", isOn: $callComposition)
                        .onAppear {
                            callComposition = wheatleyState.callComposition
                        }
                        .onChange(of: wheatleyState.callComposition) { newValue in
                            if callComposition != newValue {
                                callComposition = newValue
                            }
                        }
                        .onChange(of: callComposition) { newValue in
                            if wheatleyState.callComposition != newValue {
                                viewModel.send(.setWheatleySetting(setting: .callComposition(newValue)))
                                
                                wheatleyState.callComposition = callComposition
                            }
                        }
                }
                
                if !wheatleyState.wheatleyIsRinging {
                    
                    Picker("Row gen type", selection: $selectedRowGenType) {
                        ForEach(RowGenType.allCases) { rowGenType in
                            Text(rowGenType.rawValue.capitalized)
                                .id(rowGenType)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedRowGenType == .method {
                        NavigationLink("Set method") {
                            WheatleySearchView()
                        }
                    } else {
                        TextField("Complib url or ID", text: $complibUrl)
                            .focused($isFocused)
                        Button("Load") {
                            var processedUrl = complibUrl.trimmingCharacters(in: .whitespaces)
                            
                            let range = NSRange(location: 0, length: processedUrl.utf16.count)
                            let regex = try! NSRegularExpression(pattern: "^[0-9]+(?:\\?.*)?$")
                            if regex.firstMatch(in: processedUrl, range: range) != nil {
                                processedUrl = "https://complib.org/composition/" + processedUrl
                            }
                            processedUrl = processedUrl
                                .lowercased()
                                .replacingOccurrences(of: "https://", with: "")
                                .replacingOccurrences(of: "http://", with: "")
                            let urlSegments = processedUrl.split(separator: "/")
                            
                            if (!processedUrl.hasPrefix("complib.org")) {
                                AlertHandler.presentAlert(title: "Error", message: "URL doesn't point to 'complib.org'.", dismiss: .cancel(title: "OK", action: nil))
                                return
                            }
                            
                            if (urlSegments.count != 3 || urlSegments[1] != "composition") {
                                AlertHandler.presentAlert(title: "Error", message: "URL doesn't point to a composition.", dismiss: .cancel(title: "OK", action: nil))
                                return
                            }
                            
                            if (urlSegments.count == 3 && urlSegments[2] == "") {
                                AlertHandler.presentAlert(title: "Error", message: "Composition ID is empty", dismiss: .cancel(title: "OK", action: nil))
                                return;
                            }
                            
                            let complibID = urlSegments.last!.split(separator: "?").first!
                            
                            Task {
                                await ErrorUtil.do {
                                    let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.\(processedUrl)")!)
                                    guard let response = response as? HTTPURLResponse else { throw APIError.noResponse }
                                    switch response.statusCode {
                                    case 200...299:
                                        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
                                        let stage = json["stage"] as! Int
                                        let title = json["derivedTitle"] as! String
                                        
                                        if stage == state.size || stage == state.size - 1 {
                                            viewModel.send(.setWheatleyRowGen(rowGen: ["type": "composition", "title": title, "url": "https://\(processedUrl)"]))
                                            complibUrl = ""
                                            isFocused = false
                                        }
                                        
                                    case 401:
                                        AlertHandler.presentAlert(title: "Error", message: "Composition #\(complibID) is private.", dismiss: .cancel(title: "OK", action: nil))
                                    case 404:
                                        AlertHandler.presentAlert(title: "Error", message: "Composition #\(complibID) doesn't exist.", dismiss: .cancel(title: "OK", action: nil))
                                    case 500...599:
                                        AlertHandler.presentAlert(title: "Error", message: "Complib server error.", dismiss: .cancel(title: "OK", action: nil))
                                    default:
                                        AlertHandler.presentAlert(title: "Error", message: "Unknown complib error: \(response.statusCode).", dismiss: .cancel(title: "OK", action: nil))
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Button("Stop touch") {
                        viewModel.send(.wheatleyStopTouch)
                    }
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
