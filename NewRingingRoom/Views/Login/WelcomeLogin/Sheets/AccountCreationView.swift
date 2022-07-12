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
            AlertHandler.handle(error: LoginError.emailNotValid)
            return
        }
        
        guard !username.isEmpty else {
            AlertHandler.handle(error: LoginError.noUsername)
            return
        }
        
        guard !password.isEmpty else {
            AlertHandler.handle(error: LoginError.noPassword)
            return
        }
        
        guard password == repeatedPassword else {
            AlertHandler.handle(error: LoginError.passwordsDontMatch)
            return
        }
        
        let authenticationService = AuthenticationService()
        
        await ErrorUtil.alertable {
            try await authenticationService.registerUser(username: username, email: email.lowercased(), password: password)
            ThreadUtil.runInMain {
                self.accountCreated = true
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
