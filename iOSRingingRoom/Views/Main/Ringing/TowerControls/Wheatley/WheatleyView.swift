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

private struct CompositionRequest: Identifiable {
    let id = UUID()
    let apiURL: URL
    let publicURL: URL
    let compositionID: String
    let towerSize: Int

    init(input: String, towerSize: Int) throws {
        guard towerSize > 0 else { throw WheatleyError.invalidCompositionURL }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let compositionID: String

        if !trimmedInput.isEmpty && trimmedInput.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) {
            compositionID = trimmedInput
        } else {
            guard
                let components = URLComponents(string: trimmedInput),
                let scheme = components.scheme?.lowercased(),
                scheme == "http" || scheme == "https"
            else {
                throw WheatleyError.invalidCompositionURL
            }

            guard components.host?.lowercased() == "complib.org" else {
                throw WheatleyError.invalidCompositionHost
            }

            guard components.user == nil, components.password == nil, components.port == nil else {
                throw WheatleyError.invalidCompositionHost
            }

            let pathSegments = components.path.split(separator: "/")
            guard pathSegments.count == 2, String(pathSegments[0]).lowercased() == "composition" else {
                throw WheatleyError.invalidCompositionPath
            }

            compositionID = String(pathSegments[1])
        }

        guard !compositionID.isEmpty else { throw WheatleyError.emptyCompositionID }
        guard compositionID.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) else {
            throw WheatleyError.invalidCompositionURL
        }

        var publicComponents = URLComponents()
        publicComponents.scheme = "https"
        publicComponents.host = "complib.org"
        publicComponents.path = "/composition/\(compositionID)"

        var apiComponents = URLComponents()
        apiComponents.scheme = "https"
        apiComponents.host = "api.complib.org"
        apiComponents.path = "/composition/\(compositionID)"

        guard let publicURL = publicComponents.url, let apiURL = apiComponents.url else {
            throw WheatleyError.invalidURL
        }

        self.apiURL = apiURL
        self.publicURL = publicURL
        self.compositionID = compositionID
        self.towerSize = towerSize
    }
}

private struct ComplibCompositionResponse: Decodable {
    let stage: Int
    let derivedTitle: String
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
    @State private var compositionRequest: CompositionRequest?
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
    
    var ringingroomLink: LocalizedStringKey {
        let string = "Wheatley is not enabled for this tower. To enable wheatley, you must be the ownwer of the tower, and change the tower settings on [ringingroom.com](https://\(viewModel.apiService.region.server)ringingroom.com/tower_settings/\(String(viewModel.towerInfo.towerID)))."
        return LocalizedStringKey(string)
    }
    
    var body: some View {
        if !state.users.contains(Ringer.wheatley) {
            Form {
                Text(ringingroomLink)
            }
        } else {
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
                                compositionRequest = nil
                                do {
                                    compositionRequest = try CompositionRequest(input: complibUrl, towerSize: state.size)
                                } catch {
                                    AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "OK", action: nil))
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
            .task(id: compositionRequest?.id) {
                guard let compositionRequest else { return }
                await loadComposition(compositionRequest)
            }
        }
    }

    @MainActor
    private func loadComposition(_ request: CompositionRequest) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: request.apiURL)
            try Task.checkCancellation()

            guard let response = response as? HTTPURLResponse else {
                throw WheatleyError.invalidResponse
            }
            guard 200..<300 ~= response.statusCode else {
                throw WheatleyError.httpStatus(response.statusCode)
            }

            let composition: ComplibCompositionResponse
            do {
                composition = try JSONDecoder().decode(ComplibCompositionResponse.self, from: data)
            } catch {
                throw WheatleyError.invalidCompositionPayload
            }
            try Task.checkCancellation()

            guard request.towerSize == state.size else { return }

            guard composition.stage == state.size || composition.stage == state.size - 1 else {
                AlertHandler.presentAlert(
                    title: "Error",
                    message: "Composition needs \(composition.stage) bells, not \(state.size). Change the tower size in tower controls and try again.",
                    dismiss: .cancel(title: "OK", action: nil)
                )
                return
            }

            viewModel.send(.setWheatleyRowGen(rowGen: [
                "type": "composition",
                "title": composition.derivedTitle,
                "url": request.publicURL.absoluteString
            ]))
            complibUrl = ""
            isFocused = false
        } catch is CancellationError {
            return
        } catch WheatleyError.httpStatus(401) {
            AlertHandler.presentAlert(title: "Error", message: "Composition #\(request.compositionID) is private.", dismiss: .cancel(title: "OK", action: nil))
        } catch WheatleyError.httpStatus(404) {
            AlertHandler.presentAlert(title: "Error", message: "Composition #\(request.compositionID) doesn't exist.", dismiss: .cancel(title: "OK", action: nil))
        } catch WheatleyError.httpStatus(let status) where status >= 500 {
            AlertHandler.presentAlert(title: "Error", message: "Complib server error.", dismiss: .cancel(title: "OK", action: nil))
        } catch WheatleyError.invalidCompositionPayload {
            AlertHandler.presentAlert(title: "Error", message: WheatleyError.invalidCompositionPayload.localizedDescription, dismiss: .cancel(title: "OK", action: nil))
        } catch {
            guard !Task.isCancelled else { return }
            AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "OK", action: nil))
        }
    }
}
