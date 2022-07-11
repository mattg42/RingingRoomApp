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
        .task {
            await login()
        }
    }
        
    func login() async {
        
        guard viewModel.apiService.token == nil else { return }
        
        print("sent login request")
        let email = UserDefaults.standard.string(forKey: "userEmail")!.trimmingCharacters(in: .whitespaces)
                
        do {
            let password = try KeychainService.getPasswordFor(account: email, server: viewModel.apiService.domain )
            User.shared.email = email
            User.shared.password = password
            print("retrieved password")
        
            if autoJoinTowerID != 0 {
                await viewModel.login(email: email, password: password, withTowerID: autoJoinTowerID)
            } else {
                await viewModel.login(email: email, password: password)
            }
        } catch let error as KeychainError {
            AlertHandler.handle(error: error)
        } catch {
            fatalError("Impossible")
        }
    }
}

struct AutoLoginView_Previews: PreviewProvider {
    static var previews: some View {
        AutoLoginView()
    }
}
