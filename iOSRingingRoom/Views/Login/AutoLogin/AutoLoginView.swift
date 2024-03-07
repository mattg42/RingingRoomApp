//
//  AutoLoginView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/08/2021.
//

import SwiftUI

struct AutoLoginView: View {
        
    @EnvironmentObject var router: Router<AppRoute>
    @EnvironmentObject var monitor: NetworkMonitor
    
    @Binding var loginState: LoginState
    
    @State private var autoJoinTowerID: Int?
    
    var body: some View {
        ZStack {
            Color.main
            
            HStack {
                Image("rrLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 256, height: 256)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onOpenURL(perform: { url in
            let pathComponents = url.pathComponents.dropFirst()
            if let firstPath = pathComponents.first {
                if let towerID = Int(firstPath) {
                    autoJoinTowerID = towerID
                }
            }
            print("opened from \(url.pathComponents.dropFirst())")
        })
        .task {
            await login()
        }
    }
        
    func login() async {
        var authenticationService = AuthenticationService()
        
        let email = UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces)
        
        await ErrorUtil.do(networkRequest: true) {
            let password: String
            
            do {
                password = try KeychainService.getPasswordFor(account: email, server: authenticationService.domain)
            } catch let error as KeychainError {
                KeychainService.clear()
                UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
                
                AlertHandler.presentAlert(title: error.alertData.title, message: error.alertData.message, dismiss: .cancel(title: "OK", action: { loginState = .welcome}))
                return
            }
            
            let authenticate = { () async -> () in
                await ErrorUtil.do {
                    let (user, apiService) = try await authenticationService.login(email: email.lowercased(), password: password)
                    
                    if let towerID = autoJoinTowerID {
                        router.moveTo(.main(user: user, apiService: apiService, route: .joinTower(towerID: towerID, towerDetails: nil)))
                    } else {
                        router.moveTo(.main(user: user, apiService: apiService, route: .home))
                    }
                }
            }
            authenticationService.retryAction = authenticate
            await authenticate()
        }
    }
}
