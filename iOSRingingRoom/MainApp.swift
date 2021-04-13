//
//  MainApp.swift
//  iOSRingingRoom
//
//  Created by Matthew on 06/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import SocketIO
import Network

struct MainApp: View {
        
    @Environment(\.scenePhase) var scenePhase
    
    @State private var isPresentingHelpView = true
        
    @State var autoJoinTower = false
    @State var autoJoinTowerID = 0

//    var ringView = RingView()
    var ringingRoomView = RingingRoomView()

    
    @ObservedObject var user = User.shared
    
    @ObservedObject var bellCircle = BellCircle.current
    
    @ObservedObject var controller = AppController.shared
        
    @State var showingPrivacyPolicyView = false
    
    @State var cc:CommunicationController! = nil

    @State var monitor = NWPathMonitor()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton = Alert.Button.cancel()
    
    var body: some View {
        switch AppController.shared.state {
        case .login:
            if AppController.shared.loginState == .auto {
                AutoLogin()
                    .sheet(isPresented: $showingPrivacyPolicyView, content: {
                        PrivacyPolicyWebView(isPresented: $showingPrivacyPolicyView)

                    })
                    .onOpenURL(perform: { url in
                        let pathComponents = Array(url.pathComponents.dropFirst())
                        print(pathComponents)
                        if pathComponents.first ?? "" == "privacy" {
                            showingPrivacyPolicyView = true
                        }
                    })
            } else {
                WelcomeLoginScreen()
                    .accentColor(Color.main)

            }

        case .main:
            TabView(selection: .init(get: {
                controller.selectedTab
            }, set: {
                controller.selectedTab = $0
            })) {
                RingView()
                    .tag(TabViewType.ring)
                    .tabItem {
                        Image(systemName: "list.bullet")
                            .font(.title)
                        Text("Towers")
                    }
                StoreView()
                    .tag(TabViewType.store)
                    .tabItem {
                        Image(systemName: "cart")
                            .font(.title)
                        Text("Store")
                    }
                HelpView(asSheet: false, isPresented: self.$isPresentingHelpView)
                    .tag(TabViewType.help)
                    .tabItem {
                        Image(systemName: "questionmark.circle")
                            .font(.title)
                        Text("Help")
                    }
                AccountView()
                    .tag(TabViewType.settings)
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title)
                        Text("Account")
                    }
            }
            .alert(isPresented: $showingAlert, content: {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: alertCancelButton)
            })
            .onAppear {
                monitor.start(queue: DispatchQueue.monitor)
            }
            .onDisappear {
                monitor.cancel()
            }
            .sheet(isPresented: $showingPrivacyPolicyView, content: {
                PrivacyPolicyWebView(isPresented: $showingPrivacyPolicyView)

            })
            .onOpenURL(perform: { url in
                cc = CommunicationController(sender: self, loginType: nil)
                let pathComponents = url.pathComponents.dropFirst()
                print(pathComponents)
                if let firstPath = pathComponents.first {
                    if firstPath == "privacy" {
                        showingPrivacyPolicyView = true
                    } else if let towerID = Int(firstPath) {
                        if CommunicationController.token != nil {
                            joinTower(id: towerID)
                        }
                    }
                }
            })
            .accentColor(Color.main)
        case .ringing:
            ringingRoomView
                .onChange(of: scenePhase, perform: { phase in
                    print("new phase: \(phase)")
                    if phase == .active {
                        SocketIOManager.shared.refresh = true
                        SocketIOManager.shared.socket?.connect()
                    } else if phase == .background {
                        SocketIOManager.shared.socket?.disconnect()
                    }
                })
                .accentColor(Color.main)

        }
    }
    
    func joinTower(id: Int) {
        SocketIOManager.shared.socket?.disconnect()
        DispatchQueue.global(qos: .userInteractive).async {
            if monitor.currentPath.status == .satisfied {
                print("joined tower")
                self.getTowerConnectionDetails(id: id)
                
                //create new tower
            } else {
                noInternetAlert()
            }
        }
        
    }
    
    func getTowerConnectionDetails(id: Int) {
        cc.getTowerDetails(id: id)
    }
        
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        print("received")
        if statusCode ?? 0 == 404 {
            noTowerAlert()
        } else if statusCode ?? 0 == 401 {
            unauthorisedAlert()
        } else if statusCode ?? 0 == 200 {
            BellCircle.current.towerName = response["tower_name"] as! String
            BellCircle.current.towerID = response["tower_id"] as! Int
            BellCircle.current.serverAddress = response["server_address"] as! String
            BellCircle.current.additionalSizes = response["additional_sizes_enabled"] as? Bool ?? false
            BellCircle.current.hostModePermitted = response["host_mode_permitted"] as? Bool ?? false
            BellCircle.current.halfMuffled = response["half_muffled"] as? Bool ?? false
            
            DispatchQueue.main.async {
                BellCircle.current.hostModeEnabled = false
            }
            
            if let tower = user.myTowers.towerForID(BellCircle.current.towerID) {
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
                if !BellCircle.current.joinedTowers.contains(response["tower_id"] as! Int) {
                    if !showingAlert {
                        socketFailedAlert()
                    }
                } else {
                    BellCircle.current.joinedTowers.removeFirstInstance(of: response["tower_id"] as! Int)
                }
            }
            //            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func presentRingingRoomView() {
        print("going to ringingroom view")
        cc.getMyTowers()
        AppController.shared.state = .ringing
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
        alertMessage = "An unknown error occured."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func noInternetAlert() {
        alertTitle = "Connection error"
        alertMessage = "Your device is not connected to the internet. Please check your internet connection and try again."
        
        alertCancelButton = .cancel(Text("OK"))
        
        showingAlert = true
    }
    
}

enum TabViewType:Hashable {
    case ring, help, store, settings
}

extension Color {
    public static var main:Color {
        return Color(red: 178/255, green: 39/255, blue: 110/255)
    }
}

struct MainApp_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
