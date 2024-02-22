//
//  WheatleySearchView.swift
//  Ringing Room
//
//  Created by Matthew on 17/11/2023.
//

import SwiftUI

struct WheatleySearchView: View {
    @EnvironmentObject var state: RingingRoomState
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init() {
        UITableView.appearance().backgroundColor = .clear
    }
    
    
    @State var text: String = ""
    
    @FocusState private var isEditing: Bool
    
    @State var methods = [BluelineMethod]()
    
    var body: some View {
        VStack {
            HStack {
                TextField("Method", text: $text)
                    .focused($isEditing)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if isEditing {
                                Button(action: {
                                    self.text = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                                .transition(.opacity)
                                .animation(.default, value: isEditing)
                            }
                        }
                    )
                    .onChange(of: text) { newValue in
                        Task {
                            await ErrorUtil.do {
                                let (json, _) = try await URLSession.shared.data(from: URL(string: "https://rsw.me.uk/blueline/methods/search.json?q=\(newValue)&stage=\(state.size - 1),\(state.size)")!)
                                let methods = (try JSONDecoder().decode(Methods.self, from: json)).results
                                self.methods = methods
                            }
                        }
                        
                    }
                    .padding(.horizontal)

               
            }
            List(methods) { method in
                Button {
                    viewModel.send(.setWheatleyRowGen(rowGen: method.rowGen))
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack {
                        Text(method.title)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await ErrorUtil.do {
                    let (json, _) = try await URLSession.shared.data(from: URL(string: "https://rsw.me.uk/blueline/methods/search.json?q=&stage=\(state.size - 1),\(state.size)")!)
                    let methods = (try JSONDecoder().decode(Methods.self, from: json)).results
                    self.methods = methods
                }
            }
        }
        .onDisappear {
            UITableView.appearance().backgroundColor = .systemBackground
        }
        
    }
}

struct Methods: Codable {
    let results: [BluelineMethod]
}

struct BluelineMethod: Codable, Identifiable, Hashable {
    var id: Int {
        hashValue
    }
    
    let title: String
    let stage: Int
    let notation: String
    let lengthOfLead: Int
    let calls: Calls?
    let url: String
    
    var rowGen: [String: Any] {
        var wheatleyMethod = [String: Any]()
        wheatleyMethod["title"] = title
        wheatleyMethod["stage"] = stage
        wheatleyMethod["notation"] = notation
        wheatleyMethod["url"] = url
        
        func convertCall(call: Bob) -> [String: String] {
            var convertedCall = [String: String]()
            for i in 0..<Int((Double(lengthOfLead)/Double(call.every)).rounded(.up)) {
                convertedCall[String(call.from + i * call.every)] = call.notation
            }
            return convertedCall
        }
        
        let bob: [String: String]
        let single: [String: String]
        if let calls {
            bob = convertCall(call: calls.bob)
            
            if title == "Stedman Doubles" {
                single = [
                    "0": "145",
                    "6": "345"
                ]
            } else {
                single = convertCall(call: calls.single)
            }
        } else {
            bob = .init()
            single = .init()
        }
        
        wheatleyMethod["bob"] = bob
        wheatleyMethod["single"] = single
        wheatleyMethod["type"] = "method"
        return wheatleyMethod
    }
}

struct Calls: Codable, Hashable {
    let bob, single: Bob
    
    enum CodingKeys: String, CodingKey {
        case bob = "Bob"
        case single = "Single"
    }
}

struct Bob: Codable, Hashable {
    let notation: String
    let from, every: Int
}

struct WheatleyMethod: Codable {
    init(type: String, title: String, stage: Int, notation: String, url: String, bob: [Int : String], single: [Int : String]) {
        self.type = type
        self.title = title
        self.stage = stage
        self.notation = notation
        self.url = url
        self.bob = bob
        self.single = single
    }
    
    init(dictionary: [String: Any]) throws {
        guard dictionary["type"] as? String == "method" else { throw DecodingError.keyNotFound(WheatleyMethod.CodingKeys.title, .init(codingPath: [WheatleyMethod.CodingKeys.title], debugDescription: "Is comp not method")) }
        self = try JSONDecoder().decode(WheatleyMethod.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
    
    let type: String
    let title: String
    let stage: Int
    let notation: String
    let url: String
    let bob: [Int: String]
    let single: [Int: String]
}
