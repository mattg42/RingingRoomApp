//
//  AutoLogin.swift
//  iOSRingingRoom
//
//  Created by Matthew on 05/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import Network

struct AutoLogin: View {
    @State private var showingAlert = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton:Alert.Button = .cancel()
        
    @State private var autoJoinTower = false
    @State private var autoJoinTowerID = 0
        
    init() {
        
        print("called login")

    }
    
    var body: some View {
        ZStack {
            Color.main
            HStack {
                Image("rrLogo").resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 256, height: 256)
            }
            
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showingAlert) {
        //present welcome login screen
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: alertCancelButton)
        }
        .onOpenURL(perform: { url in
            var pathComponents = url.pathComponents.dropFirst()
            if let firstPath = pathComponents.first {
                if let towerID = Int(firstPath) {
                    autoJoinTowerID = towerID
                }
            }
            print("opened from \(url.pathComponents.dropFirst())")
        })
        .onAppear(perform: {
            login()
        })
    }
        
    func joinTower(id: Int) {

        DispatchQueue.global(qos: .userInteractive).async {
//                CommunicationController.towerQueued = nil
                print("joined tower")
                self.getTowerConnectionDetails(id: id)
            }
    }
    
    func getTowerConnectionDetails(id: Int) {
//        comController.getTowerDetails(id: id)
    }
        
//    func receivedTowerResponse(statusCode:Int?, response:[String:Any]) {
//        print("received")
//        if statusCode ?? 0 == 404 {
//            noTowerAlert()
//        } else if statusCode ?? 0 == 401 {
//            unauthorisedAlert()
//        } else if statusCode ?? 0 == 200 {
//            BellCircle.current.towerName = response["tower_name"] as! String
//            BellCircle.current.towerID = response["tower_id"] as! Int
//            BellCircle.current.serverAddress = response["server_address"] as! String
//            BellCircle.current.additionalSizes = response["additional_sizes_enabled"] as? Bool ?? false
//            BellCircle.current.hostModePermitted = response["host_mode_permitted"] as? Bool ?? true
//            BellCircle.current.halfMuffled = response["half_muffled"] as? Bool ?? false
//
//            if let tower = User.shared.myTowers.towerForID(BellCircle.current.towerID) {
//                DispatchQueue.main.async {
//                    BellCircle.current.isHost = tower.host
//                }
//            } else {
//                BellCircle.current.needsTowerInfo = true
//            }
//
//            BellCircle.current.joinedTowers.append(BellCircle.current.towerID)
//
//            SocketIOManager.shared.setups = 0
//            SocketIOManager.shared.connectSocket(server_ip: BellCircle.current.serverAddress)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
//                if !BellCircle.current.joinedTowers.contains(response["tower_id"] as! Int) {
//                    if !showingAlert {
//                        socketFailedAlert()
//                    }
//                } else {
//                    BellCircle.current.joinedTowers.removeFirstInstance(of: response["tower_id"] as! Int)
//                }
//            }
//            //            }
//        } else {
//            unknownErrorAlert()
//        }
//    }
        
    func login() {
        
        guard NetworkManager.token == nil else { return }
        
        print("sent login request")
        let email = UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces)
        
        //remove in next beta version
        let savedPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
        let kcw = KeychainWrapper()
        
        if UserDefaults.standard.string(forKey: "server") == nil {
            let value = UserDefaults.standard.bool(forKey: "NA")
            
            if value {
                UserDefaults.standard.setValue("/na.", forKey: "server")
            } else {
                UserDefaults.standard.setValue("/", forKey: "server")
            }
        }
        
        if savedPassword != "" {
            do {
                try kcw.storePasswordFor(account: email, password: savedPassword)
            } catch {
                print("error saving password to keychain")
            }
            UserDefaults.standard.setValue("", forKey: "userPassword")
        }
        
        do {
            print("got this far")
            let password = try kcw.getPasswordFor(account: email)
            User.shared.email = email
            User.shared.password = password
            print("retrieved password")
            NetworkManager.sendRequest(request: .login(email: email, password: password)) { (json, response, error) in
                if let json = json {
                    if let token = json["token"] as? String {
                        NetworkManager.token = token
                        NetworkManager.sendRequest(request: .getUserDetails()) { (json, response, error) in
                            if let json = json {
                                if let username = json["username"] as? String {
                                    DispatchQueue.main.async {
                                        User.shared.name = username
                                    }
                                    
                                }
                            }

                        }

                        NetworkManager.sendRequest(request: .getMyTowers()) { (json, response, error) in
                            if let json = json as? [String: [String:Any]] {
                                DispatchQueue.main.async {
                                    User.shared.myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
                                    User.shared.firstTower = true
                                }

                                for dict in json {
                                    print(dict)
                                    if dict.key != "0" {
                                        var tower:Tower? = nil
                                        if let id = dict.value["tower_id"] as? Int {
                                            tower = Tower(id: id, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
                                        } else {
                                            tower = Tower(id: Int(dict.value["tower_id"] as! String)!, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
                                            
                                        }
                                        if tower != nil {
                                            DispatchQueue.main.async {
                                                User.shared.addTower(tower!)
                                            }
                                           
                                        }
                                    }
                                }
                                print(User.shared.myTowers.names)
                                DispatchQueue.main.async {
                                    User.shared.sortTowers()
                                }
                                if autoJoinTowerID != 0 {
                                    NetworkManager.sendRequest(request: .getTowerDetails(id: autoJoinTowerID)) { (json, response, error) in
                                        if let json = json {
                                            BellCircle.current.towerName = json["tower_name"] as! String
                                            BellCircle.current.towerID = json["tower_id"] as! Int
                                            BellCircle.current.serverAddress = json["server_address"] as! String
                                            BellCircle.current.additionalSizes = json["additional_sizes_enabled"] as? Bool ?? false
                                            BellCircle.current.hostModePermitted = json["host_mode_permitted"] as? Bool ?? true
                                            BellCircle.current.halfMuffled = json["half_muffled"] as? Bool ?? false
                                            
                                            if let tower = User.shared.myTowers.towerForID(BellCircle.current.towerID) {
                                                DispatchQueue.main.async {
                                                    BellCircle.current.isHost = tower.host
                                                }
                                            } else {
                                                BellCircle.current.needsTowerInfo = true
                                            }
                                            
                                            BellCircle.current.joinedTowers.append(BellCircle.current.towerID)
                                            
                                            SocketIOManager.shared.setups = 0
                                            SocketIOManager.shared.connectSocket(server_ip: BellCircle.current.serverAddress)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                                if !BellCircle.current.joinedTowers.contains(json["tower_id"] as! Int) {
                                                    if !showingAlert {
                                                        socketFailedAlert()
                                                    }
                                                } else {
                                                    BellCircle.current.joinedTowers.removeFirstInstance(of: json["tower_id"] as! Int)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        AppController.shared.selectedTab = .ring

                                        AppController.shared.state = .main
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            unknownErrorAlert()
        }
    }
    
//    func receivedResponse(statusCode:Int?, response:[String:Any], _ gotToken:Bool) {
//        if statusCode == 401 {
//            incorrectCredentialsAlert()
//        } else if statusCode == 200 && gotToken {
//            self.comController.getUserDetails()
//            self.comController.getMyTowers()
//        } else {
//            unknownErrorAlert()
//        }
//    }
    
//    func receivedMyTowers(statusCode:Int?, response:[String:Any]) {
//        DispatchQueue.main.async {
//            AppController.shared.state = .main
//        }
//    }
    
    func upgradeSecurityAlert() {
        alertTitle = "Error"
        alertMessage = "We've upgraded your password security. Sorry, you'll need to login again."
        alertCancelButton = .cancel(Text("OK"), action: {
            AppController.shared.loginState = .standard
        })
        showingAlert = true
    }
    
    func incorrectCredentialsAlert() {
        alertTitle = "Credentials error"
        alertMessage = "Your username or password is incorrect."
        alertCancelButton = .cancel(Text("OK"), action: {
            AppController.shared.loginState = .standard
        })
        showingAlert = true
    }
    
    func socketFailedAlert() {
        alertTitle = "Failed to connect socket"
        alertMessage = "Please try and join the tower again. If the problem persists, restart the app."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func unauthorisedAlert() {
        alertTitle = "Invalid token"
        alertMessage = "Please restart the app."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func noTowerAlert() {
        alertTitle = "No tower found"
        alertMessage = "There is no tower with that ID."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func unknownErrorAlert() {
        alertTitle = "Error"
        alertMessage = "An unknown error occurred."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
        
    func noInternetAlert() {
        alertTitle = "Connection error"
        alertMessage = "Your device is not connected to the internet. Please check your internet connection and try again."
        alertCancelButton = .cancel(Text("Try again"), action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: login)
        })
        showingAlert = true
    }
    
}

struct AutoLogin_Previews: PreviewProvider {
    static var previews: some View {
        AutoLogin()
    }
}
