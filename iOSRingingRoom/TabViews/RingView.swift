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
    
    init() {
         UIScrollView.appearance().bounces = false

    }
    
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
            RingingRoomView(towerParameters: getTowerParameters(), tower_id: tower_id)
        }
    }
    
    func getTowerParameters() -> TowerParameters {
        let url = URL(string: "https://ringingroom.com/\(tower_id)")
        guard let requestUrl = url else { fatalError() }
        // Create URL Request
        var request = URLRequest(url: requestUrl)
        // Specify HTTP Method to use
        request.httpMethod = "GET"
        
        var requestComplete = false
        
        var towerParameters:TowerParameters? = nil
        
        var initialTowerParameters = [String:Any]()
        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check if Error took place
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            //            // Read HTTP Response Status code
            //            if let response = response as? HTTPURLResponse {
            //                //  print("Response HTTP Status code: \(response.statusCode)")
            //            }
            
            // Convert HTTP Response Data to a simple String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                // print("Response data string:\n \(dataString)")
                
                //parse result for window.tower_parameters
                let towerParameterText = (dataString.components(separatedBy: "window.tower_parameters = {")[1]).components(separatedBy: "}")[0]
                
                //convert resulting string of tower_parameters to a dictionary
                
                //removing whitespace
                var parameterLines = towerParameterText.components(separatedBy: ",\n")
                for (index, line) in parameterLines.enumerated() {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    parameterLines[index] = trimmedLine
                }
                parameterLines.removeLast()
                
                //adding all strings to a dictionary
                var dictLines = [[String]]()
                for (_, line) in parameterLines.enumerated() {
                    let newArr = line.components(separatedBy: ": ")
                    dictLines.append(newArr)
                }
                
                for line in dictLines {
                    initialTowerParameters[line[0]] = line[1]
                }
                                
                //converting all the strings to their actual value
                for (key, value) in initialTowerParameters {
                    if let stringValue = value as? String {
                        if stringValue == "false" { //if the parameter's value is false
                            initialTowerParameters[key] = false
                        } else if stringValue == "true" { //if the parameter's value is true
                            initialTowerParameters[key] = true
                        } else if stringValue.contains("parseInt") { //if the parameter's value is an Tnt
                            //remove 'parseInt(...)' text, then convert the number to an Int
                            var newValue = stringValue
                            let firstIndex = newValue.index(newValue.startIndex, offsetBy: 9)
                            let endIndex = newValue.index(newValue.endIndex, offsetBy: -1)
                            newValue = String(newValue[firstIndex..<endIndex])
                            initialTowerParameters[key] = Int(newValue)
                        } else if stringValue.contains("[") { //if the parameter's value is an Array
                            //remove the brackets, spaces and extra quotes, then convert the remaining String to an Array
                            var newValue = stringValue
                            newValue.removeFirst()
                            newValue.removeLast()
                            newValue = newValue.replacingOccurrences(of: " '", with: "")
                            newValue = newValue.replacingOccurrences(of: "'", with: "")
                            let newArr = newValue.components(separatedBy: ",")
                            initialTowerParameters[key] = newArr
                        } else { // if all other checks fail, the parameter's value must be a string
                            //remove extra quotes
                            var newValue = stringValue
                            newValue.removeFirst()
                            newValue.removeLast()
                            initialTowerParameters[key] = newValue
                        }
                    }
                    
                }
                //converting the dictionary of towerparameters to an object
           //     print(initialTowerParameters)
                var dictString = initialTowerParameters.description
                dictString.removeLast()
                dictString.removeFirst()
                dictString.insert("{", at: dictString.startIndex)
                dictString.append("}")
                
                let jsonData = Data(dictString.utf8)
                let decoder = JSONDecoder()
                do {
                    towerParameters = try decoder.decode(TowerParameters.self, from: jsonData)
                } catch {
                    print(error.localizedDescription)
                }
                requestComplete = true
            }
            
        }
        task.resume()
        
        while !requestComplete {

        }
        
        print(towerParameters!.size)
        return towerParameters!
        
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
