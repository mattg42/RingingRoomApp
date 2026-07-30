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
    @EnvironmentObject private var pendingDeepLinkRouter: PendingDeepLinkRouter
    
    @Binding var loginState: LoginState
    
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

        let credentialStore = SessionCredentialStore.standard
        let storedCredentials: SessionCredentialStore.StoredCredentials
        do {
            guard let credentials = try credentialStore.load(for: server) else {
                credentialStore.disableAutomaticLogin()
                loginState = .welcome
                return
            }
            storedCredentials = credentials
        } catch let error as Alertable {
            credentialStore.clear()
            loginState = .welcome
            AlertHandler.handle(error: error)
            return
        } catch {
            credentialStore.clear()
            loginState = .welcome
            AlertHandler.presentAlert(title: "Error", message: error.localizedDescription, dismiss: .cancel(title: "Dismiss", action: nil))
            return
        }

        let email = storedCredentials.credentials.email
        let password = storedCredentials.credentials.password

        let authenticate: AsyncAction = { @MainActor in
            guard !retryBox.isRunning else { return }
            retryBox.isRunning = true
            defer { retryBox.isRunning = false }

            var authenticationService = AuthenticationService(region: region)
            authenticationService.retryAction = retryBox.action

            do {
                let (user, apiService) = try await authenticationService.login(email: email, password: password)

                if let towerID = pendingDeepLinkRouter.consumeTowerID() {
                    router.moveTo(.main(user: user, apiService: apiService, route: .joinTower(towerID: towerID, towerDetails: nil)))
                } else {
                    router.moveTo(.main(user: user, apiService: apiService, route: .home))
                }
            } catch APIError.unauthorized {
                credentialStore.clear(currentEmail: email)
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
