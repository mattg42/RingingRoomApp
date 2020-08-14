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
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    @State var towerListSelection:Int = 0
    var towerLists = ["Recents", "Favourites", "Created", "Host"]
    var recentTowers = [Tower(id: "123456789", name: "Goodship"), Tower(id: "215436789", name: "Test"), Tower(id: "918273645", name: "3ls"), Tower(id: "263451789", name: "Lancashire branch"), Tower(id: "564738921", name: "Peal"), Tower(id: "873456129", name: "Practice"), Tower(id: "283719465", name: "Striking"), Tower(id: "178625439", name: "Silverdale")]
    @State var tower_id = "254317968"
    
    @State var selectedTower = 0
    
    @State var towerIDFieldYPosition:CGFloat = 0
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
            VStack {
                ForEach(0..<recentTowers.count) { number in
                    Button(action: {self.tower_id = self.recentTowers[number].id; self.selectedTower = number}) {
                        Text(self.recentTowers[number].id)
                        .towerButtonStyle(isSelected: (number == self.selectedTower), name: self.recentTowers[number].name)
 
                    }
                    .frame(height: 32)
                .buttonStyle(CustomButtonSyle())
                }
            }
            Spacer()
            HStack {
                GeometryReader { geo in
                    TextField("Tower id", text: self.$tower_id, onEditingChanged: { selected in
                        self.textFieldSelected = selected
                    })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onAppear(perform: {
                            var pos = geo.frame(in: .global).midY
                            pos += geo.frame(in: .global).height*2
                            pos = UIScreen.main.bounds.height - pos
                            self.towerIDFieldYPosition = pos
                        })
                }
                .fixedSize(horizontal: false, vertical: true)
                Button("Hide keyboard") {
                    self.hideKeyboard()
                }
                .opacity((keyboardHeight > 0) ? 1 : 0.4)
                .disabled(keyboardHeight == 0)
            }
            Button(action: joinTower) {
                ZStack {
                    Color.main
                        .cornerRadius(5)
                    Text("Join Tower")
                        .foregroundColor(.white)
                }
            }
            .frame(height: 45)
            .opacity((tower_id.count == 9) ? 1 : 0.35)
            .disabled(!(tower_id.count == 9))
        }
        .padding()
        .offset(y: viewOffset)
        .onReceive(Publishers.keyboardHeight) {
            self.keyboardHeight = $0
            print(self.keyboardHeight)
            let offset = self.keyboardHeight - self.towerIDFieldYPosition
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
        
        let offset = keyboardHeight - towerIDFieldYPosition
        print("offset: ",offset)
        if offset <= 0 {
            return 0
        } else {
            return -offset
        }
    }
    
    func joinTower() {
        self.viewControllerHolder?.present(style: .fullScreen, name: "RingingRoom") {
            RingingRoomView(tower_id: tower_id)
        }
    }
    
    
}

struct towerButtonModifier:ViewModifier {
    var isSelected:Bool
    var name:String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            Color.main
                .opacity(isSelected ? 1 : 0)
                .cornerRadius(5)
            HStack() {
                Text(name)
                .fontWeight(isSelected ? Font.Weight.bold : nil)
                content
            }
            .padding(.horizontal)
            .foregroundColor(isSelected ? .white : Color.primary)
        }
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
