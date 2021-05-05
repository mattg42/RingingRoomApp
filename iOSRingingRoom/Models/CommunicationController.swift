//
//  CommunicationController.swift
//  iOSRingingRoom
//
//  Created by Matthew on 31/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import Foundation
import Network

class APIRequest:Equatable {
    init(endpoint:String, method:HTTPMethod, headers:[String:String], json:[String:String]?, requiresAuth:Bool) {
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.json = json
        self.requiresAuth = requiresAuth
    }
    
    private(set) var headers:[String:String] = [:]
    var json: [String:String]? = nil
    var endpoint:String
    var method = HTTPMethod.get
    var requiresAuth = true
    
    func addValue(_ value:String, forHTTPHeaderField header:String) {
        headers[header] = value
    }
    
    var urlRequest: URLRequest {
        let url = "https:/\(NetworkManager.server)ringingroom.com/api/\(endpoint)"
        var request = URLRequest(url: URL(string: url)!)
        
        request.httpMethod = method.rawValue
        
        if requiresAuth {
            request.addValue("Bearer \(NetworkManager.token!)", forHTTPHeaderField: "Authorization")
        }
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        if let json = json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: json)
            } catch {
                print(error)
            }
        }
        
        return request
    }
    
    static var error:APIRequest {
        return APIRequest(endpoint: "error", method: .get, headers: [:], json: nil, requiresAuth: false)
    }
    
    static func ==(lhs: APIRequest, rhs: APIRequest) -> Bool {
        return lhs.endpoint == rhs.endpoint
    }
}


extension APIRequest {
    static func login(email: String, password: String) -> APIRequest {
        let utf8str = "\(email.lowercased()):\(password)".data(using: .utf8)
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            let request = APIRequest(endpoint: "tokens", method: .post, headers: ["Authorization":"Basic \(base64Encoded)"], json: nil, requiresAuth: false)
            return request
        } else {
            return APIRequest.error
        }
    }
    
    static func registerNewUser(username:String, email:String, password:String) -> APIRequest {
        return APIRequest(endpoint: "user", method: .post, headers: [:], json: ["password":password, "username":username, "email":email], requiresAuth: false)
    }
    
    static func getTowerDetails(id:Int) -> APIRequest {
        return APIRequest(endpoint: "tower/\(id)", method: .get, headers: [:], json: nil, requiresAuth: true)
        
    }
    
    static func getUserDetails() -> APIRequest {
        return APIRequest(endpoint: "user", method: .get, headers: [:], json: nil, requiresAuth: true)
    }
    
    static func createTower(name:String) -> APIRequest {
        return APIRequest(endpoint: "tower", method: .post, headers: [:], json: ["tower_name":name], requiresAuth: true)
    }
    
    static func getMyTowers() -> APIRequest {
        return APIRequest(endpoint: "my_towers", method: .get, headers: [:], json: nil, requiresAuth: true)
    }
    
    static func resetPassword(email: String) -> APIRequest {
        return APIRequest(endpoint: "user/reset_password", method: .post, headers: [:], json: ["email":email], requiresAuth: false)
    }
    
    static func changeUserSetting(change:[String:String], setting:UserSetting) -> APIRequest {
        return APIRequest(endpoint: "user", method: .put, headers: [:], json: change, requiresAuth: true)
    }
    
    static func deleteAccount() -> APIRequest {
        return APIRequest(endpoint: "user", method: .del, headers: [:], json: nil, requiresAuth: true)
        
    }
}



enum TestError: Error {
    case failedToConvert
}

class NetworkManager {
    
    static var server = ""
    static var token:String? = nil
    static func sendRequest(request: APIRequest, completion: @escaping ([String:Any]?, HTTPURLResponse?, Error?) -> ()) {
        guard request != APIRequest.error else { return }
        let urlRequest = request.urlRequest
        
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
            let json = convertToJson(data)
            completion(json, response as? HTTPURLResponse, error)
        })
        task.resume()
    }
    
}
func convertToJson(_ data:Data?) -> [String:Any]? {
    if let data = data {
        do {
            return try JSONSerialization.jsonObject(with: data) as? [String : Any]
        } catch {
            return nil
        }
    } else {
        return nil
    }
}
enum HTTPMethod: String {
    case get = "GET",
         del = "DELETE",
         put = "PUT",
         post = "POST"
}


class NetworkStatus {
    static let shared = NetworkStatus()
    
    private init() {
        startMonitoring()
    }
    
    var monitor: NWPathMonitor?

    var isConnected: Bool {
        guard let monitor = monitor else { return false }
        return monitor.currentPath.status == .satisfied
    }
    
    func startMonitoring() {
        monitor = NWPathMonitor()
        
        let queue = DispatchQueue(label: "NetStatus_Monitor")
        monitor?.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        self.monitor = nil
    }
    
    deinit {
        stopMonitoring()
    }
    
}

//class CommunicationController {
//    
//    static var token:String? = nil
//    
//    static var towerQueued:Int? = nil
//    
//    var loginType:LoginType? = nil
//    
//    var sender:Any!
//    
//    static var server = UserDefaults.standard.string(forKey: "server") ?? (UserDefaults.standard.bool(forKey: "NA") ? "/na." : "/")
//    
//    init(sender:Any! = nil, loginType:LoginType? = nil) {
//        self.sender = sender
//        self.loginType = loginType
//    }
//    
//    func sendRequest(method:String, endpoint:String, headers:[String:String]? = nil, json:[String:String]? = nil, type:RequestType, towerID:Int = 0, userSetting:UserSetting? = nil) {
//        // Create URL Request
//        let baseURL = "https:\(CommunicationController.server)ringingroom.com/api/"
//        guard let requestUrl = URL(string: baseURL+endpoint) else { return }
//        
//        var request = URLRequest(url: requestUrl)
//        
//        // Specify HTTP Method to use
//        request.httpMethod = method
//        
//        
//        if let requestHeaders = headers {
//            for header in requestHeaders {
//                request.addValue(header.value, forHTTPHeaderField: header.key)
//            }
//        }
//        
//        if let jsonData = json {
//            
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.setValue("application/json", forHTTPHeaderField: "Accept")
//            
//            do {
//                print("happenning")
//                request.httpBody = try JSONSerialization.data(withJSONObject: jsonData)
//            } catch {
//                print("conversion to json failed")
//            }
//        }
//        
//        // Send HTTP Request
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            
//            // Check if Error took place
//            if let error = error {
//                print("Error took place \(error)")
//                return
//            }
//            
//            var statusCode:Int? = nil
//            // Read HTTP Response Status code
//            if let response = response as? HTTPURLResponse {
//                print("Response HTTP Status code: \(response.statusCode)")
//                statusCode = response.statusCode
//            }
//            var dataDict = [String:Any]()
//            var towersDict = [String:[String:Any]]()
//            //            print(data)
//            // Convert HTTP Response Data to a simple String
//            
//            if let data = data {
//                if let dataString = String(data: data, encoding: .utf8) {
//                    print("Http response")
//                    print(dataString)
//                }
//                
//                do {
//                    if type == .getMyTowers {
//                        towersDict = try JSONSerialization.jsonObject(with: data) as! [String : [String : Any]]
//                    } else {
//                        dataDict = try JSONSerialization.jsonObject(with: data) as! [String : Any]
//                    }
//                } catch {
//                    print("error converting response to a dictionary")
//                }
//            }
//            
//            print(dataDict)
//            
//            switch type {
//            case .loginAttempt:
//                var gotToken = false
//                if let token = dataDict["token"] as? String {
//                    CommunicationController.token = token
//                    User.shared.loggedIn = true
//                    gotToken = true
//                }
//                switch self.loginType {
//                case .auto:
//                    if CommunicationController.towerQueued == nil || !gotToken {
//                        (self.sender as! AutoLogin).receivedResponse(statusCode: statusCode, response: dataDict, gotToken)
//                    } else {
//                        (self.sender as! AutoLogin).joinTower(id: CommunicationController.towerQueued!)
//                    }
//                case .welcome:
//                    (self.sender as! WelcomeLoginScreen).receivedResponse(statusCode: statusCode, response: dataDict, gotToken)
//                //                case .simple:
//                //                    (self.sender as! SimpleLoginView).receivedResponse(statusCode: statusCode, responseData: dataDict)
//                //                case .settings:
//                //                    (self.sender as! SettingsView).receivedResponse(statusCode: statusCode, responseData: dataDict)
//                //                case .refresh:
//                //                    (self.sender as! RingView)
//                default:
//                    print("not login")
//                //                case .none:
//                //                    (self.sender as! RingView).updatedMyTowers()
//                }
//            //            case .logout:
//            
//            case .getUserDetails:
//                User.shared.name = dataDict["username"] as! String
//                User.shared.email = dataDict["email"] as! String
//            case .registerNewUser:
//                (self.sender as! AccountCreationView).receivedResponse(statusCode: statusCode, response: dataDict)
//            case .modifyUserDetails:
//                User.shared.name = dataDict["username"] as! String
//                User.shared.email = dataDict["email"] as! String
//                (self.sender as! AccountView).receivedResponse(statusCode: statusCode, response: dataDict, setting:userSetting!, newSetting: json!["new_\(userSetting?.rawValue ?? "")"] ?? "")
//            case .deleteUser:
//                (self.sender as! AccountView).receivedDeleteResponse(statusCode: statusCode, response: dataDict)
//            case .getMyTowers:
//                //                for dict in dataDict {
//                //                    print(dict.value)
//                //                    do {
//                //                        var tempDict = [String:Any]()
//                //                        tempDict = try JSONSerialization.jsonObject(with: dict.value as! Data) as! [String : Any]
//                //                        towersDict[dict.key] = tempDict
//                //                    } catch {
//                //                        "error converting response to a dictionary"
//                //                    }
//                //                }
//                DispatchQueue.main.async {
//                    User.shared.myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
//                    User.shared.firstTower = true
//                    print("added towers")
//                    for dict in towersDict {
//                        print(dict)
//                        if dict.key != "0" {
//                            var tower = Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)
//                            if let id = dict.value["tower_id"] as? Int {
//                                tower = Tower(id: id, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
//                            } else {
//                                tower = Tower(id: Int(dict.value["tower_id"] as! String)!, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
//                                
//                            }
//                            User.shared.addTower(tower)
//                        }
//                    }
//                    print(User.shared.myTowers.names)
//                    User.shared.sortTowers()
//                    
//                }
//                
//                
//                switch self.loginType {
//                case .auto:
//                    (self.sender as! AutoLogin).receivedMyTowers(statusCode: statusCode, response: dataDict)
//                case .welcome:
//                    (self.sender as! WelcomeLoginScreen).receivedMyTowers(statusCode: statusCode, responseData: dataDict)
//                //                case .simple:
//                //                    (self.sender as! SimpleLoginView).receivedMyTowers(statusCode: statusCode, responseData: dataDict)
//                //                case .settings:
//                //                    (self.sender as! SettingsView).receivedMyTowers(statusCode: statusCode, responseData: dataDict)
//                default:
//                    if let sender = self.sender as? SocketIOManager {
//                        sender.gotMyTowers()
//                    }
//                    print("not login")
//                //                case nil:
//                //                    (self.sender as! RingView).updatedMyTowers()
//                }
//                
//            //            case .toggleBookmark:
//            //            case .deleteTowerFromRecents:
//            case .connectToTower:
//                if self.loginType == .auto {
//                    (self.sender as! AutoLogin).receivedTowerResponse(statusCode: statusCode, response: dataDict)
//                } else {
//                    if let sender = self.sender as? MainApp {
//                        sender.receivedResponse(statusCode: statusCode, response: dataDict)
//                    } else {
//                        (self.sender as! RingView).receivedResponse(statusCode: statusCode, response: dataDict)
//                    }
//                }
//            case .createTower:
//                self.getTowerDetails(id: dataDict["tower_id"] as! Int)
//            //            case .deleteTower:
//            //            case .getTowerSettings:
//            //            case .modifyTowerSettings:
//            //            case .addHost:
//            //            case .removeHost:
//            default:
//                return
//            }
//        }
//        task.resume()
//    }
//    
//    func login(email:String, password:String) {
//        
//    }
//    
//
//    
//}
//
//
//
//enum RequestType {
//    case welcomeLoginAttempt, loginAttempt, autoLoginAttempt, logout, getUserDetails, registerNewUser, modifyUserDetails, deleteUser, resetPassword
//    case getMyTowers, toggleBookmark, deleteTowerFromRecents
//    case connectToTower, createTower, deleteTower, getTowerSettings, modifyTowerSettings, addHost, removeHost
//}
//
//enum LoginType {
//    case auto, welcome, simple, settings, refresh
//}
