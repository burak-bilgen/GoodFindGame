import XCTest

@MainActor final class RepricingUITests: XCTestCase {
    func testLargeTextPriceRevisionShowsTheRiskBeforeCommitting() {
        continueAfterFailure = false
        let app = makeSale(code: "tr", locale: "tr_TR", flags: ["--uitest-large-type"])
        tap(app.buttons["İlan fiyatını güncelle"].firstMatch, app: app)
        let field = app.textFields["salePrice"]
        tap(field, app: app)
        if let value = field.value as? String { field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)) }
        field.typeText("40000")
        tap(app.buttons["Tamam"], app: app)
        XCTAssertTrue(app.staticTexts["saleRepricingConsequence"].label.contains("pazarlığını"))
        let apply = app.buttons["updateSalePrice"]
        for _ in 0..<12 {
            if apply.exists && apply.isHittable && apply.frame.maxY <= app.buttons["gameTab.3"].frame.minY { break }
            app.swipeUp()
        }
        XCTAssertTrue(apply.isEnabled)
        XCTAssertLessThanOrEqual(apply.frame.maxY, app.buttons["gameTab.3"].frame.minY)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Large text repricing preview"; shot.lifetime = .keepAlways; add(shot)
        apply.tap()
        XCTAssertTrue(app.staticTexts["salePriceUnchanged"].waitForExistence(timeout: 5))
        app.terminate()
    }

    func testUnchangedPriceKeepsTheOfferAndAnEditExplainsItsConsequences() {
        continueAfterFailure = false
        for (code, locale, editor, amount, displayed) in [
            ("en", "en_US", "Update asking price", "1000", "1,000.00"),
            ("tr", "tr_TR", "İlan fiyatını güncelle", "40000", "40.000,00")
        ] {
            let app = makeSale(code: code, locale: locale)
            let heldOffer = app.staticTexts["buyerOfferAmount"].label
            tap(app.buttons[editor].firstMatch, app: app)
            XCTAssertTrue(app.staticTexts["salePriceUnchanged"].exists)
            XCTAssertFalse(app.buttons["updateSalePrice"].isEnabled)
            XCTAssertEqual(app.staticTexts["buyerOfferAmount"].label, heldOffer)
            let field = app.textFields["salePrice"]
            tap(field, app: app)
            if let value = field.value as? String { field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)) }
            field.typeText(amount)
            if app.buttons[code == "tr" ? "Tamam" : "Done"].exists { app.buttons[code == "tr" ? "Tamam" : "Done"].tap() }
            XCTAssertTrue(app.staticTexts["saleRepricingConsequence"].exists)
            let preview = XCTAttachment(screenshot: app.screenshot()); preview.name = "Repricing decision \(code)"; preview.lifetime = .keepAlways; add(preview)
            tap(app.buttons["updateSalePrice"], app: app)
            XCTAssertFalse(app.buttons["updateSalePrice"].isEnabled)
            XCTAssertFalse(app.buttons["acceptBuyerOffer"].exists)
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Sale repricing \(code)"; shot.lifetime = .keepAlways; add(shot)
            app.terminate(); app.launch()
            app.buttons["gameTab.3"].tap()
            tap(app.buttons["sale.resale-item-42-0-0"], app: app)
            XCTAssertTrue(app.staticTexts["saleAskingPrice"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["saleAskingPrice"].label.contains(displayed))
            XCTAssertFalse(app.buttons["acceptBuyerOffer"].exists)
            app.terminate()
        }
    }

    private func makeSale(code: String, locale: String, flags: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale,
            "--uitest-save", UUID().uuidString, "--uitest-instant", "--uitest-reduce-motion"] + flags
        app.launch()
        XCTAssertTrue(app.buttons["listing.listing-42-0"].waitForExistence(timeout: 10))
        tap(app.buttons["listing.listing-42-0"], app: app)
        for id in ["openConversation", "askIssues", "sendOffer", "confirmPurchase", "continueToItem", "basicInspect", "createListing", "publishListing", "followPlayerListing"] { tap(app.buttons[id], app: app) }
        XCTAssertTrue(app.buttons["acceptBuyerOffer"].waitForExistence(timeout: 5))
        return app
    }

    private func tap(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<12 { if element.exists && element.isHittable && element.isEnabled { break }; app.swipeUp() }
        XCTAssertTrue(element.exists)
        element.tap()
    }
}
