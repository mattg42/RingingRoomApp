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

//
//struct UsersListView: View {
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    @EnvironmentObject var state: RingingRoomState
//
//    @Binding var selectedUser: Int
//
//    var sortedUsers: [Int] {
//        var users = [Int]()
//
//        for assignment in state.assignments {
//            if let assignment {
//                if !users.contains(assignment) {
//                    users.append(assignment)
//                }
//            }
//        }
//
//        users.append(contentsOf: state.users.keys
//            .filter { user in
//                !state.assignments.contains(user)
//            }
//            .sorted { user1, user2 in
//                state.users[user1]!.name < state.users[user2]!.name
//            }
//        )
//
//        return users
//    }
//
//    var body: some View {
//        VStack(spacing: 14) {
//            ForEach(sortedUsers, id: \.self) { user in
//                RingerView(user: user, selectedUser: (selectedUser == user))
//                    .opacity(viewModel.hasPermissions ? 1 : (user == selectedUser) ? 1 : 0.35)
//                    .onTapGesture(perform: {
//                        if viewModel.hasPermissions {
//                            selectedUser = user
//                        }
//                    })
//
//            }
//        }
//        .fixedSize(horizontal: false, vertical: true)
//        .padding(.top, 10)
//    }
//}
//
//struct AssigmentButtons: View {
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    @EnvironmentObject var state: RingingRoomState
//
//    var selectedUser: Int
//
//    var body: some View {
//        VStack(alignment: .trailing, spacing: 7) {
//            ForEach(0..<state.assignments.count, id: \.self) { number in
//                HStack(alignment: .center, spacing: 5) {
//                    if canUnassign(at: number) {
//                        Button {
//                            viewModel.send(.assignUser(bell: number + 1, user: 0))
//                        } label: {
//                            Text("X")
//                                .foregroundColor(.primary)
//                                .font(.title3)
//                                .fixedSize()
//                                .padding(.vertical, -4)
//                        }
//                    }
//                    UnassignButton(number: number, selectedUser: selectedUser)
//                }
//            }
//        }
//        .padding(.vertical, 6)
//        .padding(.horizontal, 6)
//    }
//
//    func canUnassign(at bell: Int) -> Bool {
//        state.assignments[bell] != nil && (viewModel.hasPermissions || state.assignments[bell] == viewModel.unwrappedRinger.ringerID)
//    }
//}
//
//struct UnassignButton: View {
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    @EnvironmentObject var state: RingingRoomState
//
//    let number: Int
//    let selectedUser: Int
//
//    var body: some View {
//        Button {
//            viewModel.send(.assignUser(bell: number + 1, user: selectedUser))
//        } label: {
//            ZStack {
//                ZStack {
//                    Circle()
//                        .fill(Color.main)
//
//                    Text("1")
//                        .font(.callout)
//                        .bold()
//                        .opacity(0)
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 4)
//                }
//
//                Text(String(number + 1))
//                    .font(.callout)
//                    .bold()
//                    .foregroundColor(Color.white)
//
//            }
//            .fixedSize()
//        }
//        .disabled(state.assignments[number] != nil)
//        .opacity(state.assignments[number] == nil ? 1 : 0.35)
//        .animation(.linear(duration: 0.15), value: state.assignments)
//        .fixedSize(horizontal: true, vertical: true)
//    }
//}

struct UsersView: View {
    
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    @State private var selectedUser = 0
    
    @State var assignedUsers = [Ringer]()
    
    @State var unassignedUsers = [Ringer]()
    
    @State var dialogData = [Int]()
    @State var presenting = false
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "main")
    }
    
    var body: some View {
        Form {
            
            Section {
                FillInButton()
                UnassignAllButton()
            }
            
//            if !unassignedUsers.isEmpty {

//            }
            
//            if !assignedUsers.isEmpty {
                Section(header: Text("Assigned")) {
                    List(assignedUsers) { user in
                        ListCell(user: user)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
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
                            } message: {
                                Text("Select the bell to unassign.")
                            }
                            .tint(.main)
                    }
//                }
                    Section(header: Text("Unassigned")) {
                        List(unassignedUsers) { user in
                            ListCell(user: user)
                        }
                    }
            }
        }
        .onAppear {
            updateAssignedUsers(users: state.users, assignments: state.assignments)
            updateUnassignedUsers(users: state.users, assignments: state.assignments)
        }
        .onChange(of: state.assignments) { newValue in
            withAnimation {
                updateAssignedUsers(users: state.users, assignments: newValue)
                updateUnassignedUsers(users: state.users, assignments: newValue)
            }
        }
        .onChange(of: state.users) { newValue in
            withAnimation {
                updateUnassignedUsers(users: newValue, assignments: state.assignments)
            }
        }
    }
    
    func updateUnassignedUsers(users: [Ringer], assignments: [Int?]) {
        unassignedUsers = users
            .filter({ !assignments.contains($0.ringerID) })
            .sorted { user1, user2 in
                user1.name.lowercased() < user2.name.lowercased()
            }
    }
    
    func updateAssignedUsers(users: [Ringer], assignments: [Int?]) {
        assignedUsers = Set(assignments)
            .compactMap { user in
                users.first(where: { $0.ringerID == user})
            }
            .sorted { user1, user2 in
                assignments.firstIndex(of: user1.ringerID)! < assignments.firstIndex(of: user2.ringerID)!
            }
    }
}

struct ListCell: View {
    @EnvironmentObject var viewModel: RingingRoomViewModel
    @EnvironmentObject var state: RingingRoomState
    
    let user: Ringer
    
//    var assignments: [Int] {
//        state.assignments
//            .enumerated()
//            .filter { $0.element == user.ringerID }
//            .map(\.offset)
//            .map { $0 + 1 }
//    }
    @State var unassignedBells = [Int]()
    
    var body: some View {
        Menu {
            ForEach(unassignedBells, id: \.self) { num in
                Button {
                    viewModel.send(.assignUser(bell: num, user: user.ringerID))
                } label: {
                    Text("\(num)")
                }
            }
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
//                    .minimumScaleFactor(0.5)
//                HStack(spacing: 4) {
//                    ForEach(
//                        state.assignments
//                            .enumerated()
//                            .filter { $0.element == user.ringerID }
//                            .map(\.offset)
//                            .map { $0 + 1 },
//                        id: \.self
//                    ) { num in
//                        Text(Image(systemName: "\(num).circle"))
////                            .font(.title3)
//                            .minimumScaleFactor(0.5)
//                    }
//                }
//                .minimumScaleFactor(0.5)
            }
//            .fixedSize()
        }
        .onAppear(perform: { setUnassignedBells(newValue: state.assignments) })
        .onChange(of: state.assignments, perform: setUnassignedBells)
        .disabled(unassignedBells.isEmpty)
    }
    
    func setUnassignedBells(newValue: [Int?]) {
        unassignedBells = newValue.enumerated()
            .filter { $0.element == nil }
            .map(\.offset)
            .map { $0 + 1 }
        print(user.name, "Changed", unassignedBells)
    }
}
//
//struct RingerView:View {
//    
//    @EnvironmentObject var state: RingingRoomState
//
//    var user: Int
//    var selectedUser: Bool
//        
//    var body: some View {
//        HStack {
//            Text(!state.assignments.contains(user) ? "-" : getString())
//                .minimumScaleFactor(0.5)
//                .lineLimit(1)
//            Text(state.users[user]!.name)
//                .fontWeight(selectedUser ? .bold : .regular)
//                .lineLimit(1)
//                .layoutPriority(2)
//            Spacer()
//        }
//        .foregroundColor(selectedUser ? Color.main : Color.primary)
//        .fixedSize(horizontal: false, vertical: true)
//        .contentShape(Rectangle())
//    }
//    
//    func getString() -> String {
//        let indices = state.assignments.enumerated()
//            .filter { $0.element == user }
//            .map(\.offset)
//        
//        var str = ""
//        for (index, number) in indices.enumerated() {
//            if index == 0 {
//                str += String(number + 1)
//            } else {
//                str += ", \(number + 1)"
//            }
//        }
//        return str
//    }
//}
