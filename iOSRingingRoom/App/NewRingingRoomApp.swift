//
//  NewRingingRoomApp.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import SwiftUI
import Combine
import AVFoundation

@MainActor
class Router<Route>: ObservableObject {
    init(defaultRoute: Route) {
        currentRoute = defaultRoute
    }
    
    @Published var currentRoute: Route
    
    func moveTo(_ newRoute: Route) {
        ThreadUtil.runInMain {
            self.currentRoute = newRoute
        }
    }
}

enum AppRoute {
    case login
    case main(user: User, apiService: APIService, route: MainRoute)
}

enum MainRoute {
    case home
    case ringing(viewModel: RingingRoomViewModel)
    case joinTower(towerID: Int, towerDetails: APIModel.TowerDetails?)
}

enum AppDeepLink: Equatable {
    case privacy
    case tower(towerID: Int)

    init?(url: URL) {
        let pathComponents = Array(url.pathComponents.dropFirst())
        guard pathComponents.count == 1, let firstPath = pathComponents.first else {
            return nil
        }

        if firstPath == "privacy" {
            self = .privacy
        } else if let towerID = Int(firstPath), towerID > 0 {
            self = .tower(towerID: towerID)
        } else {
            return nil
        }
    }
}

@MainActor
final class PendingDeepLinkRouter: ObservableObject {
    @Published private(set) var pendingTowerID: Int?

    @discardableResult
    func receive(_ url: URL) -> AppDeepLink? {
        guard let deepLink = AppDeepLink(url: url) else {
            AppLogger.navigation.debug("Ignoring unsupported deep link")
            return nil
        }

        if case .tower(let towerID) = deepLink {
            pendingTowerID = towerID
        }

        return deepLink
    }

    func consumeTowerID() -> Int? {
        defer { pendingTowerID = nil }
        return pendingTowerID
    }
}

@main
struct RingingRoomApp: App {
        
    init() {
        let freshInstall = !UserDefaults.standard.bool(forKey: "alreadyInstalled")
        if freshInstall {
            UserDefaults.standard.set(true, forKey: "alreadyInstalled")
        }
        
    }
    
    @StateObject var router = Router<AppRoute>(defaultRoute: .login)
    @StateObject private var pendingDeepLinkRouter = PendingDeepLinkRouter()
    @State private var showingPrivacyPolicy = false
    @ObservedObject var monitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            Group {
                switch router.currentRoute {
                case .login:
                    LoginOverview()
                case .main(let user, let apiService, let route):
                    MainView(user: user, apiService: apiService, route: route)
                }
            }
            .tint(Color.main)
            .environmentObject(router)
            .environmentObject(monitor)
            .environmentObject(pendingDeepLinkRouter)
            .onOpenURL { url in
                guard let deepLink = pendingDeepLinkRouter.receive(url) else { return }

                switch deepLink {
                case .privacy:
                    showingPrivacyPolicy = true
                case .tower:
                    AppLogger.navigation.debug("Received tower deep link")
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyWebView(isPresented: $showingPrivacyPolicy)
            }
        }
    }
}
