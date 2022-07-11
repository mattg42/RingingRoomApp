//
//  WelcomeLoginView.swift
//  NewRingingRoom
//
//  Created by Matthew on 08/08/2021.
//

import Foundation
import SwiftUI

enum ActiveLoginSheet: Identifiable {
    case forgotPassword, createAccount
    
    var id: Int {
        hashValue
    }
}

struct WelcomeLoginView: View {
    
    @EnvironmentObject var viewModel: LoginViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor:Color {
        get {
            if colorScheme == .light {
                return Color(red: 211/255, green: 209/255, blue: 220/255)
            } else {
                return Color(white: 0.085)
            }
        }
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var stayLoggedIn = false
    
    @State private var autoJoinTower = false
    @State private var autoJoinTowerID = 0
    
    @State private var validEmail = false
    @State private var validPassword = false
    
    var loginDisabled:Bool {
        get {
            !(validEmail && validPassword)
        }
    }
    
    @State private var showingAccountCreationView = false
    @State private var showingResetPasswordView = false
    
    @State private var loginScreenIsActive = true
    
    @State private var accountCreated = false
    
    var monitor = NetworkStatus.shared.monitor
    
    @State private var activeLoginSheet: ActiveLoginSheet? = nil
    
    @State var showingServers = false
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all) //background view
            VStack {
                Group {
                    Spacer()
                    VStack {
                        Text("Welcome to")
                        Text("Ringing Room")
                            .font(Font.custom("Simonetta-Regular", size: 55, relativeTo: .title))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.bottom, 1)
                        Text("A virtual belltower")
                    }
                }
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
                SecureField("Password", text: $password)
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
                .toggleStyle(SwitchToggleStyle(tint: .main))
                DisclosureGroup(
                    
                    isExpanded: $showingServers,
                    
                    content: {
                        VStack {
                            ForEach(Region.allCases.sorted(), id: \.self) { region in
                                if region != viewModel.apiService.region {
                                    Button(action: {
                                        viewModel.apiService.region = region
                                        withAnimation {
                                            showingServers = false
                                        }
                                    }) {
                                        HStack {
                                            Spacer()
                                            
                                            Text(region.displayName)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 1)
                        }
                        .padding(.top, 5)
                    },
                    label: {
                        HStack {
                            Text("Server")
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showingServers.toggle()
                                }
                            }) {
                                Text(viewModel.apiService.region.displayName)
                            }
                        }
                        
                    }
                )
                Button {
                    Task {
                        await viewModel.login(email: email.lowercased(), password: password)
                    }
                } label: {
                    ZStack {
                        Color.main
                            .cornerRadius(5)
                            .opacity(loginDisabled ? 0.35 : 1)
                        Text("Login")
                            .foregroundColor(Color(.white))
                            .padding(10)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .disabled(loginDisabled)
                HStack {
                    Button(action: {
                        self.activeLoginSheet = .forgotPassword; self.loginScreenIsActive = false
                    }) {
                        Text("Forgot password?")
                            .font(.callout)
                    }
                    
                    Spacer()
                    Button(action: { self.activeLoginSheet = .createAccount; self.loginScreenIsActive = false} ) {
                        Text("Create an account")
                            .font(.callout)
                    }
                }
                .accentColor(Color.main)
            }
            .padding()
        }
        .sheet(item: $activeLoginSheet, onDismiss: {
            self.loginScreenIsActive = true
            if self.accountCreated {
                Task {
                    await self.viewModel.login(email: email, password: password)
                }
            }
        }, content: { item in
            switch item {
            case .forgotPassword:
                ResetPasswordView(email: self.$email)
                    .accentColor(Color.main)
            case .createAccount:
                AccountCreationView(email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
            }
        })
        .onOpenURL(perform: { url in
            let pathComponents = Array(url.pathComponents.dropFirst())
            print(pathComponents)
            if pathComponents.first ?? "" == "privacy" {
                UIApplication.shared.open(url)
            }
        })
    }
}
