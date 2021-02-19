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
import NotificationCenter
import Network

struct WelcomeLoginScreen: View {
//    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
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
    
    @State private var comController:CommunicationController!
    
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
    
    @State private var monitor = NWPathMonitor()
    
    @State private var isUsingDevServer = UserDefaults.standard.bool(forKey: "useDevServer")
    
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
                    Toggle(isOn: $isUsingDevServer) {
                        Text("Use dev server")
                    }
                    .onChange(of: isUsingDevServer, perform: { value in
                        if isUsingDevServer {
                            CommunicationController.baseUrl = "https:/dev.ringingroom.com/api/"
                            UserDefaults.standard.setValue(value, forKey: "useDevServer")
                        } else {
                            CommunicationController.baseUrl = "https:/ringingroom.com/api/"
                            UserDefaults.standard.setValue(value, forKey: "useDevServer")

                        }
                    })
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
                        Button(action: {self.showingResetPasswordView = true; self.loginScreenIsActive = false}) {
                            Text("Forgot password?")
                                .font(.footnote)
                        }.sheet(isPresented: $showingResetPasswordView, onDismiss: {self.loginScreenIsActive = true}) {
                            resetPasswordView(isPresented: self.$showingResetPasswordView, email: self.$email)
                        }
                        
                        Spacer()
                        Button(action: { self.showingAccountCreationView = true; self.loginScreenIsActive = false} ) {
                            Text("Create an account")
                                .font(.footnote)
                        }.sheet(isPresented: $showingAccountCreationView, onDismiss: {self.loginScreenIsActive = true; if self.accountCreated {self.login()}}) {
                            AccountCreationView(isPresented: self.$showingAccountCreationView, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
                        }
                    }
                    .accentColor(Color.main)
                    }
            .padding()
        }
        .onAppear(perform: {
            self.comController = CommunicationController(sender: self, loginType: .welcome)
            let queue = DispatchQueue.monitor
            monitor.start(queue: queue)
        })
    }
    
    func login() {
        if monitor.currentPath.status == .satisfied || monitor.currentPath.status == .requiresConnection {
            print("sent login request")
            comController.login(email: self.email.trimmingCharacters(in: .whitespaces), password: self.password)
        } else {
            print("path unsatisfied")
            noInternetAlert()
        }
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        print("status code: \(String(describing: statusCode))")
        print(responseData ?? 0)
        if statusCode! == 401 {
            incorrectCredentialsAlert()
        } else if statusCode! == 200 {
            comController.getUserDetails()
            comController.getMyTowers()
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
                UserDefaults.standard.set(self.password, forKey: "userPassword")
                AppController.shared.selectedTab = .ring
                AppController.shared.state = .main
//                self.presentMainApp()
            }
        } else {
            unknownErrorAlert()
        }
    }
    
    func presentMainApp() {
        //present main ringingroom view

//        self.viewControllerHolder?.present(style: .fullScreen, name: "Main") {
//            MainApp(autoJoinTower: autoJoinTower, autoJoinTowerID: autoJoinTowerID)
//        }
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

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeLoginScreen()
    }
}

//struct ViewControllerHolder {
//    weak var value: UIViewController?
//}
//
//struct ViewControllerKey: EnvironmentKey {
//    static var defaultValue: ViewControllerHolder {
//        return ViewControllerHolder(value: UIApplication.shared.windows.first?.rootViewController)
//        
//    }
//}
//
//extension EnvironmentValues {
//    var viewController: UIViewController? {
//        get { return self[ViewControllerKey.self].value }
//        set { self[ViewControllerKey.self].value = newValue }
//    }
//}
//
//extension UIViewController {
//    func present<Content: View>(style: UIModalPresentationStyle = .automatic, name:String, animated:Bool = false, @ViewBuilder builder: () -> Content) {
//        let toPresent = UIHostingController(rootView: AnyView(EmptyView()))
//        toPresent.modalPresentationStyle = style
//        toPresent.rootView = AnyView(
//            builder()
//                .environment(\.viewController, toPresent)
//        )
//        print("blank")
//        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "dismiss\(name)"), object: nil, queue: nil) { [weak toPresent] _ in
//            toPresent?.dismiss(animated: false, completion: nil)
//        }
//        if name == "RingingRoom" {
//            if BellCircle.current.ringingroomIsPresented == false {
//                BellCircle.current.ringingroomIsPresented = true
//            print("\n-=-=-=-=-=-=-=-Presented RR-=-=-=-=-=-=-=-=-=-=-=\n")
//            } else {
//                return
//            }
//        }
//        self.present(toPresent, animated: animated, completion: nil)
//        print("presented \(name)")
//    }
//}




