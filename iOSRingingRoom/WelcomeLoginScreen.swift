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

struct WelcomeLoginScreen: View {
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
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
    @State private var alertTitle = Text("")
    @State private var alertMessage:Text? = nil
    
    
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
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Password", text: self.$password)
                        .onChange(of: password, perform: { _ in
                            validPassword = password.count > 0
                        })
                        .textContentType(.password)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Toggle(isOn: $stayLoggedIn) {
                        Text("Keep me logged in")
                    }
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
                        Alert(title: self.alertTitle, message: self.alertMessage, dismissButton: .cancel(Text("Ok")))
                    }
                    Button(action: presentMainApp) {
                        ZStack {
                            Color(red: 178/255, green: 39/255, blue: 110/255)
                                .cornerRadius(5)
                            Text("Continue as listener only")
                                .foregroundColor(Color(.white))
                                .padding(4)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
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
        .onOpenURL { url in
            guard let towerID = url.towerID else { return }
            self.autoJoinTower = true
            self.autoJoinTowerID = towerID
        }
        .onAppear(perform: {
            self.comController = CommunicationController(sender: self, loginType: .welcome)
        })
    }
    

    
    func login() {
        comController.login(email: self.email, password: self.password)
        //send login request to server
  //     presentMainApp()
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        print("status code: \(String(describing: statusCode))")
        print(responseData ?? 0)
        if statusCode! == 401 {
            print("unauth")
            alertTitle = Text("Your email or password is incorrect")
            self.showingAlert = true
        } else {
            comController.getUserDetails()
            comController.getMyTowers()
        }
    }
    
    func receivedMyTowers(statusCode:Int?, responseData:[String:Any]?) {
        if statusCode! == 401 {
            alertTitle = Text("Error")
            self.showingAlert = true
        } else {
            DispatchQueue.main.async {
                UserDefaults.standard.set(self.stayLoggedIn, forKey: "keepMeLoggedIn")
                UserDefaults.standard.set(self.email, forKey: "userEmail")
                UserDefaults.standard.set(self.password, forKey: "userPassword")
                self.presentMainApp()
            }
        }
    }
    
    func presentMainApp() {
        //present main ringingroom view

        self.viewControllerHolder?.present(style: .fullScreen, name: "Main") {
            MainApp(autoJoinTower: autoJoinTower, autoJoinTowerID: autoJoinTowerID)
        }
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

struct ViewControllerHolder {
    weak var value: UIViewController?
}

struct ViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        return ViewControllerHolder(value: UIApplication.shared.windows.first?.rootViewController)
        
    }
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { return self[ViewControllerKey.self].value }
        set { self[ViewControllerKey.self].value = newValue }
    }
}

extension UIViewController {
    func present<Content: View>(style: UIModalPresentationStyle = .automatic, name:String, animated:Bool = false, @ViewBuilder builder: () -> Content) {
        let toPresent = UIHostingController(rootView: AnyView(EmptyView()))
        toPresent.modalPresentationStyle = style
        toPresent.rootView = AnyView(
            builder()
                .environment(\.viewController, toPresent)
        )
        print("blank")
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "dismiss\(name)"), object: nil, queue: nil) { [weak toPresent] _ in
            toPresent?.dismiss(animated: false, completion: nil)
        }
        if name == "RingingRoom" {
            if BellCircle.current.ringingroomIsPresented == false {
                BellCircle.current.ringingroomIsPresented = true
            print("\n-=-=-=-=-=-=-=-Presented RR-=-=-=-=-=-=-=-=-=-=-=\n")
            } else {
                return
            }
        }
        self.present(toPresent, animated: animated, completion: nil)
        print("presented \(name)")
    }
}




