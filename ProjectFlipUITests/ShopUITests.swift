import XCTest

@MainActor final class ShopUITests: XCTestCase {
    func testShopOpeningPersistsAndSettingsHasNoDeveloperUI() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--uitest-save", UUID().uuidString, "--uitest-competition-fixture", "--uitest-reduce-motion"]
        app.launch()
        XCTAssertTrue(app.buttons["gameTab.3"].waitForExistence(timeout: 10))
        app.buttons["gameTab.3"].tap()
        reveal(app.textFields["shopName"], app: app)
        app.textFields["shopName"].tap()
        app.textFields["shopName"].typeText("Kose Dukkani\n")
        reveal(app.buttons["openShop"], app: app)
        app.buttons["openShop"].tap()
        reveal(app.buttons["expandShop"], app: app)
        XCTAssertFalse(app.buttons["expandShop"].isEnabled)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Shop growth Turkish"; shot.lifetime = .keepAlways; add(shot)
        app.terminate(); app.launch()
        app.buttons["gameTab.3"].tap()
        XCTAssertTrue(app.staticTexts["Kose Dukkani"].waitForExistence(timeout: 5))
        app.buttons["gameTab.4"].tap()
        reveal(app.buttons["openSettings"], app: app)
        app.buttons["openSettings"].tap()
        XCTAssertTrue(app.switches["soundSetting"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["developerTools"].exists)
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
