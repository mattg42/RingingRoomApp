//
//  TowerControlsView.swift
//  NewRingingRoom
//
//  Created by Matthew on 20/08/2022.
//

import SwiftUI

enum TowerControlViewSelection: String, CaseIterable, Identifiable {
    var id: Self { self }
    
    case users, settings, chat
}

struct TowerControlsView: View {
    
    @EnvironmentObject var state: TowerControlsState
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $state.towerControlsViewSelection) {
                    ForEach(TowerControlViewSelection.allCases) { selection in
                        Text(selection.rawValue.capitalized)
                            .tag(selection)
                    }
                }
                .pickerStyle(.segmented)

                Button("Back") {
//                    withAnimation {
                    dismiss()
//                    }
                }
                .padding(.leading, 7)
                
            }
            .padding(.horizontal)
            .padding(.bottom, 2)
            switch state.towerControlsViewSelection {
            case .settings:
                SettingsView()
            case .users:
                UsersView()
            case .chat:
                ChatView()
            }
        }
        .padding(.vertical)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
