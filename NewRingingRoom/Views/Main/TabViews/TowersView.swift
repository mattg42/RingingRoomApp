//
//  RingView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

enum TowerListType: String, CaseIterable, Identifiable {
    case recent, bookmarked, created, host
    var id: Self { self }
}

struct RingView: View {
    
    let towers = Array(repeating: Tower.blank, count: 10)
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Picker("Tower list type", selection: .constant(TowerListType.recent)) {
                        ForEach(TowerListType.allCases) { type in
                            Text(type.rawValue.capitalized)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                }
                
                ScrollView {
                    VStack {
                        ForEach(towers) { tower in
                            Text(tower.towerName)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Towers")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
}

struct Delimiter: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary)
            .opacity(0.4)
            .frame(height: 2)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension Array where Element == Int {
    mutating func removeFirstInstance(of element: Int) {
        for (index, ele) in self.enumerated() {
            if ele == element {
                self.remove(at: index)
                return
            }
        }
    }
    
}
