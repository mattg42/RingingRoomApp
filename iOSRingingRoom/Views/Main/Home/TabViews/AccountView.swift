//
//  AccountView.swift
//  NewRingingRoom
//
//  Created by Matthew on 12/07/2022.
//

import Foundation
import SwiftUI

struct AccountView: View {
    
    @EnvironmentObject var router: Router<AppRoute>
    
    let user: User
    let apiService: APIService
    
    @State private var presentingAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section {
                        Text("Account settings will be available in a future version. For now, please go to ringingroom.com to change your account settings.")
                    }
                    
                    Section {
                        Toggle("Auto-rotate bell circle", isOn: Binding(get: {
                            UserDefaults.standard.optionalBool(forKey: "autoRotate") ?? true
                        }, set: {
                            UserDefaults.standard.set($0, forKey: "autoRotate")
                        }))
                        .toggleStyle(SwitchToggleStyle(tint: .main))
                    }
                    
                    Section {
                        NavigationLink("About") {
                            AboutView()
                        }
                    }
                    
                    Section {
                        Link("Visit the Ringing Room store", destination: URL(string: "https://www.redbubble.com/people/ringingroom/shop")!)
                    }
                    
                    Section {
                        Button {
                            AlertHandler.presentAlert(title: "Are you sure you want to log out?", message: nil, dismiss: .logout(action: logout))
                        } label: {
                            HStack {
                                Spacer()
                                Text("Log out")
                                Spacer()
                            }
                        }
                    }
                }
                
                VStack {
                    Spacer()
#if DEBUG
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                        .font(.callout)
#else
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                        .font(.callout)
#endif
                    Text("By Matthew Goodship")
                        .font(.callout)
                }
                .padding()
                .foregroundColor(.secondary)
            }
            .navigationBarTitle("Account")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func logout() {
        ErrorUtil.do {
            try KeychainService.deletePasswordFor(account: user.email, server: apiService.domain)
        }
                
        UserDefaults.standard.set("", forKey: "userEmail")
        UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")

        router.moveTo(.login)
    }
}
