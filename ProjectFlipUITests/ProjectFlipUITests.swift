import XCTest

final class ProjectFlipUITests: XCTestCase {
    @MainActor
    func testEnglishShell() {
        verifyShell(language: "en", market: "Market", inventory: "Inventory")
    }

    @MainActor
    func testTurkishShell() {
        verifyShell(language: "tr", market: "Pazar", inventory: "Envanter")
    }

    @MainActor
    private func verifyShell(language: String, market: String, inventory: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "tr" ? "tr_TR" : "en_US"]
        app.launch()
        XCTAssertTrue(app.navigationBars[market].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Deniz" : "Alex"].waitForExistence(timeout: 5))
        app.buttons["listing.listing-42-0"].tap()
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
        app.buttons["openConversation"].tap()
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Deniz" : "Alex"].exists)
        app.tabBars.buttons[inventory].tap()
        XCTAssertTrue(app.navigationBars[inventory].exists)
    }
}
