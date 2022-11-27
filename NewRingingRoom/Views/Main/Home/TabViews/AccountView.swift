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
    
    @State var presentingAlert = false
    
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
                        Button {
                            presentingAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Log out")
                                Spacer()
                            }
                        }
                        .alert(isPresented: $presentingAlert) {
                            Alert(
                                title: Text("Are you sure you want to log out?"),
                                message: nil,
                                primaryButton: .destructive(Text("Yes"), action: self.logout),
                                secondaryButton: .cancel(Text("Cancel"), action: { presentingAlert = false })
                            )
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
