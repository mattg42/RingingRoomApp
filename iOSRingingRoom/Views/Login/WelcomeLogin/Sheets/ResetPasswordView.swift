//
//  forgotPasswordView.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 04/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct ResetPasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
        
    @Binding var email: String
    
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
                dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func resetPassword() async {
        email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let authenicationService = AuthenticationService()
        
        await ErrorUtil.do(networkRequest: true) {
            guard email.isValidEmail() else {
                throw LoginError.emailNotValid
            }
            
            try await authenicationService.resetPassword(email: email)
            AlertHandler.presentAlert(title: "Request sent", message: "Check your email for the instructions to reset your password.", dismiss: .cancel(title: "Ok", action: nil))
        }
    }
}
