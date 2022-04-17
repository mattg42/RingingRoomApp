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
                    Button("Request password reset") {
                        self.resetPassword()
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
    
    func resetPassword() {
        email = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !email.isValidEmail() else {
            AlertHandler.emailNotValid()
            return
        }
        APIService.resetPassword(email: email)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                default:
                    break
                }
            } receiveValue: { _ in
                AlertHandler.resetPasswordRequestSent()
            }
            .store()
    }
}
