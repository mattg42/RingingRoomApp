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
            var tempUsers = Array(state.users.keys)
            if !tempUsers.contains(Ringer.wheatley.ringerID) {
                for assignment in state.assignments {
                    if let assignment {
                        tempUsers.removeFirstInstance(of: assignment)
                    }
                }
                
                tempUsers = tempUsers.shuffled()
                
                for i in 0..<state.size {
                    if state.assignments[i] == nil {
                        let user = tempUsers.removeFirst()
                        viewModel.send(.assignUser(bell: i + 1, user: user))
                    }
                }
            } else {
                tempUsers.removeFirstInstance(of: Ringer.wheatley.ringerID)
                
                for assignment in state.assignments {
                    if let assignment {
                        tempUsers.removeFirstInstance(of: assignment)
                    }
                }
                
                tempUsers.shuffle()
                
                let bells = state.assignments.enumerated()
                    .filter({ $0.element == nil })
                    .map(\.offset)
                    .shuffled()
                
                for bell in bells {
                    if tempUsers.count > 0 {
                        let user = tempUsers.removeFirst()
                        viewModel.send(.assignUser(bell: bell + 1, user: user))
                    } else {
                        viewModel.send(.assignUser(bell: bell + 1, user: Ringer.wheatley.ringerID))
                    }
                }
            }
        } label: {
            Text("Fill In")
        }
        .disabled(state.users.count < state.size && !state.users.keys.contains(Ringer.wheatley.ringerID))
        .opacity(state.users.count < state.size && !state.users.keys.contains(Ringer.wheatley.ringerID) ? 0.35 : 1)
    }
}

struct UnassignAllButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    var body: some View {
        Button {
            for i in 0..<state.size {
                if state.assignments[i] != nil {
                    viewModel.send(.assignUser(bell: i + 1, user: 0))
                }
            }
        } label: {
            Text("Unassign all")
        }
    }
}

struct UsersListView: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    @Binding var selectedUser: Int
    
    var sortedUsers: [Int] {
        var users = [Int]()
        
        for assignment in state.assignments {
            if let assignment {
                if !users.contains(assignment) {
                    users.append(assignment)
                }
            }
        }
        
        users.append(contentsOf: state.users.keys
            .filter { user in
                !state.assignments.contains(user)
            }
            .sorted { user1, user2 in
                state.users[user1]!.name < state.users[user2]!.name
            }
        )
        
        return users
    }
    
    var body: some View {
        VStack(spacing: 14) {
            ForEach(sortedUsers, id: \.self) { user in
                RingerView(user: user, selectedUser: (selectedUser == user))
                    .opacity(viewModel.hasPermissions ? 1 : (user == selectedUser) ? 1 : 0.35)
                    .onTapGesture(perform: {
                        if viewModel.hasPermissions {
                            selectedUser = user
                        }
                    })
                
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 10)
    }
}

struct AssigmentButtons: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState

    var selectedUser: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 7) {
            ForEach(0..<state.assignments.count, id: \.self) { number in
                HStack(alignment: .center, spacing: 5) {
                    if canUnassign(at: number) {
                        Button {
                            viewModel.send(.assignUser(bell: number + 1, user: 0))
                        } label: {
                            Text("X")
                                .foregroundColor(.primary)
                                .font(.title3)
                                .fixedSize()
                                .padding(.vertical, -4)
                        }
                    }
                    UnassignButton(number: number, selectedUser: selectedUser)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
    }
    
    func canUnassign(at bell: Int) -> Bool {
        state.assignments[bell] != nil && (viewModel.hasPermissions || state.assignments[bell] == viewModel.unwrappedRinger.ringerID)
    }
}

struct UnassignButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState

    let number: Int
    let selectedUser: Int
    
    var body: some View {
        Button {
            viewModel.send(.assignUser(bell: number + 1, user: selectedUser))
        } label: {
            ZStack {
                ZStack {
                    Circle()
                        .fill(Color.main)
                    
                    Text("1")
                        .font(.callout)
                        .bold()
                        .opacity(0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                
                Text(String(number + 1))
                    .font(.callout)
                    .bold()
                    .foregroundColor(Color.white)
                
            }
            .fixedSize()
        }
        .disabled(state.assignments[number] != nil)
        .opacity(state.assignments[number] == nil ? 1 : 0.35)
        .animation(.linear(duration: 0.15), value: state.assignments)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct UsersView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    @State private var selectedUser = 0
    
    var body: some View {
        Form {
            Section {
                ScrollView(showsIndicators: false) {
                    
                    HStack(alignment: .top) {
                        UsersListView(selectedUser: $selectedUser)
                        
                        AssigmentButtons(selectedUser: selectedUser)
                    }
                }
                
                if viewModel.hasPermissions {
                    FillInButton()
                    
                    UnassignAllButton()
                }
            }
            .onAppear {
                if selectedUser == 0 {
                    selectedUser = viewModel.unwrappedRinger.ringerID
                }
            }
        }
    }
    

}

struct RingerView:View {
    
    @EnvironmentObject var state: RingingRoomState

    var user: Int
    var selectedUser: Bool
        
    var body: some View {
        HStack {
            Text(!state.assignments.contains(user) ? "-" : getString())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(state.users[user]!.name)
                .fontWeight(selectedUser ? .bold : .regular)
                .lineLimit(1)
                .layoutPriority(2)
            Spacer()
        }
        .foregroundColor(selectedUser ? Color.main : Color.primary)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
    }
    
    func getString() -> String {
        let indices = state.assignments.enumerated()
            .filter { $0.element == user }
            .map(\.offset)
        
        var str = ""
        for (index, number) in indices.enumerated() {
            if index == 0 {
                str += String(number + 1)
            } else {
                str += ", \(number + 1)"
            }
        }
        return str
    }
}
