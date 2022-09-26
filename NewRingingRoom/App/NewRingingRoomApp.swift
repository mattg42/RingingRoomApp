//
//  NewRingingRoomApp.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import SwiftUI
import Combine
import AVFoundation

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
    case main(user: User, apiService: APIService)
    case ringing(viewModel: RingingRoomViewModel)
}

private struct APIServiceKey: EnvironmentKey {
    static let defaultValue: APIService = APIService(token: "", region: .uk)
}

extension EnvironmentValues {
    var apiService: APIService {
        get { self[APIServiceKey.self] }
        set { self[APIServiceKey.self] = newValue }
    }
}

extension View {
    func embedApiSerivce(_ apiService: APIService) -> some View {
        environment(\.apiService, apiService)
    }
}

private struct UserKey: EnvironmentKey {
    static let defaultValue: User = User(email: "", password: "", username: "", towers: [Tower]())
}

extension EnvironmentValues {
    var user: User {
        get { self[UserKey.self] }
        set { self[UserKey.self] = newValue }
    }
}

extension View {
    func embedUser(_ user: User) -> some View {
        environment(\.user, user)
    }
}

@main
struct TestApp: App {
        
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
            print("audio error")
        }
    }
    
    @StateObject var router = AppRouter()
        
    var body: some Scene {
        WindowGroup {
            Group {
                switch router.currentModule {
                case .login:
                    LoginOverview()
                case .main(let user, let apiService):
                    MainView()
                        .embedUser(user)
                        .embedApiSerivce(apiService)
                case .ringing(let viewModel):
                    RingingRoomView()
                        .environmentObject(viewModel)
                }
            }
            .tint(Color.main)
            .environmentObject(router)
        }
    }
}
