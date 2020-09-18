//
//  SettingsView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @State var presentingLogin = false
    @State var presentingCreateAccount = false
    @State var presentingAlert = false
    
    @State var accountCreated = false
    
    @ObservedObject var user = User.shared
    
    @State var comController:CommunicationController!

    @State var email = User.shared.email
    @State var password = User.shared.email
    @State var loggedIn = User.shared.loggedIn
    
    @State var showingAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    
    var body: some View {
        NavigationView {
            if loggedIn {
                Form {
                    Section(header: Text("Username")) {
                        Text("Current username: \(User.shared.name)")
                    }
                    Section {
                        Button("Log out") {
                            self.presentingAlert = true
                        }
                        .alert(isPresented: $presentingAlert) {
                            Alert(title: Text("Are you sure you want to log out?"), message: nil, primaryButton: .destructive(Text("Yes"), action: self.logout), secondaryButton: .cancel(Text("Cancel"), action: {self.presentingAlert = false}))
                        }
                    }
                }.navigationBarTitle("Settings")
            } else {
                Form {
                    Section {
                        Button("Log in") {
                            self.presentingLogin = true
                        }
                        .sheet(isPresented: $presentingLogin, onDismiss: {
                            print("login is dissmissed", self.presentingLogin)
                        }) {
                            SimpleLoginView(loggedIn: self.$loggedIn)
                        }
                    }
                    Section {
                        Button("Create account") {
                            self.presentingCreateAccount = true
                        }
                        .sheet(isPresented: $presentingCreateAccount, onDismiss: {
                            if self.accountCreated {
                                self.comController.login(email: self.email, password: self.password)
                            }
                        }) {
                            AccountCreationView(isPresented: self.$presentingCreateAccount, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
                        }
                    }
                }.navigationBarTitle("Settings")
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .cancel(Text("OK")))
        }
    .onAppear(perform: {
        self.comController = CommunicationController(sender: self, loginType: .settings)
    })
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        print("status code: \(statusCode)")
        print(responseData)
        if statusCode! == 401 {
            print(responseData)
            alertTitle = "Error logging in"
            self.showingAlert = true
        } else {
            comController.getUserDetails()
            comController.getMyTowers()
        }
    }
    
    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            alertTitle = "Error logging in"
            self.showingAlert = true
        } else {
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "keepMeLoggedIn")
                UserDefaults.standard.set(self.email, forKey: "userEmail")
                UserDefaults.standard.set(self.password, forKey: "userPassword")
                self.loggedIn = true
            }
        }
    }
    
    func logout() {
        
        User.shared.loggedIn = false
        User.shared.name = ""
        User.shared.email = ""
        User.shared.host = false
        User.shared.myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
        User.shared.firstTower = true
        User.shared.savedTowerID = ""
        
        CommunicationController.token = nil
        UserDefaults.standard.set("", forKey: "userEmail")
        UserDefaults.standard.set("", forKey: "userPassword")
        UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
        self.loggedIn = false
        print("logged out")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
