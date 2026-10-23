import XCTest

@MainActor final class LanguageUITests: XCTestCase {
    func testGermanAndFrenchRootNavigationAndSettings() {
        continueAfterFailure = false
        for (code, language, profileTitle, settingsTitle) in [("de", "de_DE", "Profil", "Einstellungen"), ("fr", "fr_FR", "Profil", "Réglages")] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", language, "--uitest-save", UUID().uuidString, "--uitest-reduce-motion"]
            app.launch()
            XCTAssertTrue(app.buttons["gameTab.4"].waitForExistence(timeout: 10))
            app.buttons["gameTab.4"].tap()
            XCTAssertTrue(app.navigationBars[profileTitle].waitForExistence(timeout: 5))
            let settings = app.buttons["openSettings"]
            for _ in 0..<8 { if settings.exists && settings.isHittable { break }; app.swipeUp() }
            settings.tap()
            XCTAssertTrue(app.navigationBars[settingsTitle].waitForExistence(timeout: 5))
            XCTAssertTrue(app.switches["soundSetting"].exists)
            let image = XCTAttachment(screenshot: app.screenshot()); image.name = "Settings \(code)"; image.lifetime = .keepAlways; add(image)
            app.terminate()
        }
    }
}
