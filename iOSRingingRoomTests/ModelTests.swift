import Foundation
import XCTest
@testable import Ringing_Room

@MainActor
final class ModelTests: XCTestCase {
    func testRegionsExposeStableServerAndDisplayNames() {
        XCTAssertEqual(Region.uk.server, "")
        XCTAssertEqual(Region.na.server, "na.")
        XCTAssertEqual(Region.sg.server, "sg.")
        XCTAssertEqual(Region.anzab.server, "anzab.")

        XCTAssertEqual(Region.uk.displayName, "UK")
        XCTAssertEqual(Region.na.displayName, "North America")
        XCTAssertEqual(Region.sg.displayName, "Singapore")
        XCTAssertEqual(Region.anzab.displayName, "ANZAB")

        for region in Region.allCases {
            XCTAssertEqual(Region(server: region.server), region)
        }
        XCTAssertNil(Region(server: "unknown."))
    }

    func testAppEnvironmentSelectsDeterministicUITestMode() {
        let production = AppEnvironment(arguments: ["Ringing Room"])
        let uiTesting = AppEnvironment(arguments: ["Ringing Room", "-UITesting"])

        XCTAssertFalse(production.isUITesting)
        XCTAssertTrue(uiTesting.isUITesting)
        XCTAssertFalse(uiTesting.isAuthenticatedUITesting)
        XCTAssertFalse(uiTesting.isTowerUITesting)
        XCTAssertFalse(uiTesting.isAutomaticLoginUITesting)
        XCTAssertFalse(uiTesting.isLoginErrorUITesting)

        let authenticated = AppEnvironment(arguments: ["Ringing Room", "-UITestingAuthenticated"])
        XCTAssertTrue(authenticated.isAuthenticatedUITesting)
        XCTAssertFalse(authenticated.isTowerUITesting)

        let tower = AppEnvironment(arguments: ["Ringing Room", "-UITestingTower"])
        XCTAssertTrue(tower.isTowerUITesting)

        let automaticLogin = AppEnvironment(arguments: ["Ringing Room", "-UITestingAutomaticLogin"])
        XCTAssertTrue(automaticLogin.isAutomaticLoginUITesting)

        let loginError = AppEnvironment(arguments: ["Ringing Room", "-UITestingLoginError"])
        XCTAssertTrue(loginError.isLoginErrorUITesting)
    }

    func testSessionCredentialsNormalizeEmailButPreservePassword() {
        let credentials = SessionCredentials(email: "  User@Example.COM ", password: "  secret  ")

        XCTAssertEqual(credentials.email, "user@example.com")
        XCTAssertEqual(credentials.password, "  secret  ")
    }

    func testTowerConversionMapsFlagsAndDates() throws {
        let model = APIModel.Tower(
            bookmark: 1,
            creator: 0,
            host: 1,
            recent: 0,
            tower_id: "42",
            tower_name: "Test Tower",
            visited: "Mon, 01 Jan 2024 12:00:00 GMT"
        )

        let tower = try Tower(towerModel: model)

        XCTAssertEqual(tower.id, 42)
        XCTAssertEqual(tower.towerName, "Test Tower")
        XCTAssertTrue(tower.bookmark)
        XCTAssertFalse(tower.creator)
        XCTAssertTrue(tower.host)
        XCTAssertFalse(tower.recent)
        XCTAssertEqual(tower.visited, ISO8601DateFormatter().date(from: "2024-01-01T12:00:00Z"))
    }

    func testTowerConversionRejectsInvalidIdentifierAndDate() {
        let invalidIdentifier = APIModel.Tower(
            bookmark: 0, creator: 0, host: 0, recent: 0,
            tower_id: "not-an-id", tower_name: "Tower", visited: "Mon, 01 Jan 2024 12:00:00 GMT"
        )
        XCTAssertThrowsError(try Tower(towerModel: invalidIdentifier)) { error in
            guard case Tower.ConversionError.invalidIdentifier("not-an-id") = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        let invalidDate = APIModel.Tower(
            bookmark: 0, creator: 0, host: 0, recent: 0,
            tower_id: "42", tower_name: "Tower", visited: "not-a-date"
        )
        XCTAssertThrowsError(try Tower(towerModel: invalidDate)) { error in
            guard case Tower.ConversionError.invalidVisitedDate("not-a-date") = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTowerInfoMapsSizesAndMufflingMatrix() {
        let cases: [(Bool, Bool, Bool, Muffled)] = [
            (false, false, false, .none),
            (false, true, false, .half),
            (false, false, true, .full),
            (false, true, true, .toll),
            (true, true, true, .toll)
        ]

        for (additionalSizes, halfMuffled, fullyMuffled, expectedMuffling) in cases {
            let details = APIModel.TowerDetails(
                tower_id: 1,
                tower_name: "Tower",
                server_address: "https://ringingroom.com",
                additional_sizes_enabled: additionalSizes,
                host_mode_permitted: true,
                half_muffled: halfMuffled,
                fully_muffled: fullyMuffled
            )
            let info = TowerInfo(towerDetails: details, isHost: true)

            XCTAssertEqual(info.towerSizes, additionalSizes ? [4, 5, 6, 8, 10, 12, 14, 16] : [4, 6, 8, 10, 12])
            XCTAssertEqual(info.towerID, 1)
            XCTAssertTrue(info.isHost)
            switch (info.muffled, expectedMuffling) {
            case (.none, .none), (.half, .half), (.full, .full), (.toll, .toll):
                break
            default:
                XCTFail("Unexpected muffling value")
            }
        }
    }

    func testRingerPayloadsAndArrayHelpers() throws {
        XCTAssertEqual(try Ringer(socketPayload: ["username": "Alice", "user_id": 7]), Ringer(name: "Alice", id: 7))
        XCTAssertEqual(try Ringer(socketPayload: ["user_id": -1]), .wheatley)
        XCTAssertEqual(try Ringer(socketPayload: ["user_id": 8]).name, "Username not found")
        XCTAssertThrowsError(try Ringer(socketPayload: ["user_id": Date()]))

        var optionalRingers: [Ringer?] = [Ringer(name: "Alice", id: 1), nil, Ringer(name: "Alice", id: 1)]
        XCTAssertEqual(optionalRingers.allIndicesOfRinger(Ringer(name: "Alice", id: 1)), [0, 2])
        XCTAssertEqual(optionalRingers.allIndicesOfRinger(Ringer(name: "Nobody", id: 2)), [])

        var ringers = [Ringer(name: "zoe", id: 1), Ringer(name: "Alice", id: 2), Ringer(name: "bob", id: 3)]
        ringers.sortAlphabetically()
        XCTAssertEqual(ringers.map(\.name), ["Alice", "bob", "zoe"])
        ringers.remove(Ringer(name: "bob", id: 3))
        XCTAssertEqual(ringers.map(\.name), ["Alice", "zoe"])
    }

    func testBellTypesAndStrokesCoverSupportedValues() {
        XCTAssertEqual(BellStroke(bool: true).boolValue, true)
        XCTAssertEqual(BellStroke(bool: false).boolValue, false)

        XCTAssertEqual(BellType.allCases, [.tower, .hand, .cowbell])
        XCTAssertEqual(BellType.tower.sounds[4], ["5", "6", "7", "8"])
        XCTAssertEqual(BellType.hand.sounds[14], ["3", "4", "5", "6f", "7", "8", "9", "0", "E", "T", "A", "B", "C", "D"])
        XCTAssertEqual(BellType.cowbell.sounds[16]?.count, 16)
    }

    func testExtensionsAndDeepLinks() {
        XCTAssertTrue("person@example.com".isValidEmail())
        XCTAssertFalse("not-an-email".isValidEmail())
        XCTAssertEqual(Double(12.349).truncate(places: 2), 12.34)
        XCTAssertEqual(CGFloat(180).radians(), .pi, accuracy: 0.0001)
        XCTAssertTrue(Bool(1))
        XCTAssertFalse(Bool(0))

        XCTAssertEqual(AppDeepLink(url: URL(string: "ringingroom://privacy")!), .privacy)
        XCTAssertEqual(AppDeepLink(url: URL(string: "ringingroom://123")!), .tower(towerID: 123))
        XCTAssertNil(AppDeepLink(url: URL(string: "ringingroom://0")!))
        XCTAssertNil(AppDeepLink(url: URL(string: "ringingroom://tower/123")!))
    }

    func testPendingDeepLinkRouterStoresAndConsumesTowerIDs() {
        let router = PendingDeepLinkRouter()
        XCTAssertNil(router.pendingTowerID)
        XCTAssertEqual(router.receive(URL(string: "ringingroom://123")!), .tower(towerID: 123))
        XCTAssertEqual(router.pendingTowerID, 123)
        XCTAssertEqual(router.consumeTowerID(), 123)
        XCTAssertNil(router.pendingTowerID)
        XCTAssertNil(router.receive(URL(string: "ringingroom://unsupported/path")!))
    }

    func testAPIModelDecodingHandlesOptionalFieldsAndDeletionTypes() throws {
        let details = try JSONDecoder().decode(
            APIModel.TowerDetails.self,
            from: Data("{\"tower_id\":1,\"tower_name\":\"Tower\",\"server_address\":\"https://ringingroom.com\"}".utf8)
        )
        XCTAssertFalse(details.additional_sizes_enabled)
        XCTAssertFalse(details.host_mode_permitted)
        XCTAssertFalse(details.half_muffled)
        XCTAssertFalse(details.fully_muffled)

        let stringDeletion = try JSONDecoder().decode(APIModel.DeletedUser.self, from: Data("{\"deleted_user\":\"alice\"}".utf8))
        let numericDeletion = try JSONDecoder().decode(APIModel.DeletedUser.self, from: Data("{\"deleted_user\":42}".utf8))
        XCTAssertEqual(stringDeletion.deleted_user, "alice")
        XCTAssertEqual(numericDeletion.deleted_user, "42")
    }

    func testWheatleyMethodConversionAndRowGenerationDecoding() throws {
        let method = BluelineMethod(
            title: "Plain Bob Doubles",
            stage: 5,
            notation: "x5x125",
            lengthOfLead: 4,
            calls: Calls(bob: Bob(notation: "14", from: 1, every: 2), single: nil),
            url: "plain-bob-doubles"
        )

        let rowGen = try method.makeRowGen()
        XCTAssertEqual(rowGen["type"] as? String, "method")
        XCTAssertEqual(rowGen["bob"] as? [String: String], ["1": "14", "3": "14"])
        XCTAssertEqual(rowGen["single"] as? [String: String], [:])

        let decoded = try RowGen(dictionary: [
            "type": "method",
            "title": "Plain Bob Doubles",
            "stage": 5,
            "notation": "x5x125",
            "url": "plain-bob-doubles",
            "bob": ["1": "14"],
            "single": [:]
        ])
        guard case .method(let decodedMethod) = decoded else {
            return XCTFail("Expected a method row generator")
        }
        XCTAssertEqual(decodedMethod.title, "Plain Bob Doubles")
        XCTAssertEqual(decodedMethod.bob, [1: "14"])

        let composition = try RowGen(dictionary: [
            "type": "composition",
            "title": "A composition",
            "url": "https://complib.org/composition/123"
        ])
        guard case .comp(let decodedComposition) = composition else {
            return XCTFail("Expected a composition row generator")
        }
        XCTAssertEqual(decodedComposition.title, "A composition")
        XCTAssertThrowsError(try RowGen(dictionary: ["type": "unknown"]))
    }

    func testBluelineCallValidationAndStedmanSingleOverride() throws {
        let invalid = BluelineMethod(
            title: "Method",
            stage: 5,
            notation: "x",
            lengthOfLead: 4,
            calls: Calls(bob: Bob(notation: "14", from: 1, every: 0), single: nil),
            url: "method"
        )
        XCTAssertThrowsError(try invalid.makeRowGen()) { error in
            guard case WheatleyError.invalidCallInterval = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        let stedman = BluelineMethod(
            title: "Stedman Doubles",
            stage: 5,
            notation: "x",
            lengthOfLead: 6,
            calls: nil,
            url: "stedman"
        )
        let rowGen = try stedman.makeRowGen()
        XCTAssertEqual(rowGen["single"] as? [String: String], ["0": "145", "6": "345"])
    }

    func testOptionalUserDefaultsValuesDistinguishAbsentValidAndWrongTypes() {
        let defaults = makeIsolatedDefaults()

        XCTAssertNil(defaults.optionalInt(forKey: "int"))
        XCTAssertNil(defaults.optionalBool(forKey: "bool"))
        XCTAssertNil(defaults.optionalDouble(forKey: "double"))

        defaults.set(7, forKey: "int")
        defaults.set(true, forKey: "bool")
        defaults.set(0.75, forKey: "double")
        XCTAssertEqual(defaults.optionalInt(forKey: "int"), 7)
        XCTAssertEqual(defaults.optionalBool(forKey: "bool"), true)
        XCTAssertEqual(defaults.optionalDouble(forKey: "double"), 0.75)

        defaults.set("7", forKey: "int")
        defaults.set("true", forKey: "bool")
        defaults.set("0.75", forKey: "double")
        XCTAssertNil(defaults.optionalInt(forKey: "int"))
        XCTAssertNil(defaults.optionalBool(forKey: "bool"))
        XCTAssertNil(defaults.optionalDouble(forKey: "double"))
    }

    func testEveryAPIErrorProvidesUsefulAlertData() throws {
        let decodingError: DecodingError
        do {
            _ = try JSONDecoder().decode(APIModel.User.self, from: Data("{}".utf8))
            return XCTFail("Expected a decoding error")
        } catch let error as DecodingError {
            decodingError = error
        }

        let errors: [APIError] = [
            .decode(error: decodingError),
            .url(error: URLError(.timedOut), retryAction: nil),
            .invalidURL(attemptedURL: "https://example.invalid"),
            .noResponse,
            .unauthorized,
            .sessionExpired,
            .encode,
            .http(code: 422, error: "Validation failed", message: "Name is required"),
            .credentialsNotSaved(user: APIModel.User(username: "Alice", email: "alice@example.com")),
            .unknown(message: "unexpected failure")
        ]

        for error in errors {
            let alert = error.alertData
            XCTAssertFalse(alert.title.isEmpty, "Missing title for \(error)")
            XCTAssertFalse(alert.message.isEmpty, "Missing message for \(error)")
            if case .retry = alert.dismiss {
                XCTFail("Only the retry-specific case should create a retry action")
            }
        }
    }

    func testAPIErrorRetryAlertInvokesTheProvidedAction() async throws {
        let retryInvoked = expectation(description: "Retry action invoked")
        let error = APIError.url(
            error: URLError(.notConnectedToInternet),
            retryAction: { retryInvoked.fulfill() }
        )

        switch error.alertData.dismiss {
        case .retry(let action):
            action()
        default:
            XCTFail("Expected a retry dismissal")
        }

        await fulfillment(of: [retryInvoked], timeout: 1)
    }

    func testAlertDataInitializersSetDismissalDefaultsAndPreserveExplicitActions() {
        let defaultAlert = AlertData(title: "Title", message: "Message")
        guard case .cancel(let title, let action) = defaultAlert.dismiss else {
            return XCTFail("Expected the default cancel dismissal")
        }
        XCTAssertEqual(title, "Ok")
        XCTAssertNil(action)

        var actionInvoked = false
        let explicitAlert = AlertData(
            title: "Title",
            message: "Message",
            dissmiss: .cancel(title: "Later", action: { actionInvoked = true })
        )
        guard case .cancel(let explicitTitle, let explicitAction) = explicitAlert.dismiss else {
            return XCTFail("Expected the explicit cancel dismissal")
        }
        XCTAssertEqual(explicitTitle, "Later")
        explicitAction?()
        XCTAssertTrue(actionInvoked)
    }

    func testErrorUtilUsesInjectedPresenterForSuccessAndBothErrorPaths() async {
        let presenter = AlertPresenterSpy()
        var successRan = false

        await ErrorUtil.do(alertPresenter: presenter) {
            await Task.yield()
            successRan = true
        }
        XCTAssertTrue(successRan)
        XCTAssertTrue(presenter.presentedAlerts.isEmpty)
        XCTAssertTrue(presenter.handledErrors.isEmpty)

        await ErrorUtil.do(alertPresenter: presenter) {
            await Task.yield()
            throw APIError.unauthorized
        }
        XCTAssertEqual(presenter.handledErrors.count, 1)
        XCTAssertTrue(presenter.presentedAlerts.isEmpty)

        await ErrorUtil.do(alertPresenter: presenter) {
            await Task.yield()
            throw TestError.forcedFailure
        }
        XCTAssertEqual(presenter.presentedAlerts.count, 1)
        XCTAssertEqual(presenter.presentedAlerts[0].title, "Error")

        ErrorUtil.do(alertPresenter: presenter) {
            throw APIError.sessionExpired
        }
        XCTAssertEqual(presenter.handledErrors.count, 2)

        ErrorUtil.do(alertPresenter: presenter) {
            throw TestError.forcedFailure
        }
        XCTAssertEqual(presenter.presentedAlerts.count, 2)
    }

    func testThreadUtilRunsImmediateAndInjectedDelayedWorkDeterministically() async {
        var immediateRan = false
        ThreadUtil.runInMain {
            immediateRan = true
        }
        XCTAssertTrue(immediateRan)

        let scheduler = ImmediateTaskSchedulerSpy()
        var delayedRan = false
        ThreadUtil.runInMain(after: 2, scheduler: scheduler) {
            delayedRan = true
        }

        XCTAssertFalse(delayedRan)
        XCTAssertEqual(scheduler.requestedNanoseconds, 2_000_000_000)
        await scheduler.runScheduledOperation()
        XCTAssertTrue(delayedRan)
    }
}

@MainActor
private final class ImmediateTaskSchedulerSpy: TaskScheduling {
    var requestedNanoseconds: UInt64?
    private var operation: (@MainActor @Sendable () async -> Void)?

    func schedule(
        after nanoseconds: UInt64,
        operation: @escaping @MainActor @Sendable () async -> Void
    ) -> Task<Void, Never> {
        requestedNanoseconds = nanoseconds
        self.operation = operation
        return Task {}
    }

    func runScheduledOperation() async {
        await operation?()
    }
}
