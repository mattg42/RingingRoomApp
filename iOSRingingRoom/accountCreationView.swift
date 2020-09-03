//
//  accountCreationView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 03/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct AccountCreationView: View {
    @Binding var isPresented:Bool
    @State var isShowingPrivacyPolicy = false
    
    @State var agreedToPrivacyPolicy = false
    
    @Binding var email:String
    @State var username = ""
    @Binding var password:String
    @State var repeatedPassword = ""
    
    @State var presentingAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""

    @Binding var accountCreated:Bool
    
    @State var privacyPolicyButtonText = "Read and agree to the privacy policy"
    
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("You'll use your email address to log in. We will never share it with anyone.")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                }
                Section(footer: Text("This is the name that will appear in the tower when you're ringing. You can change it later.")) {
                    TextField("Username", text: $username)
                        .textContentType(.nickname)
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
                .navigationBarItems(trailing: Button(action: {self.isPresented = false}) {Text("Back").bold()})
        }
    .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func createAccount() {
        if email.trimmingCharacters(in: .whitespaces).isNotValidEmail() {
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
        CommunicationController.registerNewUser(username: username, email: email, password: password, sender: self)
    }
    
    func receivedResponse(statusCode:Int? = nil, response:String) {
        print(statusCode, response)
       // accountCreated = true
      //  isPresented = false
    }
    
    func passwordsDontMatch(passwords:[String]) -> Bool {
        return !(passwords[0] == passwords[1])
    }
    
}

public extension String {
    func isNotValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return !emailPred.evaluate(with: self)
    }
}
