//
//  MainApp.swift
//  iOSRingingRoom
//
//  Created by Matthew on 06/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import SocketIO

struct MainApp: View {
    @State var bellNumber = 1
    @State var towerParameters = [String:Any]()

    @State var tower_id = ""
    
    @State var Manager:SocketIOManager!
    
    var body: some View {
        ZStack {
            //#d3d1dc
            Color(red: 211/255, green: 209/255, blue: 220/255)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 10) {
                TextField("Tower number", text: $tower_id)
                Button(action: connectToTower) {
                    Text("connect to tower")
                }
                
                Button(action: ringBell) {
                    
                    Text("ring")
                }.buttonStyle(touchDown())
    
                Stepper(value: $bellNumber, in: 1...8) {
                    Text("Bell selected: \(bellNumber)")
                        .font(.subheadline)
                    .padding(20)
                }
            }
        }
    }
    
    struct touchDown:PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration
            .label
                .onLongPressGesture(minimumDuration: 0) {
                    configuration.trigger()
                
            }
        }
    }
    
    func connectToTower() {
        getTowerParameters()
        do {
            usleep(1000000)
        }
        initializeManager()
        do {
            usleep(1000000)
        }
        initializeSocket()
        do {
            usleep(1000000)
        }
        joinTower()
    }
    
    func getTowerParameters() {
        let url = URL(string: "https://ringingroom.com/\(tower_id)")
        guard let requestUrl = url else { fatalError() }
        // Create URL Request
        var request = URLRequest(url: requestUrl)
        // Specify HTTP Method to use
        request.httpMethod = "GET"

        var initialTowerParameters = [String:Any]()
        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            // Check if Error took place
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            // Read HTTP Response Status code
            if let response = response as? HTTPURLResponse {
              //  print("Response HTTP Status code: \(response.statusCode)")
            }
            
            // Convert HTTP Response Data to a simple String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
               // print("Response data string:\n \(dataString)")
                
                //parse result for window.tower_parameters
                var towerParameterText = (dataString.components(separatedBy: "window.tower_parameters = {")[1]).components(separatedBy: "}")[0]
                
                //convert resulting string of tower_parameters to a dictionary

                //removing whitespace
                var parameterLines = towerParameterText.components(separatedBy: ",\n")
                for (index, line) in parameterLines.enumerated() {
                    var trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    parameterLines[index] = trimmedLine
                }
                parameterLines.removeLast()
                
                //adding all strings to a dictionary
                var dictLines = [[String]]()
                for (index, line) in parameterLines.enumerated() {
                    var newArr = line.components(separatedBy: ": ")
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
                            //remove the brackets, spaces and redundant quotes, then convert the remaining String to an Array
                            var newValue = stringValue
                            newValue.removeFirst()
                            newValue.removeLast()
                            newValue = newValue.replacingOccurrences(of: " '", with: "")
                            newValue = newValue.replacingOccurrences(of: "'", with: "")
                            var newArr = newValue.components(separatedBy: ",")
                            initialTowerParameters[key] = newArr
                        } else { // if all other checks fail, the parameter's value must be a string
                            //remove redundant quotes
                            var newValue = stringValue
                            newValue.removeFirst()
                            newValue.removeLast()
                            initialTowerParameters[key] = newValue
                        }
                    }
                    
                }
                print(initialTowerParameters)
            }
            
            self.towerParameters = initialTowerParameters
            
            
        }
        task.resume()
    }
    
    func initializeManager() {
        manager = SocketIOManager(server_ip: towerParameters["server_ip"] as! String)
        
    }
    
    func initializeSocket() {
        manager.addListeners()
        manager.connectSocket()
        manager.getStatus()
    }
    
    func joinTower() {
        manager.socket.emit("c_join", ["tower_id":towerParameters["id"],"user_token":towerParameters["user_token"],"anonymous_user":towerParameters["anonymous_user"]])
        print("hopefully joined tower")
    }
    
    func ringBell() {
        print(bellNumber)
        manager.socket.emit("c_bell_rung", ["bell": bellNumber, "stroke": "handstroke", "tower_id": towerParameters["id"]])
        print("hopefully rang bell")
    }
    
}
