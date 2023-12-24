//
//  WheatleySearchView.swift
//  Ringing Room
//
//  Created by Matthew on 17/11/2023.
//

import SwiftUI

struct WheatleySearchView: View {
    @EnvironmentObject var state: RingingRoomState
    
    init() {
        UITableView.appearance().backgroundColor = .clear
    }
    
    
    @State var text: String = ""
    
    @FocusState private var isEditing: Bool
    
    @State var methods = [Method]()
    
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
                                print(methods)
                            }
                        }
                        
                    }
                    .padding(.horizontal)

               
            }
            List(methods) { method in
                Button {
                    // send wheatley method
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
                    print(methods)
                }
            }
        }
        .onDisappear {
            UITableView.appearance().backgroundColor = .systemBackground
        }
        
    }
}

struct Methods: Codable {
    let results: [Method]
}

struct Method: Codable, Identifiable, Hashable {
    var id: Int {
        hashValue
    }
    
    let title: String
    let stage: Int
    let notation: String
    let lengthOfLead: Int
    let calls: Calls?
    let url: String
}

struct Calls: Codable, Hashable {
    let bob, single: Bob
    
    enum CodingKeys: String, CodingKey {
        case bob = "Bob"
        case single = "Single"
    }
}

struct Bob: Codable, Hashable {
    let symbol: Symbol
    let notation: String
    let from, every, cover: Int
}

enum Symbol: String, Codable {
    case empty = "-"
    case s = "s"
}
