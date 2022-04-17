//
//  AutoLoginView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/08/2021.
//

import SwiftUI

struct AutoLoginView: View {
        
    @EnvironmentObject var viewModel: LoginViewModel
    
    @State private var autoJoinTowerID = 0
    
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
        .onAppear(perform: {
            login()
        })
    }
        
    func login() {
        
        guard viewModel.apiService.token == nil else { return }
        
        print("sent login request")
        let email = UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces)
        
        //remove in next beta version
        let savedPassword = UserDefaults.standard.string(forKey: "userPassword") ?? ""
        let kcw = KeychainUtils()
        
        if UserDefaults.standard.string(forKey: "server") == nil {
            let value = UserDefaults.standard.bool(forKey: "NA")
            
            if value {
                UserDefaults.standard.setValue("/na.", forKey: "server")
            } else {
                UserDefaults.standard.setValue("/", forKey: "server")
            }
        }
        
        if savedPassword != "" {
            do {
                try kcw.storePasswordFor(account: email, password: savedPassword)
            } catch {
                print("error saving password to keychain")
            }
            UserDefaults.standard.setValue("", forKey: "userPassword")
        }
        
        do {
            let password = try kcw.getPasswordFor(account: email)
            User.shared.email = email
            User.shared.password = password
            print("retrieved password")
        
            if autoJoinTowerID != 0 {
                viewModel.login(email: email, password: password, withTowerID: autoJoinTowerID)
            } else {
                viewModel.login(email: email, password: password)
            }
        } catch {
            AlertHandler.unknownError(message: "")
        }
    }
}

struct AutoLoginView_Previews: PreviewProvider {
    static var previews: some View {
        AutoLoginView()
    }
}
