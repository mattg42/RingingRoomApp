//
//  SimpleLoginView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 06/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI

struct SimpleLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    

    @State var email = ""
    @State var password = ""
    @State var stayLoggedIn = false
    
    @Binding var loggedIn:Bool
    
    @State var loginDisabled = true
    
    @State var showingAccountCreationView = false
    @State var showingResetPasswordView = false
                
    @State private var accountCreated = false
    
    @State var showingAlert = false
    @State var alertTitle = Text("")
    @State var alertMessage:Text? = nil
        
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                TextField("Email", text: $email, onEditingChanged: { selected in
                    if !selected {
                        self.textFieldCommitted()
                    }
                })
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: self.$password, onCommit: {
                    self.textFieldCommitted()
                })
                    .textContentType(.password)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Toggle(isOn: $stayLoggedIn) {
                    Text("Keep me logged in")
                }
                .padding(.vertical, 7)
                Button(action: login) {
                    ZStack {
                        Color.main
                            .cornerRadius(5)
                            .opacity(loginDisabled ? 0.35 : 1)
                        Text("Login")
                            .foregroundColor(Color(.white))
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: self.alertTitle, message: self.alertMessage, dismissButton: .default(Text("OK")))
                }
                .frame(height: 43)
                .disabled(loginDisabled)
                Spacer()
                HStack(alignment: .center, spacing: 0.0) {
                    Button(action: {self.showingResetPasswordView = true}) {
                        Text("Forgot password?")
                            .font(.footnote)
                    }.sheet(isPresented: $showingResetPasswordView) {
                        resetPasswordView(isPresented: self.$showingResetPasswordView, email: self.$email)
                    }
                    
                    Spacer()
                    Button(action: { self.showingAccountCreationView = true } ) {
                        Text("Create an account")
                            .font(.footnote)
                    }.sheet(isPresented: $showingAccountCreationView, onDismiss: {if self.accountCreated {self.login()} else {self.textFieldCommitted()}}) {
                        AccountCreationView(isPresented: self.$showingAccountCreationView, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
                    }
                }
                .foregroundColor(Color(red: 178/255, green: 39/255, blue: 110/255))
            }
            .padding()
            .navigationBarItems(leading: Button("Back") {self.presentationMode.wrappedValue.dismiss()})
            .navigationBarTitle("Login", displayMode: .inline)
        }
    }
    
    func textFieldCommitted() {
        if !email.isNotValidEmail() {
            if !(self.password == "") {
                loginDisabled = false
            } else {
                loginDisabled = true
            }
        } else {
            loginDisabled = true
        }
    }

    
    func login() {
        //send login request to server
  //     presentMainApp()
    }
}
