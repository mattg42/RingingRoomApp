//
//  accountCreationView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 03/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct AccountCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: LoginViewModel
    
    @State private var isShowingPrivacyPolicy = false
    
    @State private var agreedToPrivacyPolicy = false
    
    @Binding var email:String
    @State private var username = ""
    @Binding var password:String
    @State private var repeatedPassword = ""
    
    @Binding var accountCreated:Bool
    
    @State private var privacyPolicyButtonText = "Read and agree to the privacy policy"
    
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("This is the name that will appear in the tower when you're ringing. You can change it later.")) {
                    TextField("Username", text: $username)
                        .disableAutocorrection(true)
                }
                Section(footer: Text("You'll use your email address to log in. We will never share it with anyone.")) {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    SecureField("Repeat password", text: $repeatedPassword)
                        .textContentType(.newPassword)
                }
                Section {
                    Button(action: {
                        self.isShowingPrivacyPolicy = true
                    }) {
                        Text(privacyPolicyButtonText)
                    }
                    .sheet(isPresented: $isShowingPrivacyPolicy) {
                        AgreeToPrivacyPolicyView(isPresented: self.$isShowingPrivacyPolicy, agreed: self.$agreedToPrivacyPolicy)
                    }
                }
                Section {
                    AsyncButton(action: createAccount) {
                        Text("Create account")
                    }
                    .disabled(!agreedToPrivacyPolicy)
                    
                }
                
            }.navigationBarTitle("Create Account", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {self.presentationMode.wrappedValue.dismiss()}) {Text("Back").bold()})
        }
        .accentColor(.main)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func createAccount() async {
        guard email.trimmingCharacters(in: .whitespaces).isValidEmail() else {
            viewModel.errorHandler.handle(error: AccountCreationError.emailNotValid)
            return
        }
        
        guard !username.isEmpty else {
            viewModel.errorHandler.handle(error: AccountCreationError.noUsername)
            return
        }
        
        guard !password.isEmpty else {
            viewModel.errorHandler.handle(error: AccountCreationError.noPassword)
            return
        }
        
        guard password == repeatedPassword else {
            viewModel.errorHandler.handle(error: AccountCreationError.passwordsDontMatch)
            return
        }
        
        let result = await viewModel.apiService.registerUser(username: username, email: email.lowercased(), password: password)
        
        switch result {
        case .success(let userModel):
            User.shared.username = userModel.username
            User.shared.email = userModel.email
            User.shared.password = password
            
            ThreadUtil.runInMain {
                self.accountCreated = true
                self.presentationMode.wrappedValue.dismiss()
            }
            
        case .failure(let error):
            viewModel.errorHandler.handle(error: error)
        }
    }
}

enum AccountCreationError: Error, Alertable {
    case emailNotValid, noUsername, noPassword, passwordsDontMatch
    
    var errorAlert: ErrorAlert {
        switch self {
        case .emailNotValid:
            return ErrorAlert(title: "Invalid email", message: "The email address you entered is invalid. Please fix this", dissmiss: .cancel(title: "Ok", action: nil))
        case .noUsername:
            return ErrorAlert(title:"No username", message: "Please enter a username", dissmiss: .cancel(title: "Ok", action: nil))
        case .noPassword:
            return ErrorAlert(title: "No password", message: "Please enter a password", dissmiss: .cancel(title: "Ok", action: nil))
        case .passwordsDontMatch:
            return ErrorAlert(title: "Passwords don't match", message: "Please type in the same password twice", dissmiss: .cancel(title: "Ok", action: nil))
        }
    }
}
