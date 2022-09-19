//
//  UsersView.swift
//  NewRingingRoom
//
//  Created by Matthew on 19/09/2022.
//

import SwiftUI

struct FillInButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    var body: some View {
        Button {
            var tempUsers = Array(viewModel.users.keys)
            if !tempUsers.contains(Ringer.wheatley.ringerID) {
                for assignment in viewModel.assignments {
                    if let assignment {
                        tempUsers.removeFirstInstance(of: assignment)
                    }
                }
                
                tempUsers = tempUsers.shuffled()
                
                for i in 0..<viewModel.size {
                    if viewModel.assignments[i] == nil {
                        let user = tempUsers.removeFirst()
                        viewModel.send(.assignUser(bell: i + 1, user: user))
                    }
                }
            } else {
                tempUsers.removeFirstInstance(of: Ringer.wheatley.ringerID)
                
                for assignment in viewModel.assignments {
                    if let assignment {
                        tempUsers.removeFirstInstance(of: assignment)
                    }
                }
                
                tempUsers.shuffle()
                
                let bells = viewModel.assignments.enumerated()
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
        .disabled(viewModel.users.count < viewModel.size && !viewModel.users.keys.contains(Ringer.wheatley.ringerID))
        .opacity(viewModel.users.count < viewModel.size && !viewModel.users.keys.contains(Ringer.wheatley.ringerID) ? 0.35 : 1)
    }
}

struct UnassignAllButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel

    var body: some View {
        Button {
            for i in 0..<viewModel.size {
                if viewModel.assignments[i] != nil {
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
    
    @Binding var selectedUser: Int
    
    var sortedUsers: [Int] {
        var users = [Int]()
        
        for assignment in viewModel.assignments {
            if let assignment {
                if !users.contains(assignment) {
                    users.append(assignment)
                }
            }
        }
        
        users.append(contentsOf: viewModel.users.keys
            .filter { user in
                !viewModel.assignments.contains(user)
            }
            .sorted { user1, user2 in
                viewModel.users[user1]!.name < viewModel.users[user2]!.name
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
    
    var selectedUser: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 7) {
            ForEach(0..<viewModel.assignments.count, id: \.self) { number in
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
        viewModel.assignments[bell] != nil && (viewModel.hasPermissions || viewModel.assignments[bell] == viewModel.ringer!.ringerID)
    }
}

struct UnassignButton: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel

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
        .disabled(viewModel.assignments[number] != nil)
        .opacity(viewModel.assignments[number] == nil ? 1 : 0.35)
        .animation(.linear(duration: 0.15), value: viewModel.assignments)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct UsersView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    
    @State var selectedUser = 0
    
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
                    selectedUser = viewModel.ringer!.ringerID
                }
            }
        }
    }
    

}

struct RingerView:View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel

    var user: Int
    var selectedUser: Bool
        
    var body: some View {
        HStack {
            Text(!viewModel.assignments.contains(user) ? "-" : getString())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(viewModel.users[user]!.name)
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
        let indices = viewModel.assignments.enumerated()
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
