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
        default:
            fatalError("Invalid user setting: \(setting.rawValue)")
        }
    }
    
    var keyboardType: UIKeyboardType {
        return (setting == .email) ? .emailAddress : .default
    }
    
    var parent:AccountView
    
    @State var newSetting = ""
    
    @State var password = ""
    @State var repeatPassword = ""
    
    @State var alertTitle = ""
    @State var alertMessage = ""
    @State var showingAlert = false
    
    var canSaveChanges = false
    
    @State var passwordsMatch = true
    @State var correctPassword = true
    
    var body: some View {
        NavigationView {
            
            
            Form {
                if setting == .password {
                    Section(footer: Text("Passwords don't match").foregroundColor(.red).opacity(passwordsMatch ? 0 : 1).animation(.default)) {
                        SecureField("New password", text: $newSetting) {
                            passwordsMatch = newSetting == repeatPassword || repeatPassword == ""  || newSetting == ""
                        }
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                        .onChange(of: newSetting, perform: { value in
                            passwordsMatch = true
                        })
                        SecureField("Repeat new password", text: $repeatPassword) {
                            passwordsMatch = newSetting == repeatPassword || repeatPassword == ""  || newSetting == ""
                        }
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                        .onChange(of: repeatPassword, perform: { value in
                            passwordsMatch = true
                        })
                    }
                } else {
                    Section {
                        TextField("New \(setting.rawValue)", text: $newSetting)
                            .textContentType(textContentType)
                            .keyboardType(keyboardType)
                            .autocapitalization(.none)
                    }
                }
                if setting != .username {
                    Section(header: Text("Enter your password to confirm"), footer: Text("Incorrect Password").foregroundColor(.red).opacity(correctPassword ? 0 : 1).animation(.default)) {
                        SecureField("Password", text: $password) {
                            correctPassword = password == User.shared.password || password == ""
                        }
                            .textContentType(.password)
                            .autocapitalization(.none)
                        .onChange(of: password, perform: { value in
                            correctPassword = true
                        })
                    }
                }
                Section {
                    Button("Save change") {
                        makeChange()
                    }
                    .disabled(!canSaveChange())
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
    
    func canSaveChange() -> Bool {
        
        if newSetting == "" {
            return false
        }
        
        if setting == .email {
            if !newSetting.isValidEmail() {
                return false
            }
        }
        
        if setting == .password {
            if repeatPassword != newSetting {
                return false
            }
        }
        
        if setting != .username {
            if password != User.shared.password {
                return false
            }
        }
        
        return true
    }
    
    func makeChange() {
//        parent.comController.changeUserSetting(change: ["new_\(setting.rawValue)":newSetting], setting: setting)
        presentationMode.wrappedValue.dismiss()
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
