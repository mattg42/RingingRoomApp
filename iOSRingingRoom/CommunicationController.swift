//
//  CommunicationController.swift
//  iOSRingingRoom
//
//  Created by Matthew on 31/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

class CommunicationController {
    
    static var loginScreen:LoginScreen? = nil
    
    static var ringingRoomView:RingingRoomView? = nil
    
    static var ringView:RingView? = nil
    
    static var settingsView:SettingsView? = nil
    
    static var accountCreationView:AccountCreationView? = nil
    
    static var token:String? = nil
    
    static func sendRequest(method:String, endpoint:String, headers:[String:String]? = nil, json:[String:String]? = nil, type:RequestType) {
        let baseUrl = "https:/dev.ringingroom.com/api/"
        
        // Create URL Request
        guard let requestUrl = URL(string: baseUrl+endpoint) else { return }
        
        var request = URLRequest(url: requestUrl)
        // Specify HTTP Method to use
        request.httpMethod = method
        
        if let requestHeaders = headers {
            for header in requestHeaders {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        
        
        print(request.allHTTPHeaderFields)
        
        if let jsonData = json {
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            do {
                print("happenning")
                request.httpBody = try JSONSerialization.data(withJSONObject: jsonData)
            } catch {
                print("conversion to json failed")
            }
        }
        
        var httpResponse = ""
        
        var requestComplete = false
        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check if Error took place
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            var statusCode:Int? = nil
            // Read HTTP Response Status code
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
                statusCode = response.statusCode
            }
            var dataDict = [String:Any]()
            // Convert HTTP Response Data to a simple String
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                // print("Response data string:\n \(dataString)")
                
                do {
                    dataDict = try JSONSerialization.jsonObject(with: data) as! [String : Any]
                } catch {
                    "error converting response to a dictionary"
                }
            }
            
            switch type {
            case .loginAttempt:
                self.token = dataDict["token"] as! String
                self.loginScreen?.receivedResponse(statusCode: statusCode, responseData: dataDict)
                CommunicationController.getUsername()
//            case .logout:
            case .getUserDetails:
                User.name = dataDict["username"] as! String
                User.email = dataDict["email"] as! String
//            case .registerNewUser:
//                self.accountCreationView?.receivedResponse(statusCode: statusCode, response: dataDict)
//            case .modifyUserDetails:
//            case .deleteUser:
//            case .getMyTowers:
//            case .toggleBookmark:
//            case .deleteTowerFromRecents:
            case .connectToTower:
                print(dataDict)
                self.ringView?.receivedResponse(statusCode: statusCode, response: dataDict)
//            case .createTower:
//            case .deleteTower:
//            case .getTowerSettings:
//            case .modifyTowerSettings:
//            case .addHost:
//            case .removeHost:
            default:
                return
            }
        }
        task.resume()
    }
    
    static func login(email:String, password:String, sender:LoginScreen) {
        self.loginScreen = sender
        
        let utf8str = "\(email):\(password)".data(using: .utf8)

        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            print("Encoded: \(base64Encoded)")
            sendRequest(method: "POST", endpoint: "tokens", headers: ["Authorization":"Basic \(base64Encoded)"], type: .loginAttempt)
        }
    }
    
    static func registerNewUser(username:String, email:String, password:String, sender:AccountCreationView) {
        self.accountCreationView = sender
        
       var json = ["password":password, "username":username, "email":email]
        
        sendRequest(method: "POST", endpoint: "user", json: json, type: .registerNewUser)
    }
    
    static func getTowerDetails(id:Int, sender:RingView) {
        self.ringView = sender
        
        var headers = ["Authorization":"Bearer \(self.token!)"]
        
        sendRequest(method: "GET", endpoint: "tower/\(id)", headers: headers, type: .connectToTower)
    }
    
    static func getUsername() {
        var headers = ["Authorization":"Bearer \(self.token!)"]
        sendRequest(method: "GET", endpoint: "user", headers: headers, type: .getUserDetails)
    }
    
}

enum RequestType {
    case loginAttempt, logout, getUserDetails, registerNewUser, modifyUserDetails, deleteUser
    case getMyTowers, toggleBookmark, deleteTowerFromRecents
    case connectToTower, createTower, deleteTower, getTowerSettings, modifyTowerSettings, addHost, removeHost
}
