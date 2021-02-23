//
//  CommunicationController.swift
//  iOSRingingRoom
//
//  Created by Matthew on 31/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation

class CommunicationController {
    
    static var token:String? = nil
    
    var loginType:LoginType? = nil
    
    var sender:Any
    
    static var baseUrl = UserDefaults.standard.bool(forKey: "useDevServer") ? "https:/dev.ringingroom.com/api/" : "https:/ringingroom.com/api/"
    
    init(sender:Any, loginType:LoginType? = nil) {
        self.sender = sender
        self.loginType = loginType
    }
    
    func sendRequest(method:String, endpoint:String, headers:[String:String]? = nil, json:[String:String]? = nil, type:RequestType, towerID:Int = 0) {
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
            var towersDict = [String:[String:Any]]()
//            print(data)
            // Convert HTTP Response Data to a simple String

            if let data = data {
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Http response")
                    print(dataString)
                }
                // print("Response data string:\n \(dataString)")
                
                do {
                    if type == .getMyTowers {
                        towersDict = try JSONSerialization.jsonObject(with: data) as! [String : [String : Any]]
                    } else {
                        dataDict = try JSONSerialization.jsonObject(with: data) as! [String : Any]
                    }
                } catch {
                    print("error converting response to a dictionary")
                }
            }
            
            print(dataDict)
            
            switch type {
            case .loginAttempt:
                if let token = dataDict["token"] as? String {
                    CommunicationController.token = token
                    User.shared.loggedIn = true
                }
                switch self.loginType {
                case .auto:
                    (self.sender as! AutoLogin).receivedResponse(statusCode: statusCode, response: dataDict)
                case .welcome:
                    (self.sender as! WelcomeLoginScreen).receivedResponse(statusCode: statusCode, responseData: dataDict)
                case .simple:
                    (self.sender as! SimpleLoginView).receivedResponse(statusCode: statusCode, responseData: dataDict)
                case .settings:
                    (self.sender as! SettingsView).receivedResponse(statusCode: statusCode, responseData: dataDict)
                default:
                    print("not login")
//                case .none:
//                    (self.sender as! RingView).updatedMyTowers()
                }
//            case .logout:
                
            case .getUserDetails:
                User.shared.name = dataDict["username"] as! String
                User.shared.email = dataDict["email"] as! String
            case .registerNewUser:
                (self.sender as! AccountCreationView).receivedResponse(statusCode: statusCode, response: dataDict)
//            case .modifyUserDetails:
//            case .deleteUser:
            case .getMyTowers:
//                for dict in dataDict {
//                    print(dict.value)
//                    do {
//                        var tempDict = [String:Any]()
//                        tempDict = try JSONSerialization.jsonObject(with: dict.value as! Data) as! [String : Any]
//                        towersDict[dict.key] = tempDict
//                    } catch {
//                        "error converting response to a dictionary"
//                    }
//                }
                DispatchQueue.main.async {
                    User.shared.myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
                    User.shared.firstTower = true
                    print("added towers")
                    for dict in towersDict {
                        print(dict)
                        if dict.key != "0" {
                            var tower = Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)
                            if let id = dict.value["tower_id"] as? Int {
                                tower = Tower(id: id, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
                            } else {
                                tower = Tower(id: Int(dict.value["tower_id"] as! String)!, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)

                            }
                            tower.inMyTowers = true
                            User.shared.addTower(tower)
                        }
                    }
                    print(User.shared.myTowers.names)
                    User.shared.sortTowers()
                    
                }
                
                
                switch self.loginType {
                case .auto:
                    (self.sender as! AutoLogin).receivedMyTowers(statusCode: statusCode, response: dataDict)
                case .welcome:
                    (self.sender as! WelcomeLoginScreen).receivedMyTowers(statusCode: statusCode, responseData: dataDict)
                case .simple:
                    (self.sender as! SimpleLoginView).receivedMyTowers(statusCode: statusCode, responseData: dataDict)
                case .settings:
                    (self.sender as! SettingsView).receivedMyTowers(statusCode: statusCode, responseData: dataDict)
                default:
                    if let sender = self.sender as? SocketIOManager {
                        sender.gotMyTowers()
                    }
                    print("not login")
//                case nil:
//                    (self.sender as! RingView).updatedMyTowers()
                }
            //    {"928134567": {"bookmark": 0,"creator": 1,"host": 1,"recent": 1,"tower_id": 928134567,"tower_name": "Advent","visited": "Mon, 31 Aug 2020 15:45:54 GMT"}, "987654321": {"bookmark": 0,"creator": 0,"host": 0,"recent": 1,"tower_id": 987654321,"tower_name": "Old North","visited": "Mon, 31 Aug 2020 15:44:40 GMT"}}
                
//            case .toggleBookmark:
//            case .deleteTowerFromRecents:
            case .connectToTower:
                (self.sender as! RingView).receivedResponse(statusCode: statusCode, response: dataDict)
            case .createTower:
                self.getTowerDetails(id: dataDict["tower_id"] as! Int)
//            case .deleteTower:
            case .getTowerSettings:
                let tower = User.shared.myTowers.towerForID(towerID)!
                tower.hostModePermitted = dataDict["host_mode_enabled"] as? Bool ?? false
                tower.additionalSizes = dataDict["additional_sizes_enabled"] as? Bool ?? true
                tower.gotSettings = true
                if let ringView = self.sender as? RingView {
                    ringView.receivedTowerSettings(id: tower.tower_id)
                } else {
                    SocketIOManager.shared.receivedTowerSettings(id: tower.tower_id)
                }
//            case .modifyTowerSettings:
//            case .addHost:
//            case .removeHost:
            default:
                return
            }
        }
        task.resume()
    }
    
    func login(email:String, password:String) {
        let utf8str = "\(email.lowercased()):\(password)".data(using: .utf8)
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            print("Encoded: \(base64Encoded)")
            sendRequest(method: "POST", endpoint: "tokens", headers: ["Authorization":"Basic \(base64Encoded)"], type: .loginAttempt)
        }
    }
    
    func registerNewUser(username:String, email:String, password:String) {
        let json = ["password":password, "username":username, "email":email]
        
        sendRequest(method: "POST", endpoint: "user", json: json, type: .registerNewUser)
    }
    
    func getTowerDetails(id:Int) {
        let headers = ["Authorization":"Bearer \(CommunicationController.token!)"]
        
        sendRequest(method: "GET", endpoint: "tower/\(id)", headers: headers, type: .connectToTower)
    }
    
    func getUserDetails() {
        let headers = ["Authorization":"Bearer \(CommunicationController.token!)"]
        sendRequest(method: "GET", endpoint: "user", headers: headers, type: .getUserDetails)
    }
    
    func createTower(name:String) {
        let headers = ["Authorization":"Bearer \(CommunicationController.token!)"]
        let json = ["tower_name":name]
        
        sendRequest(method: "POST", endpoint: "tower", headers: headers, json: json, type: .createTower)
    }
    
    func getMyTowers() {
        let headers = ["Authorization":"Bearer \(CommunicationController.token!)"]
        
        sendRequest(method: "GET", endpoint: "my_towers", headers: headers, type: .getMyTowers)
    }
    
    func getTowerSettings(id: Int) {
        let headers = ["Authorization":"Bearer \(CommunicationController.token!)"]
        
        sendRequest(method: "GET", endpoint: "tower/\(id)/settings", headers: headers, type: .getTowerSettings, towerID: id)
    }
    
}

enum RequestType {
    case welcomeLoginAttempt, loginAttempt, autoLoginAttempt, logout, getUserDetails, registerNewUser, modifyUserDetails, deleteUser
    case getMyTowers, toggleBookmark, deleteTowerFromRecents
    case connectToTower, createTower, deleteTower, getTowerSettings, modifyTowerSettings, addHost, removeHost
}

enum LoginType {
    case auto, welcome, simple, settings
}
