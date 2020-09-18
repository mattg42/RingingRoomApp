//
//  RingView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import Combine

struct RingView: View {
    
//    init() {
//         UIScrollView.appearance().bounces = false
//    }
    
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    @State var comController:CommunicationController!

    @State var towerListSelection:Int = 0
    var towerLists = ["Recents", "Favourites", "Created", "Host"]

        
    @State var showingAlert = false
    @State var alertTitle = Text("")
    @State var alertMessage:Text? = nil
    
    @ObservedObject var user = User.shared
    
    @State var ringingRoomView:RingingRoomView = RingingRoomView(towerName: "", serverURL: "")
    
    @State var joinTowerYPosition:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    
    @State var viewOffset:CGFloat = 0
    @State var textFieldSelected = false
    
    @State var isRelevant = false
    
    var body: some View {
        VStack(spacing: 20) {
            
//            Picker("Tower list selection", selection: $towerListSelection) {
//                ForEach(0 ..< towerLists.count) {
//                    Text(self.towerLists[$0])
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
            ScrollView {
                VStack {
//                    if User.shared.myTowers[0].tower_id != 0 {
                        ForEach(User.shared.myTowers) { tower in

                            if tower.tower_id != 0 {
                                Button(action: {self.user.savedTowerID = String(tower.tower_id)}) {
                                    Text(String(tower.tower_id))
                                        .towerButtonStyle(isSelected: (String(tower.tower_id) == self.user.savedTowerID), name: tower.tower_name)
                                }
                                .frame(height: 40)
                                .padding(.horizontal)
                                .buttonStyle(CustomButtonStyle())
                                .cornerRadius(10)
                            } else {
                                /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
                            }
                            //                        .contextMenu {
                            //                            Button(action: {
                            //                                print("")
                            //                            }) {
                            //                                HStack {
                            //                                    Image(systemName: "bookmark")
                            //                                    Text("Favourite")
                            //                                }
                            //                            }
                            //
                            //                            Button(action: {
                            //                                print("")
                            //                            }) {
                            //                                HStack {
                            //                                    Image(systemName: "gear")
                            //                                    Text("Settings")
                            //                                }
                            //                            }
                            //
                            //                            Button(action: {
                            //                                print("")
                            //                            }) {
                            //                                Image(systemName: "minus.circle")
                            //                                    .accentColor(.red)
                            //                                Text("Remove")
                            //                            }
                            //                        }
                        }
//                    }
                }
            }
            HStack {
                TextField("Tower name or id", text: .init(get: {
                    return self.user.savedTowerID
                }, set: { newValue in
                    if self.user.savedTowerID != newValue {
                       self.user.savedTowerID = newValue
                    }
                }), onEditingChanged: { selected in
                    self.textFieldSelected = selected
                    print(User.shared.myTowers.count)
                })
                .disabled(!User.shared.loggedIn)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Hide keyboard") {
                    self.hideKeyboard()
                }
                .foregroundColor((keyboardHeight > 0) ? Color.main : Color.secondary)
                .opacity((keyboardHeight > 0) ? 1 : 0.4)
                .disabled(keyboardHeight == 0)
            }
            GeometryReader { geo in
                Button(action: self.joinTower) {
                    ZStack {
                        Color.main
                            .cornerRadius(5)
                        Text(!User.shared.loggedIn ? "Please log in to join or create a tower" : self.isID(str: self.user.savedTowerID) ? "Join Tower" : "Create Tower")
                            .foregroundColor(.white)
                    }
                }
                .opacity(!User.shared.loggedIn ? 0.35 : !(self.user.savedTowerID.count == 0) ? 1 : 0.35)
                .disabled(!User.shared.loggedIn ? true : self.user.savedTowerID.count == 0)
                .onAppear(perform: {
                    var pos = geo.frame(in: .global).midY
                    pos += geo.frame(in: .global).height/2 + 10
                    print("pos", pos)
                    pos = UIScreen.main.bounds.height - pos
                    self.joinTowerYPosition = pos
                })
                    .alert(isPresented: self.$showingAlert) {
                        Alert(title: self.alertTitle, message: self.alertMessage, dismissButton: .cancel(Text("OK")))
                }
            }
            .frame(height: 45)
            .fixedSize(horizontal: false, vertical: true)
            
        }
        .onAppear(perform: {
            if self.user.savedTowerID == ""  && (User.shared.myTowers[0].tower_id) != 0 {
                if self.user.loggedIn {
                    self.user.savedTowerID = String(User.shared.myTowers[0].tower_id)
                }
            }
            self.comController = CommunicationController(sender: self)
        })
            .padding()
            .offset(y: viewOffset)
            .onReceive(Publishers.keyboardHeight) {
                self.keyboardHeight = $0
                print(self.keyboardHeight)
                let offset = self.keyboardHeight - self.joinTowerYPosition
                print("offset: ",offset)
                if offset <= 0 {
                    withAnimation(.easeIn(duration: 0.16)) {
                        self.viewOffset = 0
                    }
                } else {
                    if self.textFieldSelected {
                        withAnimation(.easeOut(duration: 0.16)) {
                            self.viewOffset = -offset
                        }
                    }
                }
        }
        
    }
    
    func getOffset() -> CGFloat {
        
        let offset = keyboardHeight - joinTowerYPosition
        print("offset: ",offset)
        if offset <= 0 {
            return 0
        } else {
            return -offset
        }
    }
    
    func isID(str:String) -> Bool {
        if str.count == 9 {
            if Int(str) != nil {
                return true
            }
        }
        return false
    }
    
    func joinTower() {
        if isID(str: self.user.savedTowerID) {
            self.getTowerConnectionDetails()
            return
        }
        
        //create new tower
        comController.createTower(name: self.user.savedTowerID)
        
        
    }
    
    func getTowerConnectionDetails() {
        comController.getTowerDetails(id: Int(self.user.savedTowerID)!)
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
//        print(statusCode)
        if statusCode == 404 {
            self.alertTitle = Text("There is no tower with that ID")
            self.showingAlert = true
        } else {
        
            self.ringingRoomView.setupComplete = false
            self.ringingRoomView.serverURL = response["server_address"]! as! String
            self.ringingRoomView.towerName = response["tower_name"]! as! String
            BellCircle.current.towerID = response["tower_id"]! as! Int
            
            DispatchQueue.main.async {
                self.viewControllerHolder?.present(style: .fullScreen, name: "RingingRoom") {
                    self.ringingRoomView
                }
            }
        }
    }
    
}

struct towerButtonModifier:ViewModifier {
    var isSelected:Bool
    var name:String
    
    func body(content: Content) -> some View {
            HStack() {
                Text(name)
                .fontWeight(isSelected ? Font.Weight.bold : nil)
                content
                Spacer()
            }
            .foregroundColor(isSelected ? .main : Color.primary)
    }
}

struct CustomButtonStyle:ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .opacity(1)
        .contentShape(Rectangle())
    }
}

extension View {
    func towerButtonStyle(isSelected:Bool, name:String) -> some View {
        self.modifier(towerButtonModifier(isSelected: isSelected, name: name))
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
