import XCTest

@MainActor final class ReleaseReadinessUITests: XCTestCase {
    func testDamagedSaveCanBeRestoredWithConfirmation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--uitest-save", UUID().uuidString, "--uitest-corrupt-save", "--uitest-reduce-motion"]
        app.launch()
        XCTAssertTrue(app.buttons["restoreBackup"].waitForExistence(timeout: 10))
        app.buttons["restoreBackup"].tap()
        XCTAssertTrue(app.buttons["confirmRestoreBackup"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["confirmRestoreBackup"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["marketCash"].waitForExistence(timeout: 10))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["marketCash"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["restoreBackup"].exists)
    }

    func testPrivacyAndSupportAreAvailableOffline() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString, "--uitest-reduce-motion"]
        app.launch()
        XCTAssertTrue(app.buttons["gameTab.4"].waitForExistence(timeout: 10)); app.buttons["gameTab.4"].tap()
        reveal(app.buttons["openSettings"], app: app); app.buttons["openSettings"].tap()
        reveal(app.buttons["openPrivacy"], app: app); app.buttons["openPrivacy"].tap()
        XCTAssertTrue(app.navigationBars["Privacy"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Privacy English"; shot.lifetime = .keepAlways; add(shot)
        app.navigationBars.buttons.firstMatch.tap()
        reveal(app.buttons["openSupport"], app: app); app.buttons["openSupport"].tap()
        XCTAssertTrue(app.navigationBars["Help & support"].waitForExistence(timeout: 5))
        let contact = app.descendants(matching: .any).matching(identifier: "supportContact").firstMatch
        reveal(contact, app: app)
        XCTAssertTrue(contact.isHittable, "The packaged support email must produce a reachable contact link.")
        XCTAssertGreaterThanOrEqual(contact.frame.height, 44)
    }

    func testOfferFieldIsReachableAboveTheDockAndAcceptsFocus() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString, "--uitest-instant", "--uitest-reduce-motion"]
        app.launch()
        XCTAssertTrue(app.buttons["listing.listing-42-0"].waitForExistence(timeout: 10)); app.buttons["listing.listing-42-0"].tap()
        reveal(app.buttons["openConversation"], app: app); app.buttons["openConversation"].tap()
        let field = app.textFields["offerAmount"]
        reveal(field, app: app)
        let dock = app.buttons["gameTab.3"]
        print("OFFER INPUT BEFORE TAP: field=\(field.frame), dock=\(dock.frame)")
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Offer focus regression"; shot.lifetime = .keepAlways; add(shot)
        XCTAssertLessThanOrEqual(field.frame.maxY, dock.frame.minY)
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        field.typeText("0")
    }

    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<10 { if element.exists && element.isHittable { return }; app.swipeUp() }
        XCTAssertTrue(element.exists)
    }
}
