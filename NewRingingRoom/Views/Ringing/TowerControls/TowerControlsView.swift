//
//  TowerControlsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 20/08/2022.
//

import SwiftUI

enum TowerControlViewSelection: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case settings, users, chat, wheatley
}

struct TowerControlsView: View {
    
    @SceneStorage("selection") var viewSelection = TowerControlViewSelection.settings
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $viewSelection) {
                    ForEach(TowerControlViewSelection.allCases) { selection in
                        Text(selection.rawValue.capitalized)
                            .tag(selection)
                    }
                }
                .pickerStyle(.segmented)

                Button("Back") {
                    withAnimation {
                        dismiss()
                    }
                }
                
            }
            .padding(.horizontal)
            .padding(.bottom, 2)
            
            switch viewSelection {
            case .settings:
                SettingsView()
            case .users:
                UsersView()
                
            case .chat:
                ChatView()
                
            case .wheatley:
                Text("Settings")
                
            }
        }
        .padding(.vertical)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
