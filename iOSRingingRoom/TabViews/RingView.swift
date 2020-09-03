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
    
    @State var towerListSelection:Int = 0
    var towerLists = ["Recents", "Favourites", "Created", "Host"]
    var recentTowers = [Tower(id: "123456789", name: "Goodship"), Tower(id: "215436789", name: "Test"), Tower(id: "918273645", name: "3ls"), Tower(id: "263451789", name: "Lancashire branch"), Tower(id: "564738921", name: "Peal"), Tower(id: "873456129", name: "Practice"), Tower(id: "283719465", name: "Striking"), Tower(id: "178625439", name: "Silverdale"), Tower(id: "123456789", name: "Goodship"), Tower(id: "215436789", name: "Test"), Tower(id: "918273645", name: "3ls"), Tower(id: "263451789", name: "Lancashire branch"), Tower(id: "564738921", name: "Peal"), Tower(id: "873456129", name: "Practice"), Tower(id: "283719465", name: "Striking"), Tower(id: "178625439", name: "Silverdale")]
    @State var tower_id = "891234567"
        
    @State var selectedTower = 0
    
    @State var ringingRoomView:RingingRoomView = RingingRoomView(id: 0, towerName: "", serverURL: "")
    
    @State var joinTowerYPosition:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    
    @State var viewOffset:CGFloat = 0
    @State var textFieldSelected = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            Picker("Tower list selection", selection: $towerListSelection) {
                ForEach(0 ..< towerLists.count) {
                    Text(self.towerLists[$0])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            ScrollView() {
                    ForEach(0..<recentTowers.count) { number in
                        Button(action: {self.tower_id = self.recentTowers[number].id; self.selectedTower = number}) {
                            Text(self.recentTowers[number].id)
                            .towerButtonStyle(isSelected: (number == self.selectedTower), name: self.recentTowers[number].name)
                        }
                        .frame(height: 40)
                            .padding(.horizontal)
                        .buttonStyle(CustomButtonSyle())
                        .cornerRadius(10)
                        .contextMenu {
                            Button(action: {
                                print("")
                            }) {
                                HStack {
                                    Image(systemName: "bookmark")
                                    Text("Favourite")
                                }
                            }

                            Button(action: {
                                print("")
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Settings")
                                }
                            }

                            Button(action: {
                                print("")
                            }) {
                                    Image(systemName: "minus.circle")
                                        .accentColor(.red)
                                    Text("Remove")
                            }
                    }

                }
            }
            HStack {
                TextField("Tower id", text: self.$tower_id, onEditingChanged: { selected in
                    self.textFieldSelected = selected
                })
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
                        Text("Join Tower")
                            .foregroundColor(.white)
                    }
                }
                .opacity((self.tower_id.count == 9) ? 1 : 0.35)
                .disabled(!(self.tower_id.count == 9))
                    .onAppear(perform: {
                        var pos = geo.frame(in: .global).midY
                        pos += geo.frame(in: .global).height/2 + 10
                        print("pos", pos)
                        pos = UIScreen.main.bounds.height - pos
                        self.joinTowerYPosition = pos
                    })
            }
                .frame(height: 45)
            .fixedSize(horizontal: false, vertical: true)
            
        }
        .padding()
        .offset(y: viewOffset).onReceive(Publishers.keyboardHeight) {
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
    
    func joinTower() {
        if tower_id.count == 9 {
            if Int(tower_id) != nil {
                self.getTowerConnectionDetails()
            }
        }
        
        //create new tower
        
        
    }
    
    func getTowerConnectionDetails() {
        CommunicationController.getTowerDetails(id: Int(self.tower_id)!, sender: self)
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        
        self.ringingRoomView.setupComplete = false
        
        self.ringingRoomView.serverURL = response["server_address"]! as! String
        self.ringingRoomView.towerName = response["tower_name"]! as! String
        self.ringingRoomView.id = response["tower_id"]! as! Int
        
        DispatchQueue.main.async {
            self.viewControllerHolder?.present(style: .fullScreen, name: "RingingRoom") {
                self.ringingRoomView
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

struct CustomButtonSyle:ButtonStyle {
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
