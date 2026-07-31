import XCTest

@MainActor
final class WelcomeLoginUITests: XCTestCase {
    func testWelcomeLoginPresentsStableControls() {
        let app = launchApp()

        XCTAssertTrue(app.textFields["login.email"].exists)
        XCTAssertTrue(app.secureTextFields["login.password"].exists)
        XCTAssertTrue(app.buttons["login.submit"].exists)
    }

    func testInvalidLoginKeepsSubmitDisabledUntilBothFieldsAreValid() {
        let app = launchApp()
        let email = app.textFields["login.email"]
        let password = app.secureTextFields["login.password"]
        let submit = app.buttons["login.submit"]

        XCTAssertFalse(submit.isEnabled)
        email.tap()
        email.typeText("not-an-email")
        password.tap()
        password.typeText("secret")
        XCTAssertFalse(submit.isEnabled)

        app.terminate()
        let validApp = launchApp()
        validApp.textFields["login.email"].tap()
        validApp.textFields["login.email"].typeText("person@example.com")
        validApp.secureTextFields["login.password"].tap()
        validApp.secureTextFields["login.password"].typeText("secret")
        XCTAssertTrue(validApp.buttons["login.submit"].isEnabled)
    }

    func testAccountCreationSheetAndPrivacyPolicyArePresentable() {
        let app = launchApp()
        app.buttons["login.createAccount"].tap()

        XCTAssertTrue(app.navigationBars["Create Account"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["account.username"].exists)
        XCTAssertTrue(app.textFields["account.email"].exists)
        XCTAssertTrue(app.secureTextFields["account.password"].exists)
        XCTAssertTrue(app.secureTextFields["account.password.repeat"].exists)
        XCTAssertFalse(app.buttons["account.submit"].isEnabled)

        app.buttons["account.privacy"].tap()
        XCTAssertTrue(app.navigationBars["Our Privacy Policy"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["privacy.agree"].exists)
        app.buttons["privacy.agree"].tap()
        XCTAssertTrue(app.navigationBars["Create Account"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["account.submit"].exists)
    }

    func testPasswordResetSheetIsPresentable() {
        let app = launchApp()
        app.buttons["login.forgotPassword"].tap()

        XCTAssertTrue(app.navigationBars["Reset Password"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["reset.email"].exists)
        XCTAssertTrue(app.buttons["reset.submit"].exists)
        XCTAssertTrue(app.buttons["reset.back"].exists)
    }

    func testAuthenticatedLaunchShowsFakeHomeWithoutNetworkDependencies() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestingAuthenticated"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Towers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tower.42"].waitForExistence(timeout: 2))
    }

    func testAuthenticatedTowerLaunchUsesFakeSocketTransport() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestingTower"]
        app.launch()

        XCTAssertTrue(app.staticTexts["UI Test Tower"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Set at hand"].waitForExistence(timeout: 2))
    }

    func testAutomaticLoginLaunchIsDeterministic() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestingAutomaticLogin"]
        app.launch()

        XCTAssertTrue(app.staticTexts["login.automatic"].waitForExistence(timeout: 5))
    }

    func testLoginErrorLaunchShowsDeterministicErrorState() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestingLoginError"]
        app.launch()

        XCTAssertTrue(app.staticTexts["login.error.screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts["Unable to login"].waitForExistence(timeout: 2))
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["welcome.login.title"].waitForExistence(timeout: 5))
        return app
    }
}
