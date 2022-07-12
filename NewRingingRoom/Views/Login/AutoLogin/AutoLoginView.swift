//
//  AutoLoginView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/08/2021.
//

import SwiftUI

struct AutoLoginView: View {
    
    @EnvironmentObject var user: User
    
    @State private var autoJoinTowerID: Int?
    
    var body: some View {
        ZStack {
            Color.main
            HStack {
                Image("rrLogo").resizable()
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

        let authenticationService = AuthenticationService()
        
        let email = UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces)
        
        await ErrorUtil.alertable {
            let password = try KeychainService.getPasswordFor(account: email, server: authenticationService.domain )
            user.email = email
            user.password = password
            print("retrieved password")
            
            let token = try await authenticationService.login(email: email, password: password)
            
            if let towerID = autoJoinTowerID {
                let apiService = APIService(token: token, region: authenticationService.region)
                let details = try await apiService.getTowerDetails(towerID: towerID)
                details.
            }
        }
    }
}

struct AutoLoginView_Previews: PreviewProvider {
    static var previews: some View {
        AutoLoginView()
    }
}
