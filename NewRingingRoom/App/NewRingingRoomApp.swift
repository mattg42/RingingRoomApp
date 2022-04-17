//
//  NewRingingRoomApp.swift
//  NewRingingRoom
//
//  Created by Matthew on 02/08/2021.
//

import SwiftUI
import Combine

class ModuleNavigator: ObservableObject {
    @Published var currentModule: AppModule = .login
    
    static var shared = ModuleNavigator()
    
    static func moveTo(_ newModule: AppModule) {
        DispatchQueue.main.async {
            shared.currentModule = newModule
        }
    }
    
    private init() {}
}

enum AppModule {
    case login
    case main
    case ringing
}

@main
struct NewRingingRoomApp: App {
        
    @ObservedObject var navigator = ModuleNavigator.shared
    @ObservedObject var user = User.shared
    
    let apiService = APIService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch navigator.currentModule {
                case .login:
                    LoginOverview(apiService: apiService)
                case .main:
                    MainOverview()
                case .ringing:
                    RingingView()
                }
            }
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
