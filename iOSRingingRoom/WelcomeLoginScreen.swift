//
//  LoginScreen.swift
//  NativeRingingRoom
//
//  Created by Matthew Goodship on 03/08/2020.
//  Copyright © 2020 Matthew Goodship. All rights reserved.
//
//  This view is displayed the first time users open the app after downloading
//  It lets users login or continue anonymously, and provides ways for users to create an account or reset their password

import SwiftUI
import Combine
import Network

enum ActiveLoginSheet: Identifiable {
    case privacy, forgotPassword, createAccount
    
    var id: Int {
        hashValue
    }
}

struct WelcomeLoginScreen: View {
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
    
//    @State private var comController:CommunicationController!
    
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
    
    @State private var buffer:CGFloat = 0
    
    let screenHeight = UIScreen.main.bounds.height
    @State private var imageSize = 0
    
    @State private var loginScreenIsActive = true
    
    @State private var accountCreated = false
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCancelButton = Alert.Button.cancel()
    
//    @State private var monitor = NWPathMonitor()
    
    var monitor = NetworkStatus.shared.monitor
    
    @State private var activeLoginSheet:ActiveLoginSheet? = nil
                
    var servers = ["/":"UK","/na.":"North America","/sg.":"Singapore","/anzab.":"ANZAB"]
    
    @State var serverSelect = UserDefaults.standard.string(forKey: "server") ?? (UserDefaults.standard.bool(forKey: "NA") ? "/na." : "/")
    
    @State var showingServers = false
    

    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all) //background view
            VStack {
                Group {
                Spacer()
//                ScrollView {
                    VStack {
                        Text("Welcome to")
                        //                            .font(.headline)
                        //                            .fontWeight(.light)
                        Text("Ringing Room")
                            .font(Font.custom("Simonetta-Regular", size: 55, relativeTo: .title))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.bottom, 1)
                        Text("A virtual belltower")
                        //                            .font(.headline)
                        //                            .fontWeight(.light)
                    }
//                    Image("dncbLogo").resizable()
//                        .frame(minWidth: 170, idealWidth: 350, minHeight: 170, idealHeight: 350)
//                        .layoutPriority(2)
//                        .scaledToFit()
                }
                Spacer()

//            }
//                .disabled(true)
//            VStack {
//                Spacer()
//                GeometryReader { geo in
//                    VStack {
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
                            ForEach(Array(servers.keys).sorted(), id: \.self) { server in
                                if server != serverSelect {
                                Button(action: {
                                    NetworkManager.server = server
                                    serverSelect = server
                                    UserDefaults.standard.set(server, forKey: "server")
                                    withAnimation {
                                        showingServers = false
                                    }
                                }) {
                                    HStack {
                                        Spacer()

                                        Text(servers[server]!)
                                    }
                                }
    //                            .padding(.vertical, 1)
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
                                Text(servers[serverSelect]!)
                            }
                        }

                    }
                )
//
                    Button(action: login) {
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
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text(self.alertTitle), message: Text(self.alertMessage), dismissButton: alertCancelButton)
                    }
//                    Button(action: presentMainApp) {
//                        ZStack {
//                            Color(red: 178/255, green: 39/255, blue: 110/255)
//                                .cornerRadius(5)
//                            Text("Continue as listener only")
//                                .foregroundColor(Color(.white))
//                                .padding(4)
//                        }
//                    }
//                    .fixedSize(horizontal: false, vertical: true)
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
                self.login()
            }
        }, content: { item in
            switch item {
            case .privacy:
                PrivacyPolicyWebView(isPresented: .init(get: {self.activeLoginSheet == .privacy}, set: {if !$0 {self.activeLoginSheet = nil}}))
                .accentColor(.main)
            case .forgotPassword:
            ResetPasswordView(isPresented: .init(get: {self.activeLoginSheet == .forgotPassword}, set: {if !$0 {self.activeLoginSheet = nil}}), email: self.$email).accentColor(Color.main)
            case .createAccount:
                AccountCreationView(isPresented: .init(get: {self.activeLoginSheet == .createAccount}, set: {if $0 {self.activeLoginSheet = nil}}), email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
            }
        })
        .onOpenURL(perform: { url in
            let pathComponents = Array(url.pathComponents.dropFirst())
            print(pathComponents)
            if pathComponents.first ?? "" == "privacy" {
                activeLoginSheet = .privacy
            }
        })
    }
    
    func login() {
//        print(CommunicationController.server)
//        CommunicationController.server = serverSelect
        if monitor?.currentPath.status == .satisfied || monitor?.currentPath.status == .requiresConnection {
            print("sent login request")
            NetworkManager.sendRequest(request: .login(email: email.trimmingCharacters(in: .whitespaces), password: password)) { json, response, error in
                if let json = json {
                    receivedResponse(statusCode: response?.statusCode, response: json)
                }
            }
//            comController.login(email: self.email.trimmingCharacters(in: .whitespaces), password: self.password)
        } else {
            print("path unsatisfied")
            noInternetAlert()
        }
    }
    
    func receivedResponse(statusCode:Int?, response:[String:Any]) {
        if statusCode == 401 {
            incorrectCredentialsAlert()
        } else if statusCode == 200 {
            NetworkManager.token = response["token"] as? String
            NetworkManager.sendRequest(request: .getUserDetails()) { (json, response, error) in
                if let json = json {
                    User.shared.name = json["username"] as! String
                }
            }
            NetworkManager.sendRequest(request: .getMyTowers()) { (json, response, error) in
                if let json = json as? [String: [String:Any]] {
                    DispatchQueue.main.async {
                        User.shared.myTowers = [Tower(id: 0, name: "", host: 0, recent: 0, visited: "", creator: 0, bookmark: 0)]
                        User.shared.firstTower = true
                    }
                    for dict in json {
                        print(dict)
                        if dict.key != "0" {
                            var tower:Tower? = nil
                            if let id = dict.value["tower_id"] as? Int {
                                tower = Tower(id: id, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
                            } else {
                                tower = Tower(id: Int(dict.value["tower_id"] as! String)!, name: dict.value["tower_name"] as! String, host: dict.value["host"] as! Int, recent: dict.value["recent"] as! Int, visited: dict.value["visited"] as! String, creator: dict.value["creator"] as! Int, bookmark: dict.value["bookmark"] as! Int)
                                
                            }
                            if tower != nil {
                                DispatchQueue.main.async {
                                    User.shared.addTower(tower!)
                                }
                               
                            }
                        }
                    }
                    print(User.shared.myTowers.names)
                    DispatchQueue.main.async {
                        User.shared.sortTowers()
                    }
                    receivedMyTowers(statusCode: response?.statusCode, responseData: json)
                }
            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            incorrectCredentialsAlert()
        } else if statusCode! == 200 {
            DispatchQueue.main.async {
                UserDefaults.standard.set(self.stayLoggedIn, forKey: "keepMeLoggedIn")
                UserDefaults.standard.set(self.email, forKey: "userEmail")
                User.shared.email = email
                User.shared.password = password
                let kcw = KeychainWrapper()
                do {
                    try kcw.storePasswordFor(account: self.email, password: self.password)
                } catch {
                    print("error saving password")
                }
                AppController.shared.selectedTab = .ring
                AppController.shared.state = .main
            }
        } else {
            unknownErrorAlert()
        }
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
    
    
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeLoginScreen()
    }
}
