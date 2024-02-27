//
//  NewRingingRoomApp.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import SwiftUI
import Combine
import AVFoundation

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

@main
struct RingingRoomApp: App {
        
    init() {
        let freshInstall = !UserDefaults.standard.bool(forKey: "alreadyInstalled")
        if freshInstall {
            KeychainService.clear()
            UserDefaults.standard.set(true, forKey: "alreadyInstalled")
        }
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            
            try session.setPreferredIOBufferDuration(0.002)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
        }
    }
    
    @StateObject var router = Router<AppRoute>(defaultRoute: .login)
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
        }
    }
}
