//
//  ChangeUsernameView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 11/04/2021.
//  Copyright © 2021 Matthew Goodship. All rights reserved.
//

import SwiftUI

enum TextFieldType {
    case new, repeated, confirm
}

enum AlertType: String {
    case passwordsDontMatch, passwordIncorrect, invalidEmail, success, error
}

extension AlertType:Identifiable {
    var id: RawValue {
        self.rawValue
    }
}

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
    
    @State var alertType:AlertType? = nil
    
    @State var newSetting = ""
    
    @State var password = ""
    @State var repeatPassword = ""
    
    var canSaveChanges = false
    
    @State var passwordsMatch = true
    @State var correctPassword = true
    
    @State var validNewSetting = true
    
    @State var selectedField:TextFieldType? = nil
    
    var body: some View {
        NavigationView {
            
            
            Form {
                if setting == .password {
                    Section {
                        SecureField("New password", text: $newSetting)
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
                        SecureField("Repeat new password", text: $repeatPassword)
                            .textContentType(.newPassword)
                            .autocapitalization(.none)
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
                    Section {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                    }
                }
                Section {
                    Button("Save change") {
                        makeChange()
                    }
                    .disabled(textFieldsAreEmpty())
                }
            }
            .alert(item: $alertType, content: { alertType in
                switch alertType {
                case .passwordsDontMatch:
                    return Alert(title: Text("Passwords don't match"), message: Text("Please re-enter your new password and try again."), dismissButton: .cancel(Text("OK")))
                case .passwordIncorrect:
                    return Alert(title: Text("Your password is incorrect"), message: Text("Please re-enter your password and try again."), dismissButton: .cancel(Text("OK")))
                case .invalidEmail:
                    return Alert(title: Text("Invalid email"), message: Text("Please re-enter your new email address and try again."), dismissButton: .cancel(Text("OK")))
                case .success:
                    return Alert(title: Text("Success!"), message: Text("Your new settings have been saved."), dismissButton: .default(Text("OK"), action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }))
                case .error:
                    return Alert(title: Text("Error"), message: Text("There was an error when saving your new settings."), dismissButton: .cancel())
                }
            })
            .navigationBarTitle(navigationTitle, displayMode: .inline)
            .navigationBarItems(trailing: Button("Back") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(.main)
    }
    
    func selectedFieldChanged() {
        switch selectedField {
        case .repeated, .new:
            passwordsMatch = newSetting == repeatPassword || repeatPassword == ""  || newSetting == ""
        case .confirm:
            correctPassword = password == User.shared.password || password == ""
        default: break
        }
    }
    
    func textFieldsAreEmpty() -> Bool {
        switch setting {
        case .username:
            return newSetting == ""
        case .password:
            return newSetting == "" || repeatPassword == ""
        case .email:
            return newSetting == "" || password == ""
        default:
            return true
        }
    }
    
    func canSaveChange() -> AlertType? {
        
        if setting == .email {
            if !newSetting.isValidEmail() {
                return .invalidEmail
            }
        }
        
        if setting == .password {
            if repeatPassword != newSetting {
                return .passwordsDontMatch
            }
        }
        
        if setting != .username {
            if password != User.shared.password {
                return .passwordIncorrect
            }
        }
        
        return nil
    }
    
    func makeChange() {
        if let alertType = canSaveChange() {
            self.alertType = alertType
        } else {
            
            NetworkManager.sendRequest(request: .changeUserSetting(change: ["new_\(setting.rawValue)":newSetting], setting: setting)) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    if 200..<300 ~= response?.statusCode ?? 0{
                        NetworkManager.sendRequest(request: .getUserDetails(), completion: { json,_,_ in
                            if let json = json {
                                if let username = json["username"] as? String {
                                    DispatchQueue.main.async {
                                        User.shared.name = username
                                    }
                                }
                                if let email = json["email"] as? String {
                                    DispatchQueue.main.async {
                                        User.shared.email = email
                                    }
                                }
                            }
                            self.alertType = .success
                        })
                        
                    } else {
                        self.alertType = .error
                    }
                }
            }
        }
    }
}
