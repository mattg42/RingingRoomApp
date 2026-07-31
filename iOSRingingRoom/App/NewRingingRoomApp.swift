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
        let pathComponents = Array(url.pathComponents.dropFirst().filter { $0 != "/" })
        let firstPath: String
        if pathComponents.count == 1, let pathComponent = pathComponents.first {
            guard url.host == nil || url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https" else {
                return nil
            }
            firstPath = pathComponent
        } else if pathComponents.isEmpty, let host = url.host, !host.isEmpty {
            // Custom-scheme links such as ringingroom://123 put the route in
            // URL.host, while universal links put it in URL.path.
            firstPath = host
        } else {
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
    private let appEnvironment: AppEnvironment
        
    init() {
        let environment = AppEnvironment(arguments: CommandLine.arguments)
        appEnvironment = environment

        let freshInstall = !UserDefaults.standard.bool(forKey: "alreadyInstalled")
        if freshInstall {
            UserDefaults.standard.set(true, forKey: "alreadyInstalled")
        }

        let fakeTower = Tower(
            bookmark: false,
            creator: false,
            host: true,
            recent: true,
            towerID: 42,
            towerName: "UI Test Tower",
            visited: Date(timeIntervalSince1970: 0)
        )
        let fakeUser = User(email: "ui-test@example.com", username: "UI Test User", towers: [fakeTower])
        let fakeAPIService = APIService(
            token: "ui-test-token",
            region: .uk,
            urlSession: URLSession(configuration: .ephemeral)
        )
        let fakeTowerDetails = APIModel.TowerDetails(
            tower_id: fakeTower.towerID,
            tower_name: fakeTower.towerName,
            server_address: "https://ringingroom.com",
            additional_sizes_enabled: false,
            host_mode_permitted: true,
            half_muffled: false,
            fully_muffled: false
        )
        let initialRoute: AppRoute = if environment.isAuthenticatedUITesting || environment.isTowerUITesting {
            .main(
                user: fakeUser,
                apiService: fakeAPIService,
                route: environment.isTowerUITesting
                    ? .joinTower(towerID: fakeTower.towerID, towerDetails: fakeTowerDetails)
                    : .home
            )
        } else {
            .login
        }

        _router = StateObject(wrappedValue: Router<AppRoute>(defaultRoute: initialRoute))
    }
    
    @StateObject var router: Router<AppRoute>
    @StateObject private var pendingDeepLinkRouter = PendingDeepLinkRouter()
    @State private var showingPrivacyPolicy = false
    @ObservedObject var monitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            Group {
                switch router.currentRoute {
                case .login:
                    if appEnvironment.isLoginErrorUITesting {
                        UITestLoginErrorView()
                    } else {
                        LoginOverview(
                            appEnvironment.isAutomaticLoginUITesting
                                ? .auto
                                : (appEnvironment.isUITesting ? .welcome : nil),
                            isUITestingAutomaticLogin: appEnvironment.isAutomaticLoginUITesting
                        )
                    }
                case .main(let user, let apiService, let route):
                    MainView(
                        user: user,
                        apiService: apiService,
                        route: route,
                        makeSocketTransport: appEnvironment.makeSocketTransport,
                        makeAudioPlayer: appEnvironment.makeAudioPlayer,
                        preferences: appEnvironment.preferences,
                        alertPresenter: appEnvironment.alertPresenter,
                        scheduler: appEnvironment.scheduler
                    )
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

final class UITestSocketTransport: SocketTransport {
    weak var delegate: (any SocketIODelegate)?

    func connect(completion: @escaping () -> ()) {
        // Required UI journeys must never open a real socket. The view model
        // remains in its deterministic connecting state for inspection.
    }

    func reset() {}
    func disconnect() {}
    func send(event: String, with data: [String: Any]) {}
}

@MainActor
final class UITestAudioPlayer: AudioPlaying {
    func prepareToStart() async {}
    func changeVolume(to volume: Float) {}
    func play(_ file: String) {}
}

struct UITestLoginErrorView: View {
    @State private var showingError = false

    var body: some View {
        Text("Login error")
            .accessibilityIdentifier("login.error.screen")
            .task {
                showingError = true
            }
            .alert("Unable to login", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your email or password is incorrect.")
            }
    }
}
