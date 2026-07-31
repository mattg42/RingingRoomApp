import Foundation
import XCTest
@testable import Ringing_Room

@MainActor
final class NetworkingTests: XCTestCase {
    private var testSession: URLSession!

    override func setUp() {
        super.setUp()
        testSession = makeTestURLSession()
    }

    override func tearDown() {
        URLProtocolStub.unregister(testSession)
        testSession.invalidateAndCancel()
        testSession = nil
        super.tearDown()
    }

    private func setHandler(_ handler: @escaping URLProtocolStub.RequestHandler) {
        URLProtocolStub.setHandler(handler, for: testSession)
    }

    func testAuthenticationBuildsBasicAuthorizationRequest() async throws {
        let session = try XCTUnwrap(testSession)
        let expectedAuthorization = "Basic \(Data("user@example.com:secret".utf8).base64EncodedString())"
        var capturedRequest: URLRequest?

        setHandler { request in
            capturedRequest = request
            XCTAssertEqual(request.url?.absoluteString, "https://na.ringingroom.com/api/tokens")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), expectedAuthorization)
            return (
                makeHTTPResponse(for: request, headers: ["Content-Type": "application/json"]),
                try makeJSONData(["token": "token-1"])
            )
        }

        let service = AuthenticationService(region: .na, urlSession: session)
        let token = try await service.getToken(email: "User@Example.com", password: "secret")

        XCTAssertEqual(token, "token-1")
        XCTAssertEqual(capturedRequest?.url?.path, "/api/tokens")
    }

    func testRegistrationAndPasswordResetSendExpectedJSONBodies() async throws {
        var capturedBodies = [[String: String]]()
        setHandler { request in
            let body = try XCTUnwrap(requestBodyData(request))
            capturedBodies.append(try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String]))

            switch request.url?.path {
            case "/api/user":
                return (
                    makeHTTPResponse(for: request),
                    try makeJSONData(["username": "Alice", "email": "alice@example.com"])
                )
            case "/api/user/reset_password":
                return (makeHTTPResponse(for: request), try makeJSONData(["status": "sent"]))
            default:
                XCTFail("Unexpected URL: \(request.url?.absoluteString ?? "nil")")
                return (makeHTTPResponse(for: request, statusCode: 500), Data())
            }
        }

        let service = AuthenticationService(region: .uk, urlSession: testSession)
        let user = try await service.registerUser(username: "Alice", email: "Alice@example.com", password: "secret")
        _ = try await service.resetPassword(email: "Alice@example.com")

        XCTAssertEqual(user.username, "Alice")
        XCTAssertEqual(capturedBodies, [
            ["username": "Alice", "email": "Alice@example.com", "password": "secret"],
            ["email": "Alice@example.com"]
        ])
    }

    func testAuthenticationLoginFetchesTokenTowersAndUserAndPersistsRegion() async throws {
        let oldServer = UserDefaults.standard.string(forKey: UserDefaults.Keys.Server)
        defer {
            if let oldServer {
                UserDefaults.standard.set(oldServer, forKey: UserDefaults.Keys.Server)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.Server)
            }
        }

        var paths = [String]()
        setHandler { request in
            paths.append(request.url?.path ?? "")
            switch request.url?.path {
            case "/api/tokens":
                return (makeHTTPResponse(for: request), try makeJSONData(["token": "login-token"]))
            case "/api/my_towers":
                return (
                    makeHTTPResponse(for: request),
                    try makeJSONData([
                        "tower": [
                            "bookmark": 0, "creator": 0, "host": 1, "recent": 1,
                            "tower_id": "42", "tower_name": "Test Tower",
                            "visited": "Tue, 02 Jan 2024 12:00:00 GMT"
                        ]
                    ])
                )
            case "/api/user":
                return (
                    makeHTTPResponse(for: request),
                    try makeJSONData(["username": "Alice", "email": "alice@example.com"])
                )
            default:
                XCTFail("Unexpected URL: \(request.url?.absoluteString ?? "nil")")
                return (makeHTTPResponse(for: request, statusCode: 500), Data())
            }
        }

        var service = AuthenticationService(region: .uk, urlSession: testSession)
        service.region = .na
        let (user, apiService) = try await service.login(email: "Alice@example.com", password: "secret")

        XCTAssertEqual(UserDefaults.standard.string(forKey: UserDefaults.Keys.Server), "na.")
        XCTAssertEqual(paths, ["/api/tokens", "/api/my_towers", "/api/user"])
        XCTAssertEqual(user.username, "Alice")
        XCTAssertEqual(user.towers.map(\.towerID), [42])
        XCTAssertEqual(apiService.token, "login-token")
        XCTAssertEqual(apiService.region, .na)
    }

    func testAPIServiceDecodesAndSortsTowersWhileIgnoringMalformedRows() async throws {
        setHandler { request in
            XCTAssertEqual(request.url?.path, "/api/my_towers")
            let payload: [String: [String: Any]] = [
                "new": [
                    "bookmark": 1, "creator": 0, "host": 1, "recent": 1,
                    "tower_id": "2", "tower_name": "New", "visited": "Tue, 02 Jan 2024 12:00:00 GMT"
                ],
                "old": [
                    "bookmark": 0, "creator": 1, "host": 0, "recent": 0,
                    "tower_id": "1", "tower_name": "Old", "visited": "Mon, 01 Jan 2024 12:00:00 GMT"
                ],
                "malformed": [
                    "bookmark": 0, "creator": 0, "host": 0, "recent": 0,
                    "tower_id": "not-an-id", "tower_name": "Ignored", "visited": "not-a-date"
                ]
            ]
            return (makeHTTPResponse(for: request), try makeJSONData(payload))
        }

        let service = APIService(token: "token", region: .uk, urlSession: testSession)
        let towers = try await service.getTowers()

        XCTAssertEqual(towers.map(\.towerID), [2, 1])
        XCTAssertEqual(towers.map(\.towerName), ["New", "Old"])
    }

    func testAPIServiceSendsJSONBodyAndHeaders() async throws {
        setHandler { request in
            XCTAssertEqual(request.url?.path, "/api/tower")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")

            let body = try XCTUnwrap(requestBodyData(request))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
            XCTAssertEqual(json, ["tower_name": "A new tower"])

            return (
                makeHTTPResponse(for: request),
                try makeJSONData(["tower_id": 99, "server_address": "https://ringingroom.com"])
            )
        }

        let service = APIService(token: "token", region: .uk, urlSession: testSession)
        let details = try await service.createTower(called: "A new tower")

        XCTAssertEqual(details.tower_id, 99)
        XCTAssertEqual(details.server_address, "https://ringingroom.com")
    }

    func testAPIServiceTowerDetailsDeletionReauthenticationAndSessionPersistence() async throws {
        var tokenRequests = 0
        setHandler { request in
            switch (request.url?.path, request.httpMethod) {
            case ("/api/tower/42", "GET"):
                return (
                    makeHTTPResponse(for: request),
                    try makeJSONData([
                        "tower_id": 42, "tower_name": "Tower", "server_address": "https://ringingroom.com",
                        "additional_sizes_enabled": true, "host_mode_permitted": true,
                        "half_muffled": true, "fully_muffled": false
                    ])
                )
            case ("/api/user", "DELETE"):
                return (makeHTTPResponse(for: request), try makeJSONData(["deleted_user": 42]))
            case ("/api/tokens", "POST"):
                tokenRequests += 1
                return (makeHTTPResponse(for: request), try makeJSONData(["token": "reauthenticated-token"]))
            default:
                XCTFail("Unexpected request: \(request.httpMethod ?? "nil") \(request.url?.path ?? "nil")")
                return (makeHTTPResponse(for: request, statusCode: 500), Data())
            }
        }

        let defaults = makeIsolatedDefaults()
        let passwordStore = InMemoryPasswordStore()
        let credentials = SessionCredentials(email: "person@example.com", password: "old-password")
        let credentialStore = SessionCredentialStore(userDefaults: defaults, passwordStore: passwordStore)
        let service = APIService(
            token: "token",
            region: .uk,
            credentials: credentials,
            urlSession: testSession,
            credentialStore: credentialStore
        )

        let details = try await service.getTowerDetails(towerID: 42)
        let deleted = try await service.deleteUser()
        try service.persistLogin(keepMeLoggedIn: true)
        try await service.reauthenticate(with: "new-password")
        let cleanup = service.clearSession()

        XCTAssertEqual(details.tower_id, 42)
        XCTAssertTrue(details.half_muffled)
        XCTAssertEqual(deleted.deleted_user, "42")
        XCTAssertEqual(tokenRequests, 1)
        XCTAssertEqual(service.token, "")
        XCTAssertNil(service.sessionCredentials)
        XCTAssertTrue(cleanup.succeeded)
        XCTAssertFalse(credentialStore.keepMeLoggedIn)
        XCTAssertTrue(passwordStore.values.isEmpty)
    }

    func testReauthenticateWithoutCredentialsEndsWithSessionExpired() async {
        let service = APIService(
            token: "token",
            region: .uk,
            urlSession: testSession
        )

        do {
            try await service.reauthenticate(with: "secret")
            XCTFail("Expected reauthentication without credentials to fail")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateUserSendsEachOptionalFieldCombination() async throws {
        var capturedBodies = [[String: String]]()
        setHandler { request in
            let body = try XCTUnwrap(requestBodyData(request))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
            capturedBodies.append(json)
            return (
                makeHTTPResponse(for: request),
                try makeJSONData(["username": json["new_username"] ?? "Alice", "email": json["new_email"] ?? "alice@example.com"])
            )
        }

        let usernameService = APIService(token: "token", region: .uk, urlSession: testSession)
        _ = try await usernameService.updateUser(username: "New Alice")
        let emailService = APIService(token: "token", region: .uk, urlSession: testSession)
        _ = try await emailService.updateUser(email: "new@example.com")
        let passwordService = APIService(token: "token", region: .uk, urlSession: testSession)
        _ = try await passwordService.updateUser(password: "new-password")

        XCTAssertEqual(capturedBodies, [
            ["new_username": "New Alice"],
            ["new_email": "new@example.com"],
            ["new_password": "new-password"]
        ])
    }

    func testUpdateUserMigratesCredentialsAndPreservesPasswordWhenEmailChanges() async throws {
        setHandler { request in
            (
                makeHTTPResponse(for: request),
                try makeJSONData(["username": "Alice", "email": "new@example.com"])
            )
        }

        let defaults = makeIsolatedDefaults()
        let passwordStore = InMemoryPasswordStore()
        let credentialStore = SessionCredentialStore(userDefaults: defaults, passwordStore: passwordStore)
        let oldCredentials = SessionCredentials(email: "old@example.com", password: "old-password")
        let service = APIService(
            token: "token",
            region: .uk,
            credentials: oldCredentials,
            urlSession: testSession,
            credentialStore: credentialStore
        )
        try service.persistLogin(keepMeLoggedIn: true)
        passwordStore.operations.removeAll()

        let user = try await service.updateUser(email: "new@example.com")

        XCTAssertEqual(user.email, "new@example.com")
        XCTAssertEqual(service.sessionCredentials?.email, "new@example.com")
        XCTAssertEqual(service.sessionCredentials?.password, "old-password")
        XCTAssertEqual(passwordStore.values[passwordStore.key("new@example.com", "ringingroom.com")], "old-password")
        XCTAssertLessThan(
            passwordStore.operations.firstIndex(of: "store:new@example.com:ringingroom.com")!,
            passwordStore.operations.firstIndex(of: "delete:old@example.com:ringingroom.com")!
        )
    }

    func testUpdateUserWithoutCredentialsDoesNotAttemptCredentialPersistence() async throws {
        setHandler { request in
            (makeHTTPResponse(for: request), try makeJSONData(["username": "Alice", "email": "alice@example.com"]))
        }

        let passwordStore = InMemoryPasswordStore()
        let service = APIService(
            token: "token",
            region: .uk,
            urlSession: testSession,
            credentialStore: SessionCredentialStore(userDefaults: makeIsolatedDefaults(), passwordStore: passwordStore)
        )

        _ = try await service.updateUser(username: "Alice")

        XCTAssertTrue(passwordStore.operations.isEmpty)
        XCTAssertNil(service.sessionCredentials)
    }

    func testUpdateUserPersistenceFailureReturnsTypedErrorAndDisablesAutomaticLogin() async throws {
        setHandler { request in
            (makeHTTPResponse(for: request), try makeJSONData(["username": "Alice", "email": "new@example.com"]))
        }

        let defaults = makeIsolatedDefaults()
        let passwordStore = InMemoryPasswordStore()
        let oldCredentials = SessionCredentials(email: "old@example.com", password: "old-password")
        let credentialStore = SessionCredentialStore(userDefaults: defaults, passwordStore: passwordStore)
        let service = APIService(
            token: "token",
            region: .uk,
            credentials: oldCredentials,
            urlSession: testSession,
            credentialStore: credentialStore
        )
        try service.persistLogin(keepMeLoggedIn: true)
        passwordStore.failStores = true

        do {
            _ = try await service.updateUser(email: "new@example.com")
            XCTFail("Expected credential persistence failure")
        } catch let error as APIError {
            guard case .credentialsNotSaved(let user) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(user.email, "new@example.com")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(service.sessionCredentials?.email, "new@example.com")
        XCTAssertFalse(credentialStore.keepMeLoggedIn)
    }

    func testHTTPStatusAndDecodeFailuresBecomeTypedAPIErrors() async {
        setHandler { request in
            (
                makeHTTPResponse(for: request, statusCode: 422),
                try makeJSONData(["error": "Validation failed", "message": "Name is required"])
            )
        }
        let service = AuthenticationService(region: .uk, urlSession: testSession)

        do {
            _ = try await service.resetPassword(email: "person@example.com")
            XCTFail("Expected an HTTP error")
        } catch let error as APIError {
            guard case .http(let code, let errorText, let message) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(code, 422)
            XCTAssertEqual(errorText, "Validation failed")
            XCTAssertEqual(message, "Name is required")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        setHandler { request in
            (makeHTTPResponse(for: request), Data("not-json".utf8))
        }
        do {
            _ = try await service.getToken(email: "person@example.com", password: "secret")
            XCTFail("Expected a decoding error")
        } catch let error as APIError {
            guard case .decode = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testURLFailuresRetainRetryAction() async {
        setHandler { _ in
            throw URLError(.notConnectedToInternet)
        }
        var service = AuthenticationService(region: .uk, urlSession: testSession)
        service.retryAction = { }

        do {
            _ = try await service.getToken(email: "person@example.com", password: "secret")
            XCTFail("Expected a URL error")
        } catch let error as APIError {
            guard case .url(let urlError, let retryAction) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
            XCTAssertNotNil(retryAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNonHTTPResponseBecomesNoResponseAndProtocolErrorsBecomeUnknown() async {
        setHandler { request in
            (
                URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil),
                Data()
            )
        }
        let service = AuthenticationService(region: .uk, urlSession: testSession)

        do {
            _ = try await service.getToken(email: "person@example.com", password: "secret")
            XCTFail("Expected no-response error")
        } catch let error as APIError {
            guard case .noResponse = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        setHandler { _ in throw TestError.forcedFailure }
        do {
            _ = try await service.getToken(email: "person@example.com", password: "secret")
            XCTFail("Expected unknown error")
        } catch let error as APIError {
            guard case .unknown(let message) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnauthorizedRequestRefreshesTokenAndRetries() async throws {
        var userRequestCount = 0
        var tokenRequestCount = 0
        setHandler { request in
            switch request.url?.path {
            case "/api/user":
                userRequestCount += 1
                if userRequestCount == 1 {
                    return (makeHTTPResponse(for: request, statusCode: 401), Data())
                }
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
                return (makeHTTPResponse(for: request), try makeJSONData(["username": "Alice", "email": "alice@example.com"]))
            case "/api/tokens":
                tokenRequestCount += 1
                return (makeHTTPResponse(for: request), try makeJSONData(["token": "refreshed-token"]))
            default:
                XCTFail("Unexpected URL: \(request.url?.absoluteString ?? "nil")")
                return (makeHTTPResponse(for: request, statusCode: 500), Data())
            }
        }

        let credentials = SessionCredentials(email: "alice@example.com", password: "secret")
        let store = SessionCredentialStore(userDefaults: makeIsolatedDefaults(), passwordStore: InMemoryPasswordStore())
        let service = APIService(
            token: "expired-token",
            region: .uk,
            credentials: credentials,
            urlSession: testSession,
            credentialStore: store
        )

        let user = try await service.getUserDetails()

        XCTAssertEqual(user.username, "Alice")
        XCTAssertEqual(service.token, "refreshed-token")
        XCTAssertEqual(userRequestCount, 2)
        XCTAssertEqual(tokenRequestCount, 1)
    }

    func testUnauthorizedRefreshHTTPFailurePropagatesAndKeepsSession() async {
        var tokenRequestCount = 0
        setHandler { request in
            if request.url?.path == "/api/user" {
                return (makeHTTPResponse(for: request, statusCode: 401), Data())
            }
            tokenRequestCount += 1
            return (
                makeHTTPResponse(for: request, statusCode: 500),
                try makeJSONData(["error": "server", "message": "refresh failed"])
            )
        }

        let credentials = SessionCredentials(email: "alice@example.com", password: "secret")
        let service = APIService(token: "expired-token", region: .uk, credentials: credentials, urlSession: testSession)

        do {
            _ = try await service.getUserDetails()
            XCTFail("Expected refresh failure")
        } catch let error as APIError {
            guard case .http(let code, _, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(tokenRequestCount, 1)
        XCTAssertEqual(service.sessionCredentials?.email, "alice@example.com")
        XCTAssertEqual(service.token, "expired-token")
    }

    func testUnauthorizedRefreshSecond401ExpiresSessionAndRunsCleanup() async {
        var sessionExpired = false
        setHandler { request in
            if request.url?.path == "/api/user" {
                return (makeHTTPResponse(for: request, statusCode: 401), Data())
            }
            return (makeHTTPResponse(for: request, statusCode: 401), Data())
        }

        let defaults = makeIsolatedDefaults()
        let passwordStore = InMemoryPasswordStore()
        let credentials = SessionCredentials(email: "alice@example.com", password: "secret")
        let store = SessionCredentialStore(userDefaults: defaults, passwordStore: passwordStore)
        let service = APIService(
            token: "expired-token",
            region: .uk,
            credentials: credentials,
            urlSession: testSession,
            credentialStore: store
        )
        try? store.persistLogin(credentials: credentials, keepMeLoggedIn: true, server: "ringingroom.com")
        service.sessionExpiredAction = { sessionExpired = true }

        do {
            _ = try await service.getUserDetails()
            XCTFail("Expected session expiration")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(sessionExpired)
        XCTAssertNil(service.sessionCredentials)
        XCTAssertEqual(service.token, "")
        XCTAssertFalse(store.keepMeLoggedIn)
        XCTAssertTrue(passwordStore.values.isEmpty)
    }

    func testConcurrentAuthenticatedRequestsShareOneTokenRefresh() async throws {
        let lock = NSLock()
        var userRequestCount = 0
        var tokenRequestCount = 0
        setHandler { request in
            lock.lock()
            defer { lock.unlock() }

            switch request.url?.path {
            case "/api/user":
                userRequestCount += 1
                if userRequestCount <= 2 {
                    return (makeHTTPResponse(for: request, statusCode: 401), Data())
                }
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer shared-token")
                return (makeHTTPResponse(for: request), try makeJSONData(["username": "Alice", "email": "alice@example.com"]))
            case "/api/tokens":
                tokenRequestCount += 1
                return (makeHTTPResponse(for: request), try makeJSONData(["token": "shared-token"]))
            default:
                XCTFail("Unexpected URL: \(request.url?.absoluteString ?? "nil")")
                return (makeHTTPResponse(for: request, statusCode: 500), Data())
            }
        }

        let credentials = SessionCredentials(email: "alice@example.com", password: "secret")
        let service = APIService(token: "expired-token", region: .uk, credentials: credentials, urlSession: testSession)
        async let first = service.getUserDetails()
        async let second = service.getUserDetails()
        let users = try await [first, second]

        XCTAssertEqual(users.map(\.username), ["Alice", "Alice"])
        XCTAssertEqual(userRequestCount, 4)
        XCTAssertEqual(tokenRequestCount, 1)
        XCTAssertEqual(service.token, "shared-token")
    }

    func testTokenRefreshCoordinatorResetsAfterSuccessAndFailure() async throws {
        var tokenRequestCount = 0
        setHandler { request in
            tokenRequestCount += 1
            switch tokenRequestCount {
            case 1:
                return (makeHTTPResponse(for: request), try makeJSONData(["token": "first-token"]))
            case 2:
                return (
                    makeHTTPResponse(for: request, statusCode: 500),
                    try makeJSONData(["error": "server", "message": "refresh failed"])
                )
            default:
                return (makeHTTPResponse(for: request), try makeJSONData(["token": "third-token"]))
            }
        }

        let service = APIService(
            token: "expired-token",
            region: .uk,
            credentials: SessionCredentials(email: "alice@example.com", password: "secret"),
            urlSession: testSession
        )

        try await service.updateToken()
        XCTAssertEqual(service.token, "first-token")

        do {
            try await service.updateToken()
            XCTFail("Expected the second refresh to fail")
        } catch let error as APIError {
            guard case .http(let code, _, _) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(code, 500)
        }

        try await service.updateToken()
        XCTAssertEqual(service.token, "third-token")
        XCTAssertEqual(tokenRequestCount, 3)
    }

    func testUnauthorizedRequestWithoutCredentialsEndsSession() async {
        setHandler { request in
            (makeHTTPResponse(for: request, statusCode: 401), Data())
        }

        let defaults = makeIsolatedDefaults()
        let store = SessionCredentialStore(
            userDefaults: defaults,
            passwordStore: InMemoryPasswordStore()
        )
        let service = APIService(
            token: "expired-token",
            region: .uk,
            urlSession: testSession,
            credentialStore: store
        )
        var sessionExpired = false
        service.sessionExpiredAction = { sessionExpired = true }

        do {
            _ = try await service.getUserDetails()
            XCTFail("Expected the missing-credentials path to expire the session")
        } catch let error as APIError {
            guard case .sessionExpired = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(sessionExpired)
        XCTAssertNil(service.sessionCredentials)
        XCTAssertEqual(service.token, "")
    }

    func testTokenRefreshCoordinatorCoalescesConcurrentRefreshes() async throws {
        let coordinator = TokenRefreshCoordinator()
        let counter = RefreshCounter()
        let gate = RefreshGate()

        let first = Task {
            try await coordinator.refresh {
                await counter.increment()
                await gate.waitUntilReleased()
                return "shared-token"
            }
        }
        await counter.waitUntilStarted()
        let second = Task {
            try await coordinator.refresh {
                await counter.increment()
                return "unexpected-token"
            }
        }
        await gate.release()

        let firstValue = try await first.value
        let secondValue = try await second.value
        let refreshCount = await counter.value
        XCTAssertEqual(firstValue, "shared-token")
        XCTAssertEqual(secondValue, "shared-token")
        XCTAssertEqual(refreshCount, 1)
    }
}

actor RefreshCounter {
    private(set) var value = 0
    private var started = CheckedContinuation<Void, Never>?.none

    func increment() {
        value += 1
        started?.resume()
        started = nil
    }

    func waitUntilStarted() async {
        if value > 0 { return }
        await withCheckedContinuation { continuation in
            started = continuation
        }
    }
}

actor RefreshGate {
    private var released = false
    private var waiter = CheckedContinuation<Void, Never>?.none

    func waitUntilReleased() async {
        if released { return }
        await withCheckedContinuation { continuation in
            waiter = continuation
        }
    }

    func release() {
        released = true
        waiter?.resume()
        waiter = nil
    }
}
