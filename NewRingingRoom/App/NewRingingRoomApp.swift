//
//  NewRingingRoomApp.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import SwiftUI
import Combine

class AppRouter: ObservableObject {
    @Published var currentModule: AppModule = .login
        
    func moveTo(_ newModule: AppModule) {
        ThreadUtil.runInMain {
            self.currentModule = newModule
        }
    }
}

enum AppModule {
    case login
    case main
    case ringing
}

@main
struct NewRingingRoomApp: App {
        
    init() {
        let freshInstall = !UserDefaults.standard.bool(forKey: "alreadyInstalled")
        if freshInstall {
            KeychainService.clear()
            UserDefaults.standard.set(true, forKey: "alreadyInstalled")
        }
    }
    
    @StateObject var router = AppRouter()
    @StateObject var user = User()
        
    var body: some Scene {
        WindowGroup {
            Group {
                switch router.currentModule {
                case .login:
                    LoginOverview()
                case .main:
                    MainOverview()
                case .ringing:
                    RingingView()
                }
            }
            .tint(Color.main)
            .environmentObject(router)
            .environmentObject(user)
        }
    }
}

struct MainOverview: View {
    var body: some View {
        Text("Main")
    }
}

struct RingingView: View {
    var body: some View {
        Text("Ringing")
    }
}
