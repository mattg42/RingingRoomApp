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
    
    @State private var comController:CommunicationController!

    @State private var towerListSelection:Int = 0
    var towerLists = ["Recents", "Favourites", "Created", "Host"]
    
    @State private var showingAlert = false
    @State private var alertTitle = Text("")
    @State private var alertMessage:Text? = nil
    
    @ObservedObject var user = User.shared
    
    @State private var ringingRoomView = RingingRoomView()
    
    @State var presentingRingingRoomView = false
    
    @State private var joinTowerYPosition:CGFloat = 0
    @State private var keyboardHeight:CGFloat = 0
    
    @State private var viewOffset:CGFloat = 0
    
    @State private var isRelevant = false
    
    @State var sink:AnyCancellable!
    
    @State var response = [String:Any]()
    
    var body: some View {
        VStack(spacing: 20) {
//            Picker("Tower list selection", selection: $towerListSelection) {
//                ForEach(0 ..< towerLists.count) {
//                    Text(self.towerLists[$0])
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
            ScrollView {
                ScrollViewReader { value in
                    VStack {
    //                    if User.shared.myTowers[0].tower_id != 0 {
                            ForEach(User.shared.myTowers) { tower in

                                if tower.tower_id != 0 {
                                    Button(action: {
                                        User.shared.towerID = String(tower.tower_id)
                                        UserDefaults.standard.set(String(tower.tower_id), forKey: "\(User.shared.email)savedTower")
                                    }) {
                                        HStack() {
                                            Text(String(tower.tower_name))
                                            .fontWeight((String(tower.tower_id) == User.shared.towerID) ? Font.Weight.bold : nil)
                                            Spacer()
                                        }
                                        .foregroundColor((String(tower.tower_id) == User.shared.towerID) ? .main : Color.primary)
//
//
//                                            .towerButtonStyle(isSelected: (String(tower.tower_id) == User.shared.towerID))
                                    }
                                    .frame(height: 40)
                                    .padding(.horizontal)
                                    .buttonStyle(CustomButtonStyle())
                                    .cornerRadius(10)
                                    .id(tower.tower_id)
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
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.gotMyTowers)) { _ in
                        value.scrollTo(user.myTowers.last!.tower_id)
                    }
                    .onAppear {
                        value.scrollTo(user.myTowers.last!.tower_id)
                    }
                }
            }
            TextField("Tower name or id", text: .init(
                        get: {
                            User.shared.towerID
                        },
                        set: {
                            UserDefaults.standard.set($0, forKey: "\(User.shared.email)savedTower")
                            User.shared.towerID = $0
                        }))
                    .disabled(!User.shared.loggedIn)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                .padding(.vertical, -10)
            GeometryReader { geo in
                Button(action: self.joinTower) {
                    ZStack {
                        Color.main
                            .cornerRadius(5)
                        Text(!User.shared.loggedIn ? "Please log in to join or create a tower" : self.isID(str: User.shared.towerID) ? "Join Tower" : "Create Tower")
                            .foregroundColor(.white)
                    }
                }
                .opacity(User.shared.loggedIn ? User.shared.towerID.count != 0 ? 1 : 0.35 : 0.35)
                .disabled((User.shared.loggedIn ? User.shared.towerID.count != 0 ? false : true : true))
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
            .padding(.bottom, -5)
            .frame(height: 45)
            .fixedSize(horizontal: false, vertical: true)
            
        }
        .onAppear(perform: {
            self.comController = CommunicationController(sender: self)
            sink = BellCircle.current.setupPublisher.sink { _ in
                print("received combine")
                if !BellCircle.current.ringingroomIsPresented {
                    print("checked values")
                    for (key, value) in BellCircle.current.setupComplete {
                        print(key, value)
                        if !value {
                            return
                        }
                    }
                    self.presentRingingRoomView()
                }
            }
        })
            .padding()

//        .onReceive(BellCircle.current.objectWillChange, perform: { _ in
//            
//        })
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
        print("joined tower")

        if isID(str: User.shared.towerID) {
            self.getTowerConnectionDetails()
            return
        }

        //create new tower
        comController.createTower(name: User.shared.towerID)
        
        
    }
    
    func getTowerConnectionDetails() {
        comController.getTowerDetails(id: Int(User.shared.towerID)!)
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        if statusCode == 404 {
            self.alertTitle = Text("There is no tower with that ID")
            self.showingAlert = true
        } else {
//            if user.myTowers.towerForID(response["tower_id"] as! Int) == nil {
//                self.response = response
//                comController.getMyTowers()
//            } else {
                BellCircle.current.towerName = response["tower_name"] as! String
                BellCircle.current.towerID = response["tower_id"] as! Int
                BellCircle.current.isHost = user.myTowers.towerForID(response["tower_id"] as! Int)?.host ?? false
                
    //            comController.getHostModePermitted(BellCircle.current.towerID)
                SocketIOManager.shared.connectSocket(server_ip: response["server_address"] as! String)
//            }
        }
    }
    
    func updatedMyTowers() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("gotMyTowers"), object: nil)
        }
    }
    
    func presentRingingRoomView() {
        if BellCircle.current.ringingroomIsPresented == false {
            comController.getMyTowers()
            DispatchQueue.main.async {
                self.viewControllerHolder?.present(style: .fullScreen, name: "RingingRoom") {
                    self.ringingRoomView
                }
            }
        }
    }
    
}

struct CustomButtonStyle:ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .opacity(1)
        .contentShape(Rectangle())
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension Notification.Name {
    static let gotMyTowers = Notification.Name("gotMyTowers")
}
