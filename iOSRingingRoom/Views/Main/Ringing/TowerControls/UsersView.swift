//
//  UsersView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import SwiftUI

struct FillInButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    var body: some View {
        Button {
            var tempUsers = state.users
            if !state.users.contains(Ringer.wheatley) {
                for assignment in state.assignments {
                    if let assignment {
                        tempUsers.removeAll(where: { $0.ringerID == assignment })
                    }
                }
                
                tempUsers.shuffle()
                
                for i in 0..<state.size {
                    if state.assignments[i] == nil {
                        viewModel.send(.assignUser(bell: i + 1, user: tempUsers.removeFirst().ringerID))
                    }
                }
            } else {
                tempUsers.remove(Ringer.wheatley)
                
                for assignment in state.assignments {
                    if let assignment {
                        tempUsers.removeAll(where: { $0.ringerID == assignment })
                    }
                }
                
                tempUsers.shuffle()
                
                let bells = state.assignments.enumerated()
                    .filter({ $0.element == nil })
                    .map(\.offset)
                    .shuffled()
                
                for bell in bells {
                    if tempUsers.count > 0 {
                        viewModel.send(.assignUser(bell: bell + 1, user: tempUsers.removeFirst().ringerID))
                    } else {
                        viewModel.send(.assignUser(bell: bell + 1, user: Ringer.wheatley.ringerID))
                    }
                }
            }
        } label: {
            Text("Fill In")
        }
        .disabled(state.users.count < state.size && !state.users.contains(Ringer.wheatley))
        .opacity(state.users.count < state.size && !state.users.contains(Ringer.wheatley) ? 0.35 : 1)
    }
}

struct UnassignAllButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    var body: some View {
        Button {
            for i in 0..<state.size {
                if state.assignments[i] != nil {
                    viewModel.send(.unassignBell(bell: i + 1))
                }
            }
        } label: {
            Text("Unassign all")
        }
    }
}
// TODO: Mark ringers as sitting out

struct UsersView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    @State private var selectedUser = 0
    
    var assignedUsers: [Ringer] {
        state.users
            .filter { state.assignments.contains($0.ringerID) }
            .sorted { state.assignments.firstIndex(of: $0.ringerID)! < state.assignments.firstIndex(of: $1.ringerID)! }
    }
    
    var unassignedUsers: [Ringer] {
        state.users
            .filter { !state.assignments.contains($0.ringerID) }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    @State var dialogData = [Int]()
    @State var presenting = false
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "main")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Unassigned")) {
                List(unassignedUsers) { user in
                    ListCell(user: user)
                        .disabled(state.hostMode && !viewModel.towerInfo.isHost && user.ringerID != viewModel.unwrappedRinger.ringerID)
                }
            }
            
            Section(header: Text("Assigned")) {
                List(assignedUsers) { user in
                    ListCell(user: user)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                let assignedBells = state.assignments
                                    .enumerated()
                                    .filter { $0.element == user.ringerID }
                                    .map(\.offset)
                                    .map { $0 + 1 }
                                
                                if assignedBells.count == 1 {
                                    viewModel.send(.unassignBell(bell: assignedBells[0]))
                                } else {
                                    dialogData = assignedBells
                                    presenting = true
                                }
                            } label: {
                                Text("Unassign")
                            }
                            .tint(.red)
                        }
                        .confirmationDialog("Choose a bell to unassign.", isPresented: $presenting) {
                            ForEach(dialogData, id: \.self) { bell in
                                Button {
                                    viewModel.send(.unassignBell(bell: bell))
                                } label: {
                                    Text("\(bell)")
                                }
                                .tint(.main)
                            }
                            Button {
                                for bell in dialogData {
                                    viewModel.send(.unassignBell(bell: bell))
                                }
                            } label: {
                                Text("All")
                            }
                        } message: {
                            Text("Select the bell to unassign.")
                        }
                        .tint(.main)
                        .disabled(state.hostMode && !viewModel.towerInfo.isHost && user.ringerID != viewModel.unwrappedRinger.ringerID)
                }
            }
            
            Section(footer: Text("Tap a name then a number to assign or unassign." + (state.hostMode && !viewModel.towerInfo.isHost ? "\n\nHost mode is enabled, you may catch hold, but not assign others." : ""))) {
                FillInButton()
                    .disabled(state.hostMode && !viewModel.towerInfo.isHost)
                
                UnassignAllButton()
                    .disabled(state.hostMode && !viewModel.towerInfo.isHost)
                
            }
        }
        .animation(.default, value: state.assignments)
        .animation(.default, value: state.users)
    }
}

struct ListCell: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    let user: Ringer

    var unassignedBells: [Int] {
        state.assignments
            .enumerated()
            .filter { $0.element == nil }
            .map(\.offset)
            .map { $0 + 1 }
    }
    
    var assignedBells: [Int] {
        state.assignments
            .enumerated()
            .filter { $0.element == user.ringerID }
            .map(\.offset)
            .map { $0 + 1 }
    }
    
    var body: some View {
        Menu {
                Section("Assign") {
                    ForEach(unassignedBells, id: \.self) { num in
                        Button {
                            viewModel.send(.assignUser(bell: num, user: user.ringerID))
                        } label: {
                            Text("\(num)")
                        }
                    }
                }
                Section("Unassign") {
                    ForEach(assignedBells, id: \.self) { num in
                        Button(role: .destructive) {
                            viewModel.send(.unassignBell(bell: num))
                        } label: {
                            Text("\(num)")
                        }
                    }
                    if assignedBells.count >= 2 {
                        Button(role: .destructive) {
                            for bell in assignedBells {
                                viewModel.send(.unassignBell(bell: bell))
                            }
                        } label: {
                            Text("All")
                        }
                    }
                }
                .tint(.red)
        } label: {
            HStack {
                Text(user.name)
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
                
                Spacer()
                
                state.assignments
                    .enumerated()
                    .filter { $0.element == user.ringerID }
                    .map(\.offset)
                    .map { $0 + 1 }
                    .reduce(Text(""), { $0 + Text(Image(systemName: "\($1).circle")).font(.title2) + Text(" ").font(.caption2) })
                    .lineLimit(1)
                    .allowsTightening(true)
            }
        }
    }
}
