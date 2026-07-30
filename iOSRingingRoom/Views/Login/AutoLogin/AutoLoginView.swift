//
//  AutoLoginView.swift
//  NewRingingRoom
//
//  Created by Matthew on 09/08/2021.
//

import SwiftUI

@MainActor
private final class AuthenticationRetryBox {
    var action: AsyncAction?
    var isRunning = false
}

struct AutoLoginView: View {
        
    @EnvironmentObject var router: Router<AppRoute>
    
    @Binding var loginState: LoginState
    
    @State private var autoJoinTowerID: Int?
    @State private var isAttempting = false
    
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
            AppLogger.navigation.debug("Received deep link during automatic login")
        })
        .task {
            await login()
        }
    }
        
    @MainActor
    func login() async {
        guard !isAttempting else { return }
        isAttempting = true
        defer { isAttempting = false }

        let authenticationService = AuthenticationService()
        let region = authenticationService.region
        let server = authenticationService.domain
        let retryBox = AuthenticationRetryBox()
        
        guard let storedEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
            loginState = .welcome
            return
        }

        let trimmedEmail = storedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = trimmedEmail.lowercased()
        guard !email.isEmpty else {
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
            loginState = .welcome
            return
        }

        var candidateAccounts = [storedEmail]
        if !candidateAccounts.contains(trimmedEmail) {
            candidateAccounts.append(trimmedEmail)
        }
        if !candidateAccounts.contains(email) {
            candidateAccounts.append(email)
        }

        var password: String?
        var keychainAccount: String?
        var lookupError: KeychainError?

        for account in candidateAccounts {
            do {
                password = try KeychainService.getPasswordFor(account: account, server: server)
                keychainAccount = account
                break
            } catch let error as KeychainError {
                if case .itemNotFound = error {
                    continue
                }
                lookupError = error
                break
            } catch {
                loginState = .welcome
                AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
                return
            }
        }

        guard let password, let keychainAccount else {
            for account in candidateAccounts {
                try? KeychainService.deletePasswordFor(account: account, server: server)
            }
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
            loginState = .welcome

            AlertHandler.handle(error: lookupError ?? .itemNotFound)
            return
        }

        let authenticate: AsyncAction = { @MainActor in
            guard !retryBox.isRunning else { return }
            retryBox.isRunning = true
            defer { retryBox.isRunning = false }

            var authenticationService = AuthenticationService(region: region)
            authenticationService.retryAction = retryBox.action

            do {
                let (user, apiService) = try await authenticationService.login(email: email, password: password)

                if let towerID = autoJoinTowerID {
                    router.moveTo(.main(user: user, apiService: apiService, route: .joinTower(towerID: towerID, towerDetails: nil)))
                } else {
                    router.moveTo(.main(user: user, apiService: apiService, route: .home))
                }
            } catch APIError.unauthorized {
                try? KeychainService.deletePasswordFor(account: keychainAccount, server: server)
                UserDefaults.standard.removeObject(forKey: "userEmail")
                UserDefaults.standard.set(false, forKey: "keepMeLoggedIn")
                loginState = .welcome
                AlertHandler.handle(error: APIError.unauthorized)
            } catch is CancellationError {
                loginState = .welcome
            } catch let error as Alertable {
                loginState = .welcome
                AlertHandler.handle(error: error)
            } catch {
                loginState = .welcome
                AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
            }
        }

        retryBox.action = authenticate
        await authenticate()
    }
}
