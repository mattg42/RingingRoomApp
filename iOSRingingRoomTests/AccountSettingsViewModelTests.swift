import XCTest
@testable import Ringing_Room

@MainActor
final class AccountSettingsViewModelTests: XCTestCase {
    func testUpdateRequiresCurrentPassword() async {
        let api = AccountAPIClientSpy()
        let alerts = AlertPresenterSpy()
        let sut = AccountSettingsViewModel(apiService: api, alertPresenter: alerts)

        let result = await sut.updateUser(username: "new-name", currentPassword: "")

        XCTAssertNil(result)
        XCTAssertTrue(api.reauthenticatedPasswords.isEmpty)
        XCTAssertEqual(alerts.presentedAlerts.first?.title, "Current password required")
        XCTAssertFalse(sut.isRunning)
    }

    func testUpdateReauthenticatesAndReturnsUpdatedUser() async {
        let api = AccountAPIClientSpy()
        api.updatedUser = APIModel.User(username: "new-name", email: "new@example.com")
        let alerts = AlertPresenterSpy()
        let sut = AccountSettingsViewModel(apiService: api, alertPresenter: alerts)

        let result = await sut.updateUser(
            username: "new-name",
            email: "new@example.com",
            password: "new-password",
            currentPassword: "current-password"
        )

        XCTAssertEqual(result?.user.username, "new-name")
        XCTAssertFalse(result?.automaticLoginDisabled ?? true)
        XCTAssertEqual(api.reauthenticatedPasswords, ["current-password"])
        XCTAssertEqual(api.updateRequests.count, 1)
        XCTAssertEqual(api.updateRequests[0].username, "new-name")
        XCTAssertEqual(api.updateRequests[0].email, "new@example.com")
        XCTAssertEqual(api.updateRequests[0].password, "new-password")
        XCTAssertTrue(alerts.presentedAlerts.isEmpty)
        XCTAssertFalse(sut.isRunning)
    }

    func testCredentialPersistenceFailureStillReportsSuccessfulServerUpdate() async {
        let api = AccountAPIClientSpy()
        let updatedUser = APIModel.User(username: "new-name", email: "new@example.com")
        api.updatedUser = updatedUser
        api.updateError = APIError.credentialsNotSaved(user: updatedUser)
        let alerts = AlertPresenterSpy()
        let sut = AccountSettingsViewModel(apiService: api, alertPresenter: alerts)

        let result = await sut.updateUser(currentPassword: "current-password")

        XCTAssertEqual(result?.user.email, "new@example.com")
        XCTAssertTrue(result?.automaticLoginDisabled ?? false)
        XCTAssertTrue(alerts.handledErrors.isEmpty)
        XCTAssertTrue(alerts.presentedAlerts.isEmpty)
    }

    func testDeleteRequiresReauthenticationAndReportsCleanupResult() async {
        let api = AccountAPIClientSpy()
        api.cleanupResult = SessionCredentialStore.CleanupResult(failures: [TestError.forcedFailure])
        let alerts = AlertPresenterSpy()
        let sut = AccountSettingsViewModel(apiService: api, alertPresenter: alerts)

        let result = await sut.deleteAccount(currentPassword: "current-password")

        XCTAssertEqual(result?.credentialsRemoved, false)
        XCTAssertEqual(api.reauthenticatedPasswords, ["current-password"])
        XCTAssertEqual(api.deleteCallCount, 1)
        XCTAssertEqual(api.clearSessionCallCount, 1)
        XCTAssertTrue(alerts.presentedAlerts.isEmpty)
        XCTAssertFalse(sut.isRunning)
    }

    func testDeleteFailureIsReportedAndDoesNotClearSession() async {
        let api = AccountAPIClientSpy()
        api.deleteError = APIError.http(code: 500, error: "server", message: "failed")
        let alerts = AlertPresenterSpy()
        let sut = AccountSettingsViewModel(apiService: api, alertPresenter: alerts)

        let result = await sut.deleteAccount(currentPassword: "current-password")

        XCTAssertNil(result)
        XCTAssertEqual(api.deleteCallCount, 1)
        XCTAssertEqual(api.clearSessionCallCount, 0)
        XCTAssertEqual(alerts.handledErrors.count, 1)
        XCTAssertFalse(sut.isRunning)
    }
}
