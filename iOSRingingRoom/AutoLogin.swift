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
//    @Environment(\.viewController) private var viewControllerHolder: UIViewController?

    @State private var showingAlert = false
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton:Alert.Button = .cancel()
    
    @State private var comController:CommunicationController!
    
    @State private var autoJoinTower = false
    @State private var autoJoinTowerID = 0
    
    @State private var monitor = NWPathMonitor()
    
    init() {
        
        print("called login")

    }
    
    var body: some View {
        ZStack {
            Color.main
            HStack {
//                Spacer(minLength: 55)
                Image("rrLogo").resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 256, height: 256)
//                Spacer(minLength: 55)
            }
            
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showingAlert) {
        //present welcome login screen
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: alertCancelButton)
        }
        .onAppear(perform: {

            let queue = DispatchQueue.monitor
            monitor.start(queue: queue)
            self.comController = CommunicationController(sender: self, loginType: .auto)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                login()
            }

        })
    }
        
    func login() {
        if monitor.currentPath.status == .satisfied || monitor.currentPath.status == .requiresConnection {
            print("sent login request")
            self.comController.login(email: UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces), password: UserDefaults.standard.string(forKey: "userPassword")!)
        } else {
            print("path unsatisfied")
            noInternetAlert()
        }
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        if statusCode == 401 {
            incorrectCredentialsAlert()
        } else if statusCode == 200 {
            self.comController.getUserDetails()
            self.comController.getMyTowers()
        } else {
            unknownErrorAlert()
        }
    }
    
    func receivedMyTowers(statusCode:Int?, response:[String:Any]) {
        AppController.shared.state = .main
//        if statusCode == 200 {
//            DispatchQueue.main.async {
//                self.viewControllerHolder?.present(style: .fullScreen, name: "Main", animated: false) {
//                    MainApp(autoJoinTower: autoJoinTower, autoJoinTowerID: autoJoinTowerID)
//                }
//            }
//        } else {
//            unknownErrorAlert()
//        }
    }
    
    func unknownErrorAlert() {
        alertTitle = "Error"
        alertMessage = "An unknown error occured."
        alertCancelButton = .cancel(Text("OK"), action: {
            User.shared.loggedIn = true
        })
        showingAlert = true
    }
    
    func incorrectCredentialsAlert() {
        alertTitle = "Credentials error"
        alertMessage = "Your username or password is incorrect."
        alertCancelButton = .cancel(Text("OK"), action: {
            User.shared.loggedIn = true
        })
        self.showingAlert = true
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
