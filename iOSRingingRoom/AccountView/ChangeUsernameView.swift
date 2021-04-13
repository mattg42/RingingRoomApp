//
//  ChangeUsernameView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 11/04/2021.
//  Copyright © 2021 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct ChangeAccountSettingView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var setting:UserSetting
    
    var navigationTitle:String {
        "Change \(setting.rawValue)"
    }
    
    var textContentType: UITextContentType {
        switch setting {
        case .username:
            return .nickname
        case .email:
            return .nickname
        case .password:
            return .newPassword
        }
    }
    
    var keyboardType: UIKeyboardType {
        return (setting == .email) ? .emailAddress : .default
    }
    
    var parent:SettingsView
    
    @State var newSetting = ""
    
    @State var password = ""
    @State var repeatPassword = ""
    
    @State var alertTitle = ""
    @State var alertMessage = ""
    @State var showingAlert = false
    
    var body: some View {
        NavigationView {
            
            
            Form {
                if setting == .password {
                    Section {
                        SecureField("New password", text: $newSetting)
                            .textContentType(.newPassword)
                        SecureField("Repeat new password", text: $repeatPassword)
                            .textContentType(.newPassword)
                    }
                } else {
                    Section {
                        TextField("New \(setting.rawValue)", text: $newSetting)
                            .textContentType(textContentType)
                            .keyboardType(keyboardType)
                    }
                }
                if setting != .username {
                    Section(header: Text("Enter your password to confirm").autocapitalization(.none)) {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                    }
                }
                Section {
                    Button("Save change") {
                        makeChange()
                    }
                }
            }
            .alert(isPresented: $showingAlert, content: {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .cancel(Text("OK")))
            })
            .navigationBarTitle(navigationTitle, displayMode: .inline)
            .navigationBarItems(trailing: Button("Back") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(.main)
    }
    
    func makeChange() {
        
        if setting == .email {
            if !newSetting.isValidEmail() {
                invalidEmailAlert()
                return
            }
        }
        
        if setting == .password {
            if repeatPassword != password {
                differentPasswordsAlert()
                return
            }
        }
        
        if setting != .username {
            if password != User.shared.password {
                incorrectPasswordAlert()
                return
            }
        }
        
        // passed checks
        
        parent.comController.changeUserSetting(change: ["new_\(setting.rawValue)":newSetting], setting: setting)
    }
    
    func invalidEmailAlert() {
        alertTitle = "Invalid email"
        alertMessage = "The email address you entered is invalid. Please change it and try again."
        showingAlert = true
    }
    
    func differentPasswordsAlert() {
        alertTitle = "Different passwords"
        alertMessage = "Your repeated password isn't the same as the first."
        showingAlert = true
    }
    
    func incorrectPasswordAlert() {
        alertTitle = "Incorrect password"
        alertMessage = "The password you entered is incorrect."
        showingAlert = true
    }
}
