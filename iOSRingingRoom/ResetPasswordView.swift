//
//  forgotPasswordView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct ResetPasswordView: View {
    
    @Binding var isPresented:Bool
    @Binding var email:String
            
    var cc = CommunicationController(sender: nil)
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton = Alert.Button.cancel()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                }
                Section {
                    Button("Request password reset") {
                        self.resetPassword()
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage))
                    }
                }
            }
            .navigationBarTitle("Reset Password", displayMode: .inline)
            .navigationBarItems(trailing: Button("Back") {self.isPresented = false})
        }
    .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func resetPassword() {
        if !email.trimmingCharacters(in: .whitespaces).isValidEmail() {
            alertTitle = "Email not valid"
            alertMessage = "Please enter a valid email address."
            showingAlert = true
            return
        } else {
            cc.resetPassword(email: email)
            alertTitle = "Request sent"
            alertMessage = "Check your email for the instructions to reset your password."
            showingAlert = true
        }
    }
}
