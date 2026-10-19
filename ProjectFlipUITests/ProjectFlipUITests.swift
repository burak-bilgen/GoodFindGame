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
    func testFiveConsecutiveTradesThroughUI() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString, "--uitest-instant"]
        for index in 0..<5 {
            app.launch()
            XCTAssertTrue(app.navigationBars["Market"].waitForExistence(timeout: 10))
            tap(app.buttons["listing.listing-42-\(index)"], in: app)
            tap(app.buttons["openConversation"], in: app)
            tap(app.buttons["askIssues"], in: app)
            tap(app.buttons["sendOffer"], in: app)
            tap(app.buttons["confirmPurchase"], in: app)
            app.tabBars.buttons["Inventory"].tap()
            tap(app.buttons["inventory.item-42-\(index)"], in: app)
            tap(app.buttons["basicInspect"], in: app)
            tap(app.buttons["createListing"], in: app)
            tap(app.buttons["publishListing"], in: app)
            app.tabBars.buttons["Selling"].tap()
            tap(app.buttons["sale.resale-item-42-\(index)-\(index)"], in: app)
            tap(app.buttons["acceptBuyerOffer"], in: app)
            tap(app.buttons["Trade breakdown"], in: app)
            XCTAssertTrue(app.staticTexts["Net profit / loss"].exists)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Trade \(index + 1) cost and profit breakdown"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        tap(app.buttons["openTradeHistory"], in: app)
        XCTAssertTrue(app.staticTexts["5 completed trades"].exists)
    }

    @MainActor
    func testTimedTurkishTradeSurvivesRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--uitest-save", UUID().uuidString]
        app.launch()
        XCTAssertTrue(app.navigationBars["Pazar"].waitForExistence(timeout: 10))
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        XCTAssertTrue(app.staticTexts["Satıcının yanıtı bekleniyor"].exists)
        XCTAssertTrue(app.buttons["confirmPurchase"].waitForExistence(timeout: 10))
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons["Envanter"].tap()
        XCTAssertTrue(app.otherElements["shipment.item-42-0"].exists || app.staticTexts["Ürünün yolda"].exists)
        XCTAssertTrue(app.buttons["inventory.item-42-0"].waitForExistence(timeout: 10))
        tap(app.buttons["inventory.item-42-0"], in: app)
        tap(app.buttons["professionalInspect"], in: app)
        XCTAssertTrue(app.staticTexts["Uzman incelemesi sürüyor"].exists)
        app.terminate()
        app.launch()
        app.tabBars.buttons["Envanter"].tap()
        tap(app.buttons["inventory.item-42-0"], in: app)
        XCTAssertTrue(app.staticTexts["Temel inceleme tamamlandı"].waitForExistence(timeout: 10))
        tap(app.buttons["createListing"], in: app)
        tap(app.buttons["publishListing"], in: app)
        app.tabBars.buttons["Satışlar"].tap()
        tap(app.buttons["sale.resale-item-42-0-0"], in: app)
        XCTAssertTrue(app.buttons["acceptBuyerOffer"].waitForExistence(timeout: 10))
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts["Satıldı"].exists)
    }

    @MainActor
    func testNotificationCategoriesPersistAndRouteOpensExactConversation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        tap(app.buttons["notificationSettings"], in: app)
        if app.buttons["enableNotifications"].exists { XCTAssertFalse(app.buttons["enableNotifications"].isEnabled) }
        let category = app.switches["notificationCategory.offers"]
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        category.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let switchedOff = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"), object: category)
        XCTAssertEqual(XCTWaiter.wait(for: [switchedOff], timeout: 3), .completed)
        XCTAssertEqual(category.value as? String, "0")
        app.tabBars.buttons["Market"].tap()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        app.terminate()
        app.launchArguments += ["--uitest-route", "{\"kind\":\"conversation\",\"targetID\":\"listing-42-0\"}"]
        app.launch()
        XCTAssertTrue(app.buttons["confirmPurchase"].waitForExistence(timeout: 10))
        tap(app.buttons["closeNotificationDestination"], in: app)
        app.tabBars.buttons["Profile"].tap()
        tap(app.buttons["notificationSettings"], in: app)
        XCTAssertEqual(app.switches["notificationCategory.offers"].value as? String, "0")
    }

    @MainActor
    func testNativeNotificationDeliveryAndTapRouting() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["askIssues"], in: app)
        app.tabBars.buttons["Profile"].tap()
        tap(app.buttons["notificationSettings"], in: app)
        if app.buttons["enableNotifications"].exists {
            app.buttons["enableNotifications"].tap()
            let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
            XCTAssertTrue(alert.waitForExistence(timeout: 5))
            let allow = alert.buttons.matching(NSPredicate(format: "label IN %@", ["Allow", "İzin Ver", "İzin ver"])).firstMatch
            XCTAssertTrue(allow.exists, "Permission buttons: \(alert.buttons.allElementsBoundByIndex.map(\.label))")
            allow.tap()
        }
        XCTAssertTrue(app.staticTexts["Notifications are enabled."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Messages"].tap()
        tap(app.buttons["Veltri Arc 2"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let body = springboard.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Alex accepted")).firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 15))
        let attachment = XCTAttachment(screenshot: springboard.screenshot())
        attachment.name = "Actual scheduled iOS notification"
        attachment.lifetime = .keepAlways
        add(attachment)
        body.tap()
        XCTAssertTrue(app.buttons["closeNotificationDestination"].waitForExistence(timeout: 10))
        for _ in 0..<4 where !app.buttons["confirmPurchase"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["confirmPurchase"].exists)
        XCTAssertTrue(app.navigationBars["Messages"].exists)
    }

    @MainActor
    func testDebugTimeTravelReturnSummaryCanBeAcknowledged() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        app.tabBars.buttons["Profile"].tap()
        tap(app.buttons["developerTools"], in: app)
        tap(app.buttons["debugAdvance30Minutes"], in: app)
        XCTAssertTrue(app.navigationBars["While you were away"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Expired offers"].exists)
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["Market"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.navigationBars["While you were away"].exists)
    }

    @MainActor
    func testWatchlistAndFiltersEnglish() { verifyMarketControls(language: "en") }

    @MainActor
    func testWatchlistAndFiltersTurkish() { verifyMarketControls(language: "tr") }

    @MainActor
    private func verifyMarketControls(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        let market = turkish ? "Pazar" : "Market"
        XCTAssertTrue(app.navigationBars[market].waitForExistence(timeout: 10))
        tap(app.buttons["listing.listing-42-0"], in: app)
        app.buttons["toggleWatch"].tap()
        XCTAssertTrue(app.buttons[turkish ? "İzlemeyi bırak" : "Stop watching"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars[market].waitForExistence(timeout: 10))
        app.switches["watchedOnly"].switches.firstMatch.tap()
        XCTAssertTrue(app.buttons["listing.listing-42-0"].exists)
        let removed = NSPredicate(format: "exists == false")
        expectation(for: removed, evaluatedWith: app.buttons["listing.listing-42-1"])
        waitForExpectations(timeout: 5)
        tap(app.buttons["marketFilters"], in: app)
        let maximum = app.textFields["maximumPrice"]
        tap(maximum, in: app)
        maximum.typeText("0")
        tap(app.buttons[turkish ? "Tamam" : "Done"], in: app)
        XCTAssertTrue(app.staticTexts[turkish ? "Bu filtrelere uyan izlenen ilan yok." : "No watched listings match these filters."].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Localized market filters: \(language)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons[turkish ? "Filtreleri temizle" : "Clear filters"].tap()
        app.swipeDown()
        let search = app.searchFields.firstMatch
        tap(search, in: app)
        search.typeText("no-such-model")
        XCTAssertTrue(app.staticTexts[turkish ? "Bu filtrelere uyan ilan yok." : "No listings match these filters."].waitForExistence(timeout: 3))
    }

    @MainActor
    private func verifyShell(language: String, market: String, inventory: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "tr" ? "tr_TR" : "en_US"]
        app.launchArguments += ["--uitest-save", UUID().uuidString, "--uitest-instant"]
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
