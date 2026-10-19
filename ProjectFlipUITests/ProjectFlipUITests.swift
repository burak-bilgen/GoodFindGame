import XCTest

final class ProjectFlipUITests: XCTestCase {
    @MainActor
    func testFirstTradeEnglish() {
        verifyShell(language: "en", market: "Market", inventory: "Inventory")
    }

    @MainActor
    func testFirstTradeTurkish() {
        verifyShell(language: "tr", market: "Pazar", inventory: "Envanter")
    }

    @MainActor
    func testLargeTurkishTextAndDeveloperTools() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--uitest-save", UUID().uuidString, "--uitest-large-type"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Pazar"].waitForExistence(timeout: 10))
        tap(app.buttons["listing.listing-42-0"], in: app)
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Turkish accessibility-size listing"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.tabBars.buttons["Profil"].tap()
        tap(app.buttons["developerTools"], in: app)
        tap(app.buttons["debugAddCash"], in: app)
        tap(app.buttons["debugRegenerate"], in: app)
        app.tabBars.buttons["Pazar"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.buttons["listing.listing-43-0"], in: app)
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func verifyShell(language: String, market: String, inventory: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "tr" ? "tr_TR" : "en_US"]
        app.launchArguments += ["--uitest-save", UUID().uuidString]
        app.launch()
        XCTAssertTrue(app.navigationBars[market].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Deniz" : "Alex"].waitForExistence(timeout: 5))
        app.buttons["listing.listing-42-0"].tap()
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
        app.buttons["openConversation"].tap()
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Deniz" : "Alex"].exists)
        tap(app.buttons["askIssues"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons[inventory].tap()
        XCTAssertTrue(app.navigationBars[inventory].exists)
        XCTAssertTrue(app.buttons["inventory.item-42-0"].waitForExistence(timeout: 5))
        app.buttons["inventory.item-42-0"].tap()
        tap(app.buttons["basicInspect"], in: app)
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Temel inceleme tamamlandı" : "Basic inspection complete"].exists)
        tap(app.buttons["createListing"], in: app)
        tap(app.buttons["publishListing"], in: app)
        app.tabBars.buttons[language == "tr" ? "Satışlar" : "Selling"].tap()
        app.buttons["sale.resale-item-42-0-0"].tap()
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.otherElements["saleCompleted"].exists || app.staticTexts[language == "tr" ? "Satıldı" : "Sold"].exists)
        app.terminate()
        app.launch()
        app.tabBars.buttons[inventory].tap()
        XCTAssertTrue(app.staticTexts[language == "tr" ? "İlk ürününü pazarda bul." : "Find your first item in the market."].waitForExistence(timeout: 5))
        app.tabBars.buttons[language == "tr" ? "Profil" : "Profile"].tap()
        app.buttons["openTradeHistory"].tap()
        XCTAssertTrue(app.buttons["trade.resale-item-42-0-0"].waitForExistence(timeout: 5))
    }
    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 {
            if element.exists && element.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
        element.tap()
    }

}
