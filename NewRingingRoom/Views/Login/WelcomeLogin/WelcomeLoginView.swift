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
    
    enum TextFields {
        case email, password
    }
        
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var router: Router<AppRoute>

    var backgroundColor: Color {
        if colorScheme == .light {
            return Color(red: 211/255, green: 209/255, blue: 220/255)
        } else {
            return Color(white: 0.085)
        }
    }
    
    @State private var authenticationService = AuthenticationService()
    
    @State private var email = ""
    @State private var password = ""
    @State private var stayLoggedIn = false
    
    @State private var autoJoinTowerID = 0
    
    @State private var validEmail = false
    @State private var validPassword = false
    
    private var loginDisabled: Bool {
        !(validEmail && validPassword)
    }
    
    @State private var showingAccountCreationView = false
    @State private var showingResetPasswordView = false
    
    @State private var loginScreenIsActive = true
    
    @State private var accountCreated = false
        
    @State private var activeLoginSheet: ActiveLoginSheet? = nil
    
    @State private var showingServers = false
    
    @FocusState private var focused: TextFields?
    
    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
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
                        validEmail = email
                            .trimmingCharacters(in: .whitespaces)
                            .isValidEmail()
                    })
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focused, equals: .email)
                
                SecureField("Password", text: $password)
                    .onChange(of: password, perform: { _ in
                        validPassword = password.count > 0
                    })
                    .autocapitalization(.none)
                    .textContentType(.password)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focused, equals: .password)
                
                Toggle(isOn: $stayLoggedIn) {
                    Text("Keep me logged in")
                }
                .toggleStyle(SwitchToggleStyle(tint: .main))
                
                HStack {
                    Text("Server")
                    
                    Spacer()
                    Picker(authenticationService.region.displayName, selection: $authenticationService.region) {
                        ForEach(Region.allCases.sorted()) { region in
                            Text(region.displayName)
                                .tag(region)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                AsyncButton(progressViewColor: .white, progressViewPadding: 10) {
                    await login()
                } label: {
                    Text("Login")
//                        .padding(.vertical, 5)
                } background: {
                    Color.main
                        .cornerRadius(5)
                        .opacity(loginDisabled ? 0.35 : 1)
                }
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .foregroundColor(.white)
                .disabled(loginDisabled)
                
                HStack {
                    Button {
                        activeLoginSheet = .forgotPassword
                        loginScreenIsActive = false
                    } label: {
                        Text("Forgot password?")
                            .font(.callout)
                    }
                    
                    Spacer()
                    
                    Button {
                        activeLoginSheet = .createAccount
                        loginScreenIsActive = false
                    } label: {
                        Text("Create an account")
                            .font(.callout)
                    }
                }
                .accentColor(Color.main)
            }
            .padding()
        }
        .sheet(item: $activeLoginSheet, onDismiss: {
            loginScreenIsActive = true
            if accountCreated {
                Task {
                    await login()
                }
            }
        }, content: { item in
            switch item {
            case .forgotPassword:
                ResetPasswordView(email: $email)
                    .accentColor(Color.main)
            case .createAccount:
                AccountCreationView(email: $email, password: $password, accountCreated: $accountCreated)
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
    
    func login() async {
        focused = nil
        await ErrorUtil.do(networkRequest: true) {
            let (user, apiService) = try await authenticationService.login(email: email.lowercased(), password: password)
            
            UserDefaults.standard.set(stayLoggedIn, forKey: "keepMeLoggedIn")
            
            if stayLoggedIn {
                UserDefaults.standard.set(email, forKey: "userEmail")
                try KeychainService.storePasswordFor(account: email, password: password, server: authenticationService.domain)
            }
            
            router.moveTo(.main(user: user, apiService: apiService, route: .home))
        }
    }
}
