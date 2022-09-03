////
////  UsersView.swift
////  NewRingingRoom
////
////  Created by Matthew on 14/07/2022.
////
//
//import SwiftUI
//
//struct UsersView:View {
//    
//    //    @State private var showingUsers:Bool
//    
//    @EnvironmentObject var viewModel: RingingRoomViewModel
//    
//    @Environment(\.colorScheme) var colorScheme
//    
//    @State private var selectedUser = 0
//    
//    @State private var updateView = false
//    
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    @Environment(\.verticalSizeClass) var verticalSizeClass
//    
//    var isSplit:Bool {
//        get {
//            !(horizontalSizeClass == .compact || (UIApplication.shared.orientation?.isPortrait ?? true))
//        }
//    }
//        
//    var body: some View {
//        VStack {
//            HStack(alignment: .center) {
//                Text("Users")
//                    .font(.title3)
//                    .fontWeight(.heavy)
//                    .padding(.leading, 4)
//                Spacer()
//                if available() {
//                    Button(action: {
//                        var tempUsers = viewModel.users
//                        if !tempUsers.contains(Ringer.wheatley) {
//                            for assignedUser in viewModel.assignments {
//                                if let assignedUser {
//                                    tempUsers.remove(assignedUser)
//                                }
//                            }
//                            for i in 0..<viewModel.size {
//                                if viewModel.assignments[i] == nil {
//                                    let index = Int.random(in: 0..<tempUsers.count)
//                                    let user = tempUsers[index]
//                                    assign(user.ringerID, to: i+1)
//                                    tempUsers.remove(at: index)
//                                }
//                            }
//                        } else {
//                            tempUsers.remove(Ringer.wheatley)
//
//                            for assignedUser in viewModel.assignments {
//                                if let assignedUser {
//                                    tempUsers.remove(assignedUser)
//                                }
//                            }
//     
//                            var availableBells = viewModel.assignments.enumerated()
//                                .compactMap({ (index, ringer) in
//                                    if ringer == nil {
//                                        return index
//                                    } else {
//                                        return nil
//                                    }
//                                })
//                                                            
//                            availableBells.shuffle()
//                            tempUsers.shuffle()
//                            
//                            for user in tempUsers {
//                                if let bell = availableBells.first {
//                                    assign(user.ringerID, to: bell+1)
//                                    availableBells.removeFirst()
//                                } else {
//                                    break
//                                }
//                            }
//                            for bell in availableBells {
//                                assign(-1, to: bell+1)
//                            }
//                            
//                        }
//                    }) {
//                        Text("Fill In")
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 4)
//                            .lineLimit(1)
//                    }
//                    .background(Color.main.cornerRadius(5))
//                    .disabled(!fillInAvailable())
//                    .opacity(fillInAvailable() ? 1 : 0.35)
//                    .foregroundColor(.white)
//                    
//                    Button(action: {
//                        for i in 0..<viewModel.size {
//                            self.unAssign(bell: i+1)
//                        }
//                    }) {
//                        Text("Unassign all")
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 4)
//                            .foregroundColor(.white)
//                            .background(Color.main.cornerRadius(5))
//                            .lineLimit(1)
//                    }
//                    
//                }
//                Spacer()
//                
//                Button(action: {
//                    viewModel.towerControlsViewSelection = .chat
//                }) {
//                    Text("Chat")
//                    Image(systemName: "chevron.right")
//                }
//                .foregroundColor(.main)
//        
//            }
//
//            ScrollView(showsIndicators: false) {
//                
//                HStack(alignment: .top) {
//                    VStack(spacing: 14) {
//                        ForEach(viewModel.users) { user in
//                            RingerView(user: user, selectedUser: (self.selectedUser == user.ringerID))
//                                .opacity(self.available() ? 1 : (user.ringerID == self.selectedUser) ? 1 : 0.35)
//                                .onTapGesture(perform: {
//                                    if self.available() {
//                                        self.selectedUser = user.ringerID
//                                    }
//                                })
//                            
//                        }
//                    }
//                    .fixedSize(horizontal: false, vertical: true)
//                    .padding(.top, 10)
//                    VStack(alignment: .trailing, spacing: 7) {
//                        ForEach(0..<viewModel.assignments.count, id: \.self) { number in
//                            HStack(alignment: .center, spacing: 5) {
//                                if self.canUnassign(number)  {
//                                    Button(action: {
//                                        self.unAssign(bell: number+1)
//                                        self.updateView.toggle()
//                                    }) {
//                                        Text("X")
//                                            .foregroundColor(.primary)
//                                            .font(.title3)
//                                            .fixedSize()
//                                            .padding(.vertical, -4)
//                                    }
//                                    //                                        .background(Color.green)
//                                }
//                                Button(action: {
//                                    assign(selectedUser, to: number + 1)
//                                }) {
//                                    ZStack {
//                                        ZStack {
//                                            Circle().fill(Color.main)
//                                            
//                                            Text("1")
//                                                .font(.callout)
//                                                .bold()
//                                                .opacity(0)
//                                                .padding(.horizontal, 10)
//                                                .padding(.vertical, 4)
//                                        }
//                                        //                                            .fixedSize()
//                                        
//                                        
//                                        Text(String(number + 1))
//                                            .font(.callout)
//                                            .bold()
//                                            .foregroundColor(Color.white)
//                                        
//                                    }
//                                    .fixedSize()
//                                }
//                                .disabled(!(viewModel.assignments[number] == nil))
//                                .opacity((viewModel.assignments[number] == nil) ? 1 : 0.35)
//                                .animation(.linear(duration: 0.15))
//                                .fixedSize(horizontal: true, vertical: true)
//                                //.background(.black)
//                            }
//                        }
//                        
//                        
//                    }
//                    .padding(.vertical, 6)
//                    .padding(.horizontal, 6)
//                    .background(Color(white: (self.colorScheme == .light) ? 0.86 : 0.13).cornerRadius(5))
//                }
//            }
//            //                .padding(.top, 2)
//            .padding(.horizontal, 7)
//            //            }
//        }
//        .onChange(of: viewModel.ringer, perform: { ringer in
//            selectedUser = ringer!.ringerID
//        })
//        .clipped()
//        .padding(7)
//        .background(isSplit ? Color(white: colorScheme == .light ? 1 : 0.08).cornerRadius(5) : Color(white: colorScheme == .light ? 0.94 : 0.08).cornerRadius(5))
//        .onDisappear {
//            print("users view disappeared")
//        }
//    }
//    
//    func canUnassign(_ number:Int) -> Bool {
//        if viewModel.assignments.count == viewModel.size {
//            return (viewModel.assignments[number] != nil) && (self.available() || viewModel.assignments[number]?.name ?? "" == viewModel.user.username)
//        } else {
//            return false
//        }
//    }
//    
//    func available() -> Bool {
//        return viewModel.towerInfo.isHost || !viewModel.hostMode
//    }
//    
//    func assign(_ id: Int, to bell: Int) {
//        viewModel.send(event: "c_assign_user", with: ["user":id, "bell":bell, "tower_id": viewModel.towerInfo.towerID])
//    }
//    
//    func unAssign(bell:Int) {
//        print("unassigning")
//        viewModel.send(event: "c_assign_user", with: ["user": 0, "bell":bell, "tower_id": viewModel.towerInfo.towerID])
//    }
//    
//    func fillInAvailable() -> Bool {
//        if numberOfAvailableBells() <= 0 {
//            return false
//        } else {
//            if viewModel.users.contains(Ringer.wheatley) {
//                return true
//            } else {
//                return numberOfAvailableRingers() >= numberOfAvailableBells()
//            }
//        }
//    }
//    
//    func numberOfAvailableRingers() -> Int {
//        var number = 0
//        for ringer in viewModel.users {
//            if !viewModel.assignments.contains(ringer) {
//                number += 1
//            }
//        }
//        return number
//    }
//    
//    func numberOfAvailableBells() -> Int {
//        return viewModel.assignments.filter({ $0 == nil}).count
//    }
//    
//    
//}
