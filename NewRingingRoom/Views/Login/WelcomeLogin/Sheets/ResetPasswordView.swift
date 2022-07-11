//
//  forgotPasswordView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct ResetPasswordView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var viewModel: LoginViewModel
    
    @Binding var email:String
    
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
                    AsyncButton("Request password reset") {
                        await resetPassword()
                    }
                }
            }
            .navigationBarTitle("Reset Password", displayMode: .inline)
            .navigationBarItems(trailing: Button("Back") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func resetPassword() async {
        email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard email.isValidEmail() else {
            AlertHandler.handle(error: LoginError.emailNotValid)
            return
        }
        
        await viewModel.apiService.resetPassword(email: email)

        AlertHandler.presentAlert(title: "Request sent", message: "Check your email for the instructions to reset your password.", dismiss: .cancel(title: "Ok", action: nil))
    }
}
