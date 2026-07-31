import Foundation
@preconcurrency import XCTest
@testable import Ringing_Room

@MainActor
final class CredentialStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var passwordStore: InMemoryPasswordStore!
    private var sut: SessionCredentialStore!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "iOSRingingRoomTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        passwordStore = InMemoryPasswordStore()
        sut = SessionCredentialStore(userDefaults: defaults, passwordStore: passwordStore)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        passwordStore = nil
        sut = nil
        try await super.tearDown()
    }

    func testPersistThenLoadUsesNormalizedEmailAndInjectedStore() throws {
        let credentials = SessionCredentials(email: " Alice@Example.com ", password: "secret")

        try sut.persistLogin(credentials: credentials, keepMeLoggedIn: true, server: "ringingroom.com")

        XCTAssertTrue(sut.keepMeLoggedIn)
        XCTAssertEqual(defaults.string(forKey: UserDefaults.Keys.userEmail), "alice@example.com")
        XCTAssertEqual(passwordStore.values[passwordStore.key("alice@example.com", "ringingroom.com")], "secret")

        let stored = try XCTUnwrap(sut.load(for: "ringingroom.com"))
        XCTAssertEqual(stored.credentials.email, "alice@example.com")
        XCTAssertEqual(stored.credentials.password, "secret")
        XCTAssertEqual(stored.keychainAccount, "alice@example.com")
    }

    func testLoadReturnsNilWhenNoEmailIsStored() throws {
        XCTAssertNil(try sut.load(for: "ringingroom.com"))
        XCTAssertTrue(passwordStore.operations.isEmpty)
    }

    func testLoadPropagatesItemNotFoundAfterAllAliasesAreMissing() {
        defaults.set("person@example.com", forKey: UserDefaults.Keys.userEmail)
        defaults.set(["person@example.com", " PERSON@example.com "], forKey: UserDefaults.Keys.userEmailAliases)

        XCTAssertThrowsError(try sut.load(for: "ringingroom.com")) { error in
            guard case KeychainError.itemNotFound = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertFalse(passwordStore.operations.isEmpty)
    }

    func testLoadPropagatesNonItemNotFoundPasswordStoreErrors() {
        defaults.set("person@example.com", forKey: UserDefaults.Keys.userEmail)
        passwordStore.getError = TestError.forcedFailure

        XCTAssertThrowsError(try sut.load(for: "ringingroom.com")) { error in
            guard case TestError.forcedFailure = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testLoadFallsBackThroughLegacyAliases() throws {
        defaults.set("new@example.com", forKey: UserDefaults.Keys.userEmail)
        defaults.set([" old@example.com ", "old@example.com"], forKey: UserDefaults.Keys.userEmailAliases)
        passwordStore.values[passwordStore.key("old@example.com", "na.ringingroom.com")] = "legacy-password"

        let stored = try XCTUnwrap(sut.load(for: "na.ringingroom.com"))

        XCTAssertEqual(stored.credentials.email, "new@example.com")
        XCTAssertEqual(stored.credentials.password, "legacy-password")
        XCTAssertEqual(stored.keychainAccount, "old@example.com")
    }

    func testUpdatingEmailStoresReplacementBeforeDeletingOldAliases() throws {
        let oldCredentials = SessionCredentials(email: "old@example.com", password: "old")
        let newCredentials = SessionCredentials(email: "new@example.com", password: "new")
        try sut.persistLogin(credentials: oldCredentials, keepMeLoggedIn: true, server: "ringingroom.com")
        passwordStore.operations.removeAll()

        try sut.updateCredentials(from: oldCredentials, to: newCredentials, server: "ringingroom.com")

        let storeIndex = try XCTUnwrap(passwordStore.operations.firstIndex(of: "store:new@example.com:ringingroom.com"))
        let deleteIndex = try XCTUnwrap(passwordStore.operations.firstIndex(of: "delete:old@example.com:ringingroom.com"))
        XCTAssertLessThan(storeIndex, deleteIndex)
        XCTAssertEqual(defaults.string(forKey: UserDefaults.Keys.userEmail), "new@example.com")
    }

    func testUpdateCredentialsDoesNothingWhenAutomaticLoginIsDisabled() throws {
        let oldCredentials = SessionCredentials(email: "old@example.com", password: "old")
        let newCredentials = SessionCredentials(email: "new@example.com", password: "new")

        try sut.updateCredentials(from: oldCredentials, to: newCredentials, server: "ringingroom.com")

        XCTAssertTrue(passwordStore.operations.isEmpty)
        XCTAssertFalse(sut.keepMeLoggedIn)
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmail))
    }

    func testDisableAutomaticLoginClearsEmailButRetainsAliasesForLaterCleanup() throws {
        try sut.persistLogin(
            credentials: SessionCredentials(email: "person@example.com", password: "secret"),
            keepMeLoggedIn: true,
            server: "ringingroom.com"
        )

        sut.disableAutomaticLogin()

        XCTAssertFalse(sut.keepMeLoggedIn)
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmail))
        XCTAssertEqual(defaults.array(forKey: UserDefaults.Keys.userEmailAliases) as? [String], ["person@example.com"])
    }

    func testLoadUsesUniqueTrimmedAndCaseInsensitiveAliases() throws {
        defaults.set(" Person@Example.com ", forKey: UserDefaults.Keys.userEmail)
        defaults.set(
            ["person@example.com", " Person@Example.com ", "PERSON@EXAMPLE.COM", ""],
            forKey: UserDefaults.Keys.userEmailAliases
        )
        passwordStore.values[passwordStore.key("person@example.com", "ringingroom.com")] = "secret"

        let stored = try XCTUnwrap(sut.load(for: "ringingroom.com"))

        XCTAssertEqual(stored.credentials.email, "person@example.com")
        XCTAssertEqual(stored.keychainAccount, "person@example.com")
        XCTAssertEqual(passwordStore.operations.filter { $0.hasPrefix("get:") }.count, 3)
        XCTAssertEqual(Set(passwordStore.operations), Set([
            "get: Person@Example.com :ringingroom.com",
            "get:Person@Example.com:ringingroom.com",
            "get:person@example.com:ringingroom.com"
        ]))
    }

    func testOptingOutRemovesStoredStateAndCredentials() throws {
        try sut.persistLogin(credentials: SessionCredentials(email: "person@example.com", password: "secret"), keepMeLoggedIn: true, server: "ringingroom.com")

        try sut.persistLogin(credentials: SessionCredentials(email: "person@example.com", password: "secret"), keepMeLoggedIn: false, server: "ringingroom.com")

        XCTAssertFalse(sut.keepMeLoggedIn)
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmail))
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmailAliases))
        XCTAssertTrue(passwordStore.values.isEmpty)
    }

    func testCleanupReportsFailuresButAlwaysClearsLocalDefaults() throws {
        try sut.persistLogin(credentials: SessionCredentials(email: "person@example.com", password: "secret"), keepMeLoggedIn: true, server: "ringingroom.com")
        passwordStore.failDeletes = true

        let result = sut.clear(currentEmail: "person@example.com")

        XCTAssertFalse(result.succeeded)
        XCTAssertFalse(sut.keepMeLoggedIn)
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmail))
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmailAliases))
    }

    func testCleanupAttemptsEveryRegionAndReportsPartialFailures() throws {
        let credentials = SessionCredentials(email: "person@example.com", password: "secret")
        try sut.persistLogin(credentials: credentials, keepMeLoggedIn: true, server: "ringingroom.com")
        passwordStore.values[passwordStore.key("person@example.com", "na.ringingroom.com")] = "other-region-secret"
        passwordStore.deleteFailures[passwordStore.key("person@example.com", "na.ringingroom.com")] = TestError.forcedFailure

        let result = sut.clear(currentEmail: credentials.email)

        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(
            Set(passwordStore.operations.filter { $0.hasPrefix("delete:") }.compactMap { $0.split(separator: ":").last.map(String.init) }),
            Set(["ringingroom.com", "na.ringingroom.com", "sg.ringingroom.com", "anzab.ringingroom.com"])
        )
        XCTAssertTrue(passwordStore.values.keys.contains(passwordStore.key("person@example.com", "na.ringingroom.com")))
        XCTAssertNil(defaults.object(forKey: UserDefaults.Keys.userEmail))
        XCTAssertFalse(sut.keepMeLoggedIn)
    }
}
