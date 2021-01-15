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
    
    @State private var comController:CommunicationController!

    @Binding var isPresented:Bool
    @State private var isShowingPrivacyPolicy = false
    
    @State private var agreedToPrivacyPolicy = false
    
    @Binding var email:String
    @State private var username = ""
    @Binding var password:String
    @State private var repeatedPassword = ""
    
    @State private var presentingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

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
                Section() {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    .disableAutocorrection(true)
                    SecureField("Repeat password", text: $repeatedPassword)
                        .textContentType(.newPassword)
                    .disableAutocorrection(true)
                }
                Section() {
                    Button(action: {
                        self.isShowingPrivacyPolicy = true
                    }) {
                        Text(privacyPolicyButtonText)
                    }
                    .sheet(isPresented: $isShowingPrivacyPolicy) {
                        agreeToPrivacyPolicyView(isPresented: self.$isShowingPrivacyPolicy, agreed: self.$agreedToPrivacyPolicy)
                    }
                }
                Section() {
                    Button(action: createAccount) {
                        Text("Create account")
                    }
                    .disabled(!agreedToPrivacyPolicy)
                    .alert(isPresented: $presentingAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    
                }
                
            }.navigationBarTitle("Create Account", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {self.presentationMode.wrappedValue.dismiss()}) {Text("Back").bold()})
        }
        .accentColor(.main)
    .navigationViewStyle(StackNavigationViewStyle())
    .onAppear(perform: {
        self.comController = CommunicationController(sender: self)
    })
    }
    
    func createAccount() {
        if !email.trimmingCharacters(in: .whitespaces).isValidEmail() {
            alertTitle = "Email not valid"
            alertMessage = "The email adress you entered is not valid. Please try again."
            presentingAlert = true
            return
        }
        if username == "" {
            alertTitle = "No username entered"
            alertMessage = "Please enter a username."
            presentingAlert = true
            return
        }
        if password == "" {
            alertTitle = "No password entered"
            alertMessage = "Please enter a password."
            presentingAlert = true
            return
        }
        if passwordsDontMatch(passwords: [password, repeatedPassword]) {
            alertTitle = "Passwords don't match"
            alertMessage = "Please enter the same password both times."
            presentingAlert = true
            return
        }
        //send account creation request to server
        comController.registerNewUser(username: username, email: email.lowercased(), password: password)
    }
    
    func receivedResponse(statusCode:Int? = nil, response:[String:Any]) {
        if statusCode == 500 {
            print("whoops")
            alertTitle = "Email already registered"
            alertMessage = "There is already an account with that email address"
            self.presentingAlert = true
        } else {
            self.accountCreated = true
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func passwordsDontMatch(passwords:[String]) -> Bool {
        return !(passwords[0] == passwords[1])
    }
    
}

public extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
