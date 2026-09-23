import Foundation

protocol SocketTransport: AnyObject {
    var delegate: (any SocketIODelegate)? { get set }

    func connect(completion: @escaping () -> ())
    func reset()
    func disconnect()
    func send(event: String, with data: [String: Any])
}

extension SocketIOService: SocketTransport {}

@MainActor
protocol AudioEngine: AnyObject {
    func load(resource: String, type: String, for identifier: SoundIdentifier, in bundle: Bundle?)
    func prepareToStart() async
    func changeVolume(to volume: Float)
    func play(_ sound: SoundIdentifier, allowOverlap: Bool) async
}

extension Starling: AudioEngine {}

@MainActor
protocol AudioPlaying: AnyObject {
    func prepareToStart() async
    func changeVolume(to volume: Float)
    func play(_ file: String)
    func cancelPendingPlayback()
}

extension AudioPlaying {
    func cancelPendingPlayback() {}
}

extension AudioService: AudioPlaying {}

@MainActor
protocol AlertPresenting: AnyObject {
    func presentAlert(title: String, message: String?, dismiss: DismissType)
    func handle(error: any Alertable)
}

@MainActor
final class SystemAlertPresenter: AlertPresenting {
    func presentAlert(title: String, message: String?, dismiss: DismissType) {
        AlertHandler.presentAlert(title: title, message: message, dismiss: dismiss)
    }

    func handle(error: any Alertable) {
        AlertHandler.handle(error: error)
    }
}

@MainActor
protocol PreferencesStoring: AnyObject {
    func optionalBool(forKey key: String) -> Bool?
    func set(_ value: Any?, forKey key: String)
}

@MainActor
final class UserDefaultsPreferences: PreferencesStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func optionalBool(forKey key: String) -> Bool? {
        defaults.optionalBool(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

@MainActor
protocol AccountAPIClient: AnyObject {
    func reauthenticate(with password: String) async throws
    func updateUser(username: String?, email: String?, password: String?) async throws -> APIModel.User
    func deleteUser() async throws -> APIModel.DeletedUser
    func clearSession() -> SessionCredentialStore.CleanupResult
}

extension APIService: AccountAPIClient {}

@MainActor
protocol RingingRoomAPIClient: AnyObject {
    var token: String { get }
    var region: Region { get }
    func updateToken() async throws
}

extension APIService: RingingRoomAPIClient {}

@MainActor
protocol TaskScheduling: AnyObject {
    func schedule(
        after nanoseconds: UInt64,
        operation: @escaping @MainActor @Sendable () async -> Void
    ) -> Task<Void, Never>
}

@MainActor
final class LiveTaskScheduler: TaskScheduling {
    func schedule(
        after nanoseconds: UInt64,
        operation: @escaping @MainActor @Sendable () async -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
                await operation()
            } catch {
                // Cancellation is the normal path when a connection succeeds
                // or the user leaves the tower before the timeout.
            }
        }
    }
}

@MainActor
struct AppEnvironment {
    let isUITesting: Bool
    let isAuthenticatedUITesting: Bool
    let isTowerUITesting: Bool
    let isAutomaticLoginUITesting: Bool
    let isLoginErrorUITesting: Bool
    let preferences: any PreferencesStoring
    let credentialStore: any SessionCredentialStoring
    let alertPresenter: any AlertPresenting
    let scheduler: any TaskScheduling
    let makeSocketTransport: @MainActor (URL) -> any SocketTransport
    let makeAudioPlayer: @MainActor () -> any AudioPlaying

    init(
        arguments: [String] = CommandLine.arguments,
        preferences: any PreferencesStoring = UserDefaultsPreferences(),
        credentialStore: any SessionCredentialStoring = SessionCredentialStore.standard,
        alertPresenter: any AlertPresenting = SystemAlertPresenter(),
        scheduler: any TaskScheduling = LiveTaskScheduler(),
        makeSocketTransport: @escaping @MainActor (URL) -> any SocketTransport = { SocketIOService(url: $0) },
        makeAudioPlayer: @escaping @MainActor () -> any AudioPlaying = { AudioService() }
    ) {
        self.isUITesting = arguments.contains("-UITesting")
        self.isAuthenticatedUITesting = arguments.contains("-UITestingAuthenticated")
        self.isTowerUITesting = arguments.contains("-UITestingTower")
        self.isAutomaticLoginUITesting = arguments.contains("-UITestingAutomaticLogin")
        self.isLoginErrorUITesting = arguments.contains("-UITestingLoginError")
        self.preferences = preferences
        self.credentialStore = credentialStore
        self.alertPresenter = alertPresenter
        self.scheduler = scheduler
        if isAuthenticatedUITesting || isTowerUITesting {
            self.makeSocketTransport = { _ in UITestSocketTransport() }
            self.makeAudioPlayer = { UITestAudioPlayer() }
        } else {
            self.makeSocketTransport = makeSocketTransport
            self.makeAudioPlayer = makeAudioPlayer
        }
    }
}
