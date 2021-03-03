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


            self.comController = CommunicationController(sender: self, loginType: .auto)
                login()

        })
    }
        
    func login() {
            print("sent login request")
            let email = UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces)
            //remove in next beta version
            let savedPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
            let kcw = KeychainWrapper()

            if savedPassword != "" {
                do {
                    try kcw.storePasswordFor(account: email, password: savedPassword)
                } catch {
                    print("error saving password to keychain")
                }
                UserDefaults.standard.setValue("", forKey: "userPassword")
            }
            //
            do {
                print("got this far")
                let password = try kcw.getPasswordFor(account: email)
                User.shared.email = email
                User.shared.password = password
                print("retrieved password")
                self.comController.login(email: email, password: password)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if AppController.shared.state == .login {
                        noInternetAlert()
                    }
                }
            } catch {
                unknownErrorAlert()
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
        DispatchQueue.main.async {
            AppController.shared.state = .main
        }
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
    
    func upgradeSecurityAlert() {
        alertTitle = "Error"
        alertMessage = "We've upgraded your password security. Sorry, you'll need to login again."
        alertCancelButton = .cancel(Text("OK"), action: {
            AppController.shared.loginState = .standard
        })
        showingAlert = true
    }
    
    func unknownErrorAlert() {
        alertTitle = "Error"
        alertMessage = "An unknown error occured."
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
