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
    
    @State var comController:CommunicationController!
    
    @State var email = ""
    @State var password = ""
    @State var stayLoggedIn = false
    
    @State var loginDisabled = true
    
    @State var showingAccountCreationView = false
    @State var showingResetPasswordView = false
    
    @State var passwordFieldYPosition:CGFloat = 0
    @State var keyboardHeight:CGFloat = 0
    
    let screenHeight = UIScreen.main.bounds.height
    
    @State var loginScreenIsActive = true
    
    @State private var accountCreated = false
    
    @State var showingAlert = false
    @State var alertTitle = Text("")
    @State var alertMessage:Text? = nil
    
    
    var body: some View {
        ZStack {
            Color(red: 211/255, green: 209/255, blue: 220/255)
                .edgesIgnoringSafeArea(.all) //background view
            VStack(spacing: 0) {
                Spacer()
                VStack() {
                    Text("Welcome to")
                        .font(.headline)
                        .fontWeight(.light)
                        .padding(.bottom, -7)
                    Text("Ringing Room")
                        .font(Font.custom("Simonetta-Regular", size: 55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.bottom, 5)
                    Text("A virtual belltower")
                        .font(.headline)
                        .fontWeight(.light)
                }
                Spacer(minLength: 13)
                Image("dncbLogo").resizable()
                    .frame(minWidth: 170, maxWidth: 350, minHeight: 170, maxHeight: 350)
                    .scaledToFit()
                Spacer(minLength: 13)
                VStack(spacing: 10) {
                    TextField("Email", text: $email, onEditingChanged: { selected in
                        if !selected {
                            self.emailTextfieldChanged()
                        }
                    })
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(5.0)
                    GeometryReader { geo in
                        SecureField("Password", text: self.$password)
                            .textContentType(.password)
                            .disableAutocorrection(true)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(5.0)
                            .onAppear(perform: {
                                var pos = geo.frame(in: .global).midY
                                pos += geo.frame(in: .global).height*2
                                pos = UIScreen.main.bounds.height - pos
                                print("performed", pos)
                                
                                self.passwordFieldYPosition = pos
                            })
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    
                }
                
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
                .frame(height: 43)
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
                    }
                }
                .frame(height: 32)
                .padding(.vertical, 8)
                HStack(alignment: .center, spacing: 0.0) {
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
                    }.sheet(isPresented: $showingAccountCreationView, onDismiss: {self.loginScreenIsActive = true; if self.accountCreated {self.login()} else {self.emailTextfieldChanged()}}) {
                        AccountCreationView(isPresented: self.$showingAccountCreationView, email: self.$email, password: self.$password, accountCreated: self.$accountCreated)
                    }
                }
                .foregroundColor(Color(red: 178/255, green: 39/255, blue: 110/255))
                .padding(.bottom, 10)
                
            }
            .padding(.horizontal, 15)
        }
    .onAppear(perform: {
        self.comController = CommunicationController(sender: self, loginType: .welcome)
    })
        .offset(y: loginScreenIsActive ? getOffset() : 0)
        .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
        .animation(.easeOut(duration: 0.16))
    }
    
    func emailTextfieldChanged() {
        if !email.isNotValidEmail() {
            loginDisabled = false
        } else {
            loginDisabled = true
        }
    }
    
    func getOffset() -> CGFloat {
        if keyboardHeight < 260 { //to stop the view being offset on launch when launced from spotlight
            return 0
        } else {
            let offset = keyboardHeight - passwordFieldYPosition
            print("offset: ",offset)
            if offset <= 0 {
                return 0
            } else {
                return -offset
            }
        }
    }
    
    func login() {
        comController.login(email: self.email, password: self.password)
        //send login request to server
  //     presentMainApp()
    }
    
    func receivedResponse(statusCode:Int?, responseData:[String:Any]?) {
        print("status code: \(statusCode)")
        print(responseData)
        if statusCode! == 401 {
            print("unauth")
            alertTitle = Text("Your username or password is incorrect")
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
            MainApp()
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
        print()
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "dismiss\(name)"), object: nil, queue: nil) { [weak toPresent] _ in
            toPresent?.dismiss(animated: false, completion: nil)
        }
        self.present(toPresent, animated: animated, completion: nil)
    }
}




