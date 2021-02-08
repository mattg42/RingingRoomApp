//
//  SimpleLoginView.swift
//  iOSRingingRoom
//
//  Created by Matthew on 06/09/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//

import SwiftUI
import Network

struct SimpleLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var comController:CommunicationController!

    @State private var email = ""
    @State private var password = ""
    @State private var stayLoggedIn = false
    
    @Binding var loggedIn:Bool
    
    @State private var validEmail = false
    @State private var validPassword = false
    
    var loginDisabled:Bool {
        get {
            !(validEmail && validPassword)
        }
    }
    
    @State private var showingAccountCreationView = false
    @State private var showingResetPasswordView = false
                
    @State private var accountCreated = false
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton = Alert.Button.cancel()
        
    var monitor = NWPathMonitor()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                TextField("Email", text: $email)
                .onChange(of: email, perform: { _ in
                    validEmail = email.trimmingCharacters(in: .whitespaces).isValidEmail()
                })
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: self.$password)
                    .onChange(of: password, perform: { _ in
                        validPassword = password.count > 0
                    })
                    .autocapitalization(.none)
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
                    Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: alertCancelButton)
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
                    }.sheet(isPresented: $showingAccountCreationView, onDismiss: {if self.accountCreated {self.login()}}) {
                        AccountCreationView(isPresented: self.$showingAccountCreationView, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
                    }
                }
                .accentColor(Color.main)
            }
            .padding()
            .navigationBarItems(leading: Button("Back") {self.presentationMode.wrappedValue.dismiss()})
            .navigationBarTitle("Login", displayMode: .inline)
        }
    .onAppear(perform: {
        self.comController = CommunicationController(sender: self, loginType: .simple)
        monitor.start(queue: DispatchQueue.monitor)
    })
    }
    
    
    func unknownErrorAlert() {
        alertTitle = "Error"
        alertMessage = "An unknown error occured."
        alertCancelButton = .cancel(Text("OK"))
        showingAlert = true
    }
    
    func incorrectCredentialsAlert() {
        alertTitle = "Credentials error"
        alertMessage = "Your username or password is incorrect."
        alertCancelButton = .cancel(Text("OK"))
        self.showingAlert = true
    }
    
    func noInternetAlert() {
        alertTitle = "Connection error"
        alertMessage = "Your device is not connected to the internet. Please check your internet connection and try again."
        alertCancelButton = .cancel(Text("Try again"), action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: login)
        })
        showingAlert = true
    }
    
    func login() {
        hideKeyboard()
        if monitor.currentPath.status == .satisfied || monitor.currentPath.status == .requiresConnection {
            print("sent login request")
            comController.login(email: self.email.trimmingCharacters(in: .whitespaces), password: self.password)
        } else {
            print("path unsatisfied")
            noInternetAlert()
        }
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            incorrectCredentialsAlert()
        } else if statusCode == 200 {
            DispatchQueue.main.async {
                self.comController.getUserDetails()
                self.comController.getMyTowers()
                self.presentationMode.wrappedValue.dismiss()
            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            unknownErrorAlert()
        } else {
            UserDefaults.standard.set(self.stayLoggedIn, forKey: "keepMeLoggedIn")
            UserDefaults.standard.set(self.email, forKey: "userEmail")
            UserDefaults.standard.set(self.password, forKey: "userPassword")
            UserDefaults.standard.set(0, forKey: "selectedTower")
            self.loggedIn = true
//            self.presentationMode.wrappedValue.dismiss()
//            print("tried to dismiss")
        }
    }
    
}
