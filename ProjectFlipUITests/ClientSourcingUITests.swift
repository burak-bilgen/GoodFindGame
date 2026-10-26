import XCTest

@MainActor final class ClientSourcingUITests: XCTestCase {
    func testAnUnavailableClientModelExplainsTheNextChoices() {
        continueAfterFailure = false
        let app = makeApp(code: "en", locale: "en_US")
        app.launch()
        app.buttons["gameTab.1"].tap()
        tap(app.buttons["openClients"], app: app)
        tap(app.buttons["client.noah"], app: app)
        tap(app.buttons["acceptClient.noah"], app: app)
        app.buttons["gameTab.0"].tap()
        tap(app.buttons["clientHuntFilter"], app: app)
        XCTAssertTrue(app.staticTexts["No matching models right now"].waitForExistence(timeout: 5))
        let hint = app.staticTexts["clientNoModelsHint"]
        XCTAssertTrue(hint.exists)
        XCTAssertTrue(hint.label.contains("first sale"))
        XCTAssertLessThanOrEqual(hint.frame.maxY, app.buttons["gameTab.0"].frame.minY)
        capture("Client sourcing with no current stock", app: app)
        tap(app.buttons["clientHuntFilter"], app: app)
        XCTAssertTrue(app.buttons["listing.listing-42-0"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No matching models right now"].exists)
    }

    func testRequestsCanGuideTheHuntWithoutClaimingVerifiedCondition() {
        continueAfterFailure = false
        for (code, locale) in [("en", "en_US"), ("tr", "tr_TR")] {
            let app = makeApp(code: code, locale: locale)
            app.launch()
            XCTAssertTrue(app.buttons["gameTab.1"].waitForExistence(timeout: 10))
            app.buttons["gameTab.1"].tap()
            tap(app.buttons["openClients"], app: app)
            tap(app.buttons["client.mira"], app: app)
            tap(app.buttons["acceptClient.mira"], app: app)
            XCTAssertFalse(app.buttons["acceptClient.mira"].exists)
            app.buttons["gameTab.0"].tap()
            tap(app.buttons["clientHuntFilter"], app: app)
            XCTAssertTrue(app.buttons["listing.listing-42-10"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["listing.listing-42-0"].exists)
            capture("Client hunt \(code)", app: app)
            tap(app.buttons["listing.listing-42-10"], app: app)
            XCTAssertTrue(app.descendants(matching: .any)["clientModelMatch"].firstMatch.exists)
            XCTAssertFalse(app.staticTexts["inspectionCondition"].exists)
            app.terminate(); app.launch()
            XCTAssertTrue(app.buttons["clientHuntFilter"].waitForExistence(timeout: 10))
            tap(app.buttons["clientHuntFilter"], app: app)
            XCTAssertTrue(app.buttons["listing.listing-42-10"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testSupplyingOwnedStockShowsItsReceiptAndUnlocksAPersistedCosmeticTitle() {
        continueAfterFailure = false
        let app = makeApp(code: "en", locale: "en_US")
        app.launchArguments.append("--uitest-client-finale")
        app.launch()
        XCTAssertTrue(app.buttons["marketClientReady"].waitForExistence(timeout: 10))
        tap(app.buttons["marketClientReady"], app: app)
        tap(app.buttons["supplyOwnedClient"], app: app)
        XCTAssertTrue(app.staticTexts["tradePayoff"].waitForExistence(timeout: 5))
        capture("Client story finale receipt", app: app)
        app.terminate(); app.launch()
        app.buttons["gameTab.2"].tap()
        XCTAssertFalse(app.buttons["inventory.client-finale-item"].exists)
        app.buttons["gameTab.4"].tap()
        tap(app.buttons["editProfile"], app: app)
        let field = app.textFields["playerName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        if let text = field.value as? String, text != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count))
        }
        field.typeText("Alex")
        tap(app.buttons["displayTitle"], app: app)
        tap(app.buttons["Neighborhood regular"].firstMatch, app: app)
        tap(app.buttons["saveProfile"], app: app)
        XCTAssertTrue(app.staticTexts["playerDisplayTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["playerDisplayTitle"].label, "Neighborhood regular")
        app.terminate(); app.launch()
        app.buttons["gameTab.4"].tap()
        XCTAssertTrue(app.staticTexts["playerDisplayTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["playerDisplayTitle"].label, "Neighborhood regular")
        capture("Earned client title", app: app)
    }

    private func makeApp(code: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale, "--uitest-save", UUID().uuidString,
                               "--uitest-instant", "--uitest-reduce-motion"]
        return app
    }
    private func tap(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<10 { if element.exists && element.isHittable { break }; app.swipeUp() }
        if !element.exists { capture("Missing client control", app: app); print(app.debugDescription) }
        XCTAssertTrue(element.exists)
        element.tap()
    }
    private func capture(_ name: String, app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
}
