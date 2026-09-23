import Foundation
import XCTest
@testable import Ringing_Room

final class URLProtocolStub: URLProtocol {
    typealias RequestHandler = (URLRequest) throws -> (URLResponse, Data)

    private static let handlerHeader = "X-iOSRingingRoom-Test-Handler"
    private static let lock = NSLock()
    private nonisolated(unsafe) static var handlers = [String: RequestHandler]()
    private nonisolated(unsafe) static var sessionIDs = [ObjectIdentifier: String]()

    static func setHandler(_ handler: @escaping RequestHandler, for session: URLSession) {
        lock.lock()
        defer { lock.unlock() }
        guard let sessionID = sessionIDs[ObjectIdentifier(session)] else { return }
        handlers[sessionID] = handler
    }

    static func unregister(_ session: URLSession) {
        lock.lock()
        defer { lock.unlock() }
        guard let sessionID = sessionIDs.removeValue(forKey: ObjectIdentifier(session)) else { return }
        handlers.removeValue(forKey: sessionID)
    }

    fileprivate static func register(_ session: URLSession, sessionID: String) {
        lock.lock()
        sessionIDs[ObjectIdentifier(session)] = sessionID
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let requestHandler: RequestHandler? = {
            Self.lock.lock()
            defer { Self.lock.unlock() }
            guard let sessionID = request.value(forHTTPHeaderField: Self.handlerHeader) else { return nil }
            return Self.handlers[sessionID]
        }()

        guard let requestHandler else {
            client?.urlProtocol(self, didFailWithError: TestError.missingURLProtocolHandler)
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

enum TestError: Error {
    case forcedFailure
    case missingURLProtocolHandler
}

func makeTestURLSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let sessionID = UUID().uuidString
    configuration.httpAdditionalHeaders = [URLProtocolStubHeader.key: sessionID]
    let session = URLSession(configuration: configuration)
    URLProtocolStub.register(session, sessionID: sessionID)
    return session
}

private enum URLProtocolStubHeader {
    static let key = "X-iOSRingingRoom-Test-Handler"
}

func makeHTTPResponse(for request: URLRequest, statusCode: Int = 200, headers: [String: String] = [:]) -> HTTPURLResponse {
    HTTPURLResponse(
        url: request.url!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: headers
    )!
}

func makeJSONData(_ object: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: object)
}

func requestBodyData(_ request: URLRequest) -> Data? {
    if let httpBody = request.httpBody {
        return httpBody
    }

    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }

    var body = Data()
    var buffer = [UInt8](repeating: 0, count: 1_024)
    while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        guard count > 0 else { break }
        body.append(buffer, count: count)
    }
    return body
}

@MainActor
final class InMemoryPasswordStore: PasswordStoring {
    var values = [String: String]()
    var operations = [String]()
    var failDeletes = false
    var failStores = false
    var getError: Error?
    var deleteFailures = [String: Error]()

    func storePasswordFor(account: String, password: String, server: String) throws {
        if failStores { throw TestError.forcedFailure }
        operations.append("store:\(account):\(server)")
        values[key(account, server)] = password
    }

    func getPasswordFor(account: String, server: String) throws -> String {
        operations.append("get:\(account):\(server)")
        if let getError { throw getError }
        guard let value = values[key(account, server)] else {
            throw KeychainError.itemNotFound
        }
        return value
    }

    func updatePasswordFor(account: String, password: String, server: String) throws {
        operations.append("update:\(account):\(server)")
        values[key(account, server)] = password
    }

    func deletePasswordFor(account: String, server: String) throws {
        operations.append("delete:\(account):\(server)")
        if failDeletes { throw TestError.forcedFailure }
        if let error = deleteFailures[key(account, server)] { throw error }
        values.removeValue(forKey: key(account, server))
    }

    func key(_ account: String, _ server: String) -> String {
        "\(account)|\(server)"
    }
}

@MainActor
final class AudioEngineSpy: AudioEngine {
    var loadedResources = [(resource: String, type: String, identifier: SoundIdentifier)]()
    var playedSounds = [SoundIdentifier]()
    var prepareCount = 0
    var volume: Float?
    var onPlay: (() -> Void)?

    func load(resource: String, type: String, for identifier: SoundIdentifier, in bundle: Bundle?) {
        loadedResources.append((resource, type, identifier))
    }

    func prepareToStart() async {
        prepareCount += 1
    }

    func changeVolume(to volume: Float) {
        self.volume = volume
    }

    func play(_ sound: SoundIdentifier, allowOverlap: Bool) async {
        playedSounds.append(sound)
        onPlay?()
    }
}

@MainActor
final class DelayedActivationAudioEngineSpy: AudioEngine {
    private var activationWaiters = [CheckedContinuation<Void, Never>]()
    private var hasActivated = false

    private(set) var playedSounds = [SoundIdentifier]()
    var onActivationWaiterCountChanged: ((Int) -> Void)?
    var onPlaybackReturned: (() -> Void)?

    func load(resource: String, type: String, for identifier: SoundIdentifier, in bundle: Bundle?) {}

    func prepareToStart() async {
        guard !hasActivated else { return }

        await withCheckedContinuation { continuation in
            activationWaiters.append(continuation)
            onActivationWaiterCountChanged?(activationWaiters.count)
        }
    }

    func changeVolume(to volume: Float) {}

    func play(_ sound: SoundIdentifier, allowOverlap: Bool) async {
        await prepareToStart()
        if !Task.isCancelled {
            playedSounds.append(sound)
        }
        onPlaybackReturned?()
    }

    func finishActivation() {
        hasActivated = true
        let waiters = activationWaiters
        activationWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }
}

@MainActor
final class PreferencesSpy: PreferencesStoring {
    var values = [String: Any]()

    func optionalBool(forKey key: String) -> Bool? {
        values[key] as? Bool
    }

    func set(_ value: Any?, forKey key: String) {
        values[key] = value
    }
}

@MainActor
final class AlertPresenterSpy: AlertPresenting {
    var presentedAlerts = [(title: String, message: String?, dismiss: DismissType)]()
    var handledErrors = [any Alertable]()
    var onPresent: (() -> Void)?
    var onHandle: (() -> Void)?

    func presentAlert(title: String, message: String?, dismiss: DismissType) {
        presentedAlerts.append((title, message, dismiss))
        onPresent?()
    }

    func handle(error: any Alertable) {
        handledErrors.append(error)
        onHandle?()
    }
}

@MainActor
final class ScheduledTaskRecord {
    let nanoseconds: UInt64
    let operation: @MainActor @Sendable () async -> Void
    var executed = false
    private(set) var cancelled = false
    private var cancellationContinuation: CheckedContinuation<Void, Never>?

    init(nanoseconds: UInt64, operation: @escaping @MainActor @Sendable () async -> Void) {
        self.nanoseconds = nanoseconds
        self.operation = operation
    }

    func markCancelled() {
        cancelled = true
        cancellationContinuation?.resume()
        cancellationContinuation = nil
    }

    func waitUntilCancelled() async {
        if cancelled { return }
        await withCheckedContinuation { continuation in
            cancellationContinuation = continuation
        }
    }
}

@MainActor
final class TaskSchedulerSpy: TaskScheduling {
    var scheduled = [ScheduledTaskRecord]()

    func schedule(
        after nanoseconds: UInt64,
        operation: @escaping @MainActor @Sendable () async -> Void
    ) -> Task<Void, Never> {
        let record = ScheduledTaskRecord(nanoseconds: nanoseconds, operation: operation)
        scheduled.append(record)
        return Task { @MainActor [record] in
            do {
                try await Task.sleep(nanoseconds: UInt64.max)
            } catch {
                record.markCancelled()
            }
        }
    }

    func runNext() async {
        guard let record = scheduled.first(where: { !$0.executed }) else { return }
        record.executed = true
        await record.operation()
    }
}

@MainActor
final class AccountAPIClientSpy: AccountAPIClient {
    var reauthenticatedPasswords = [String]()
    var updateRequests = [(username: String?, email: String?, password: String?)]()
    var deleteCallCount = 0
    var clearSessionCallCount = 0

    var reauthenticateError: Error?
    var updateError: Error?
    var deleteError: Error?
    var updatedUser = APIModel.User(username: "updated", email: "updated@example.com")
    var cleanupResult = SessionCredentialStore.CleanupResult(failures: [])

    func reauthenticate(with password: String) async throws {
        reauthenticatedPasswords.append(password)
        if let reauthenticateError { throw reauthenticateError }
    }

    func updateUser(username: String?, email: String?, password: String?) async throws -> APIModel.User {
        updateRequests.append((username, email, password))
        if let updateError { throw updateError }
        return updatedUser
    }

    func deleteUser() async throws -> APIModel.DeletedUser {
        deleteCallCount += 1
        if let deleteError { throw deleteError }
        return try! JSONDecoder().decode(APIModel.DeletedUser.self, from: Data(#"{"deleted_user":"account"}"#.utf8))
    }

    func clearSession() -> SessionCredentialStore.CleanupResult {
        clearSessionCallCount += 1
        return cleanupResult
    }
}

@MainActor
final class RingingRoomAPIClientSpy: RingingRoomAPIClient {
    var token: String
    let region: Region = .uk
    var refreshedToken = "refreshed-token"
    var updateTokenError: Error?
    private(set) var updateTokenCallCount = 0

    private var updateStarted = false
    private var updateFinished = false
    private var updateStartedContinuation: CheckedContinuation<Void, Never>?
    private var updateFinishedContinuation: CheckedContinuation<Void, Never>?
    private var releaseUpdateContinuation: CheckedContinuation<Void, Never>?
    private var releaseUpdate = false

    init(token: String = "token") {
        self.token = token
    }

    func updateToken() async throws {
        updateTokenCallCount += 1
        updateStarted = true
        updateStartedContinuation?.resume()
        updateStartedContinuation = nil

        if !releaseUpdate {
            await withCheckedContinuation { continuation in
                releaseUpdateContinuation = continuation
            }
        }

        defer {
            updateFinished = true
            updateFinishedContinuation?.resume()
            updateFinishedContinuation = nil
        }

        if let updateTokenError {
            throw updateTokenError
        }
        token = refreshedToken
    }

    func waitUntilUpdateStarts() async {
        if updateStarted { return }
        await withCheckedContinuation { continuation in
            updateStartedContinuation = continuation
        }
    }

    func waitUntilUpdateFinishes() async {
        if updateFinished { return }
        await withCheckedContinuation { continuation in
            updateFinishedContinuation = continuation
        }
    }

    func release() {
        releaseUpdate = true
        releaseUpdateContinuation?.resume()
        releaseUpdateContinuation = nil
    }
}

@MainActor
func makeIsolatedDefaults() -> UserDefaults {
    let suiteName = "iOSRingingRoomTests.\(UUID().uuidString)"
    return UserDefaults(suiteName: suiteName)!
}
