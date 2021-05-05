//
//  SettingsView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 09/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct AccountView: View {
    
    @State private var presentingLogin = false
    @State private var presentingCreateAccount = false
    @State private var presentingAlert = false
    
    @State private var accountCreated = false
    
    @ObservedObject var user = User.shared
    
//    @State var comController:CommunicationController!
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var newUsername = ""
    
    @State private var showingChangeSettingView = false
    
    @State private var showingResponseAlert = false
    
    @State private var responseAlertTitle = ""
    @State private var responseAlertMessage = ""
    
    @State var currentSetting:UserSetting? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    
                    Section {
                        Text("Username: \(User.shared.name)")
                        Button("Change username") {
                            currentSetting = .username
                            showingChangeSettingView = true
                        }

//                        .textFieldAlert(content: TextFieldAlert(isPresented: $showingChangeUsernameAlert, title: "Change username", message: "Change your username", dismissAction: { (text) in
//                            print("Sucess! \(text ?? "")")
//                        }, isSecure: false, setting: .email))

//                        .textFieldAlert(isPresented: $showingChangeUsernameAlert, content: { () -> TextFieldAlert in
//                            TextFieldAlert(title: "Change username", message: "Enter your new username", dismissAction: { (newUsername) in
//                                if newUsername != nil {
//                                    if newUsername! != "" {
//                                        comController.changeUserSetting(change: ["new_username":newUsername!], setting: .username)
//
//                                    }
//                                }
//                            }, setting: .username, isSecure: false)
//                        })
                    }
                    
                    Section {
                        Text("Email: \(User.shared.email)")
                        Button("Change email") {
                            currentSetting = .email
                            showingChangeSettingView = true
                        }
                    }
                    
                    Section {
                        Button("Change password") {
                            currentSetting = .password
                            showingChangeSettingView = true
                        }
                    }
                    
                    Section {
                        Button(action: {
                            currentSetting = .delete
                        }) {
                            ZStack(alignment: .leading) {
                            Text("Delete account").foregroundColor(.red).bold()
                            }
                        }
                    }
                    
                    Section {
                        Toggle("Auto-rotate bell circle", isOn: .init(get: {
                            return UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
                        }, set: {
                            UserDefaults.standard.set($0, forKey: "autoRotate")
                            BellCircle.current.autoRotate = $0
                        }))
                        .toggleStyle(SwitchToggleStyle(tint: .main))
                    }
                    Section {
                        Button(action: {
                            self.presentingAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Log out")
                                Spacer()
                            }
                        }
                        .alert(isPresented: $presentingAlert) {
                            Alert(title: Text("Are you sure you want to log out?"), message: nil, primaryButton: .destructive(Text("Yes"), action: self.logout), secondaryButton: .cancel(Text("Cancel"), action: {self.presentingAlert = false}))
                        }
                    }
                }
                .sheet(item: $currentSetting, content: { setting in
                    if setting != .delete {
                        ChangeAccountSettingView(setting: setting, parent: self)
                    } else {
                        DeleteAccountView(parent: self)
                    }
                })
//                .sheet(isPresented: $showingChangeSettingView) {
//                    ChangeAccountSettingView(parent: self)
//                }
                .alert(isPresented: $showingResponseAlert) {
                    Alert(title: Text(responseAlertTitle), message: Text(responseAlertMessage), dismissButton: .cancel(Text("OK")))
                }
                
//                VStack {
//                    Spacer()
//                    #if DEBUG
//                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
//                            .font(.callout)
//                    #else
//                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
//                            .font(.callout)
//                    #endif
//                    Text("By Matthew Goodship")
//                        .font(.callout)
//                }
//                .padding()
//                .foregroundColor(.secondary)
            }.navigationBarTitle("Account")
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .cancel(Text("OK")))
        }
    }
    
    func receivedResponse(statusCode: Int?, response: [String:Any], setting:UserSetting, newSetting:String) {
        print("status code: \(String(describing: statusCode))")
        print(response)
        if statusCode == 201 {
            // success
            if setting == .password {
                User.shared.password = newSetting
                let kcw = KeychainWrapper()
                do {
                    try kcw.storePasswordFor(account: User.shared.email, password: newSetting)
                } catch {
                    print("error saving password")
                }
            } else if setting == .email {

                let kcw = KeychainWrapper()
                do {
                    try kcw.storePasswordFor(account: newSetting, password: User.shared.password)
                    try kcw.deletePasswordFor(account: User.shared.email)
                } catch {
                    print("error saving password")
                }
                
                User.shared.email = newSetting
                UserDefaults.standard.set(newSetting, forKey: "userEmail")

            }
            responseAlertTitle = "Success!"
            responseAlertMessage = "You have successfully changed your \(setting.rawValue)!"
        } else {
            // failure
            responseAlertTitle = "Failure"
            responseAlertMessage = "You settings are not changed."
        }
        showingResponseAlert = true
    }
    
    func receivedDeleteResponse(statusCode: Int?, response: [String:Any]) {
        if statusCode == 202 {
            // account deleted
            
            logout()
        } else {
            responseAlertTitle = "Failure"
            responseAlertMessage = "The account failed to delete."
        
            showingResponseAlert = true
        }
    }
    
//    @State var i = 1
    
//    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
//        if statusCode! == 401 {
//            alertTitle = "Error logging in"
//            self.showingAlert = true
//        } else {
//            DispatchQueue.main.async {
//                UserDefaults.standard.set(true, forKey: "keepMeLoggedIn")
//                UserDefaults.standard.set(self.email, forKey: "userEmail")
//                UserDefaults.standard.set(self.password, forKey: "userPassword")
//                self.loggedIn = true
//            }
//        }
//    }
//
//    func runShortcut() {
//        if i == 1 {
//            var shortcutName = "shortcuts://import-shortcut?url=https://www.icloud.com/shortcuts/04566978207b47b2a99b7b878028d431&name=Start%20Practice&silent=true"
//
//            let url = URL(string: shortcutName)!
//            UIApplication.shared.open(url,
//                                      options: [:],
//                                      completionHandler: nil)
//            i += 1
//        } else {
//            var shortcutName = "shortcuts://run-shortcut?name=Start%20Practice&silent=true"
//
//            let url = URL(string: shortcutName)!
//            UIApplication.shared.open(url,
//                                      options: [:],
//                                      completionHandler: nil)
//        }
//    }
    
    func logout() {
        let kcw = KeychainWrapper()

        do {
            try kcw.deletePasswordFor(account: User.shared.email)
        } catch {
            print("error deleting password")
        }

        User.shared.reset()
        
        NetworkManager.token = nil
        UserDefaults.standard.set("", forKey: "userEmail")
        UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
                
        User.shared.loggedIn = false
        
        AppController.shared.loginState = .standard
        AppController.shared.state = .login
        print("logged out")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}

extension UserDefaults {

    public func optionalInt(forKey defaultName: String) -> Int? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Int
        }
        return nil
    }

    public func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }
    
    public func optionalDouble(forKey defaultName: String) -> Double? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Double
        }
        return nil
    }
}

enum UserSetting:String {
    case username, email, password, delete
}

extension UserSetting:Identifiable {
    var id: String { rawValue }
}
