import XCTest

@MainActor final class PriceLearningUITests: XCTestCase {
    func testQuietListingReviewShowsRealHistoryWithoutChangingTheDraft() {
        continueAfterFailure = false
        for (code, locale, large) in [("en", "en_US", false), ("tr", "tr_TR", true)] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale, "--uitest-save", UUID().uuidString,
                                   "--uitest-instant", "--uitest-quiet-sale", "--uitest-reduce-motion"]
            if large { app.launchArguments.append("--uitest-large-type") }
            app.launch()
            let handoff = app.buttons["marketSalePending"]
            XCTAssertTrue(handoff.waitForExistence(timeout: 15)); handoff.tap()
            let review = app.buttons["reviewQuietPrice"]
            reveal(review, app); review.tap()
            let field = app.textFields["salePrice"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            let original = field.value as? String
            XCTAssertNotNil(original)
            let memory = app.buttons["previousMarketSale"]
            reveal(memory, app)
            let image = XCTAttachment(screenshot: app.screenshot()); image.name = "Price learning \(code) large=\(large)"; image.lifetime = .keepAlways; add(image)
            XCTAssertFalse(app.buttons["updateSalePrice"].isEnabled)
            memory.tap()
            XCTAssertTrue(app.staticTexts["tradePayoff"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            XCTAssertEqual(field.value as? String, original)
            XCTAssertFalse(app.buttons["updateSalePrice"].isEnabled)
            app.terminate()
        }
    }
    private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
        for _ in 0..<12 { if element.exists && element.isHittable { return }; app.swipeUp() }
        if !element.exists || !element.isHittable { print(app.debugDescription) }
        XCTAssertTrue(element.exists); XCTAssertTrue(element.isHittable)
    }
}
