import XCTest

@MainActor final class SalesUITests: XCTestCase {
    func testSalesTabAndSettingsHasNoDeveloperUI() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--uitest-save", UUID().uuidString, "--uitest-competition-fixture", "--uitest-reduce-motion"]
        app.launch()
        XCTAssertTrue(app.buttons["gameTab.3"].waitForExistence(timeout: 10))
        app.buttons["gameTab.3"].tap()
        XCTAssertEqual(app.buttons["gameTab.3"].label, "Satışlar")
        XCTAssertTrue(app.buttons["salesHistory"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["openShop"].exists)
        app.buttons["salesHistory"].tap()
        app.buttons["gameTab.3"].tap() // Reselect returns directly to the sales root.
        XCTAssertTrue(app.buttons["salesHistory"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Sales Turkish"; shot.lifetime = .keepAlways; add(shot)
        app.terminate(); app.launch()
        app.buttons["gameTab.3"].tap()
        XCTAssertTrue(app.buttons["salesHistory"].waitForExistence(timeout: 5))
        app.buttons["gameTab.4"].tap()
        XCTAssertFalse(app.buttons["openCollections"].exists)
        XCTAssertFalse(app.buttons["openTradeHistory"].exists)
        XCTAssertFalse(app.buttons["openRecovery"].exists)
        reveal(app.buttons["openSettings"], app: app)
        app.buttons["openSettings"].tap()
        XCTAssertTrue(app.switches["soundSetting"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["developerTools"].exists)
        app.buttons["gameTab.0"].tap()
        XCTAssertTrue(app.navigationBars["Pazar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["soundSetting"].exists, "Inactive tabs must not leak into accessibility")
        app.buttons["gameTab.4"].tap()
        XCTAssertTrue(app.switches["soundSetting"].waitForExistence(timeout: 5), "Switching tabs preserves the settings destination")
        app.buttons["gameTab.4"].tap() // Reselect the active tab: pop Settings to Profile.
        XCTAssertTrue(app.buttons["editProfile"].waitForExistence(timeout: 5))
        app.buttons["editProfile"].tap()
        let field = app.textFields["playerName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        if let value = field.value as? String, value != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        field.typeText("Deniz")
        app.buttons["playerAvatar.2"].tap()
        app.buttons["saveProfile"].tap()
        XCTAssertTrue(app.staticTexts["Deniz"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        app.buttons["gameTab.4"].tap()
        XCTAssertTrue(app.staticTexts["Deniz"].waitForExistence(timeout: 5))
        let settings = XCTAttachment(screenshot: app.screenshot()); settings.name = "Player settings Turkish"; settings.lifetime = .keepAlways; add(settings)
    }
    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<10 { if element.exists && element.isHittable { return }; app.swipeUp() }
        XCTAssertTrue(element.exists)
    }
}
