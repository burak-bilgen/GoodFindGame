import XCTest

final class ProjectFlipUITests: XCTestCase {
    @MainActor
    func testCameraFindingsEnglish() { verifyItemFindings(language: "en", retro: false) }
    @MainActor
    func testCameraFindingsTurkish() { verifyItemFindings(language: "tr", retro: false) }
    @MainActor
    func testRetroFindingsEnglish() { verifyItemFindings(language: "en", retro: true) }
    @MainActor
    func testRetroFindingsTurkish() { verifyItemFindings(language: "tr", retro: true) }

    @MainActor
    private func verifyItemFindings(language: String, retro: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        let slot = retro ? 8 : 5
        let key = retro ? "authenticity" : "shutterCount"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-\(slot)"], in: app)
        XCTAssertFalse(app.descendants(matching: .any)["factValue.\(key)"].firstMatch.exists)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
        tap(app.buttons["inventory.item-42-\(slot)"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        tap(app.buttons["openItemFacts"], in: app)
        let locked = app.descendants(matching: .any)["factLocked.\(key)"].firstMatch
        for _ in 0..<8 {
            if locked.exists && locked.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(locked.exists)
        XCTAssertFalse(app.descendants(matching: .any)["factValue.\(key)"].firstMatch.exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.swipeDown()
        app.swipeDown()
        tap(app.buttons["professionalInspect"], in: app)
        tap(app.buttons["openItemFacts"], in: app)
        let measured = app.descendants(matching: .any)["factValue.\(key)"].firstMatch
        for _ in 0..<8 {
            if measured.exists && measured.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(measured.exists)
        XCTAssertFalse(locked.exists)
        let savedValue = measured.label
        XCTAssertFalse(savedValue.isEmpty)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(language) \(retro ? "retro" : "camera") expert findings"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
        app.launch()
        app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
        tap(app.buttons["inventory.item-42-\(slot)"], in: app)
        tap(app.buttons["openItemFacts"], in: app)
        for _ in 0..<8 {
            if measured.exists && measured.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(measured.exists)
        XCTAssertEqual(measured.label, savedValue)
    }

    @MainActor
    func testKnowledgeEnglish() { verifyKnowledge(language: "en") }

    @MainActor
    func testKnowledgeTurkish() { verifyKnowledge(language: "tr") }

    @MainActor
    private func verifyKnowledge(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US", "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        app.tabBars.buttons[turkish ? "Profil" : "Profile"].tap()
        tap(app.buttons["openKnowledge"], in: app)
        tap(app.buttons["buyTools.cameras"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["toolsOwned.cameras"].firstMatch.exists)
        XCTAssertFalse(app.buttons["buyTools.cameras"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons[turkish ? "Pazar" : "Market"].tap()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
        tap(app.buttons["inventory.item-42-0"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        app.tabBars.buttons[turkish ? "Profil" : "Profile"].tap()
        tap(app.buttons["openKnowledge"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["knowledgePoints.gaming"].firstMatch.label.contains("1"))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(language) category learning and permanent tools"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
        app.launch()
        app.tabBars.buttons[turkish ? "Profil" : "Profile"].tap()
        tap(app.buttons["openKnowledge"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["knowledgePoints.gaming"].firstMatch.label.contains("1"))
        let owned = app.descendants(matching: .any)["toolsOwned.cameras"].firstMatch
        for _ in 0..<5 {
            if owned.exists { break }
            app.swipeUp()
        }
        XCTAssertTrue(owned.exists)
        XCTAssertFalse(app.buttons["buyTools.cameras"].exists)
        let restored = XCTAttachment(screenshot: app.screenshot())
        restored.name = "\(language) restored camera kit"
        restored.lifetime = .keepAlways
        add(restored)
    }

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
            XCTAssertTrue(app.staticTexts["tradePayoff"].waitForExistence(timeout: 5))
            tap(app.buttons["Where the margin went"], in: app)
            for prefix in ["Acquisition cost,", "Inspection costs,", "Repair costs,", "Total cost,"] {
                let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
                XCTAssertTrue(row.waitForExistence(timeout: 5))
            }
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
        tap(app.buttons["conversation.listing-42-0"], in: app)
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
        capture("return summary: en", app: app)
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
        app.switches["watchedOnly"].coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
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
    func testMarketTrendsEnglish() { verifyShell(language: "en", market: "Market", inventory: "Inventory", followTrends: true) }

    @MainActor
    func testMarketTrendsTurkish() { verifyShell(language: "tr", market: "Pazar", inventory: "Envanter", followTrends: true) }

    @MainActor
    func testNewCategoriesEnglish() { verifyNewCategories(language: "en") }

    @MainActor
    func testNewCategoriesTurkish() { verifyNewCategories(language: "tr") }

    @MainActor
    private func verifyNewCategories(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].waitForExistence(timeout: 10))
        tap(app.buttons["marketFilters"], in: app)
        tap(app.buttons["marketCategory"], in: app)
        app.buttons[turkish ? "Fotoğraf makineleri" : "Cameras"].tap()
        tap(app.buttons["listing.listing-42-5"], in: app)
        XCTAssertTrue(app.staticTexts["Ilyven Luma 3"].exists)
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["listingCategoryName"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["listingCategoryName"].label.contains(turkish ? "Fotoğraf makineleri" : "Cameras"))
        tap(app.buttons["toggleWatch"], in: app)
        app.navigationBars.buttons.firstMatch.tap()
        app.swipeDown()
        tap(app.buttons["marketCategory"], in: app)
        app.buttons[turkish ? "Retro ve koleksiyon" : "Retro & collectibles"].tap()
        tap(app.buttons["listing.listing-42-8"], in: app)
        XCTAssertTrue(app.staticTexts["Yoriva Chapter 8"].exists)
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["listingCategoryName"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["listingCategoryName"].label.contains(turkish ? "Retro ve koleksiyon" : "Retro & collectibles"))
        tap(app.buttons["toggleWatch"], in: app)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Retro category listing: \(language)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
        app.launch()
        app.switches["watchedOnly"].coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        tap(app.buttons["listing.listing-42-5"], in: app)
        XCTAssertTrue(app.staticTexts["Ilyven Luma 3"].exists)
    }

    @MainActor
    func testLiveMarketFeedEnglish() { verifyShell(language: "en", market: "Market", inventory: "Inventory", followFeed: true) }

    @MainActor
    func testLiveMarketFeedTurkish() { verifyShell(language: "tr", market: "Pazar", inventory: "Envanter", followFeed: true) }

    @MainActor
    private func verifyShell(language: String, market: String, inventory: String, followTrends: Bool = false, followFeed: Bool = false) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "tr" ? "tr_TR" : "en_US"]
        app.launchArguments += ["--uitest-save", UUID().uuidString]
        if !followFeed { app.launchArguments += ["--uitest-instant"] }
        app.launch()
        XCTAssertTrue(app.navigationBars[market].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Deniz" : "Alex"].waitForExistence(timeout: 5))
        capture("market: \(language)", app: app)
        app.buttons["listing.listing-42-0"].tap()
        XCTAssertTrue(app.buttons["openConversation"].waitForExistence(timeout: 5))
        capture("listing: \(language)", app: app)
        XCTAssertFalse(app.staticTexts["inspectionCondition"].exists)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Henüz bilinmiyor" : "Still unknown"].exists)
        capture("listing investigation: \(language)", app: app)
        app.buttons["openConversation"].tap()
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Deniz" : "Alex"].exists)
        tap(app.buttons["askIssues"], in: app)
        if followFeed {
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["sendOffer"])
            waitForExpectations(timeout: 10)
        }
        capture("seller conversation: \(language)", app: app)
        tap(app.buttons["sendOffer"], in: app)
        capture("agreed offer: \(language)", app: app)
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons[inventory].tap()
        XCTAssertTrue(app.navigationBars[inventory].exists)
        XCTAssertTrue(app.buttons["inventory.item-42-0"].waitForExistence(timeout: followFeed ? 10 : 5))
        app.buttons["inventory.item-42-0"].tap()
        tap(app.buttons["basicInspect"], in: app)
        XCTAssertTrue(app.staticTexts[language == "tr" ? "Temel inceleme tamamlandı" : "Basic inspection complete"].exists)
        capture("inspection: \(language)", app: app)
        tap(app.buttons["createListing"], in: app)
        capture("resale price: \(language)", app: app)
        tap(app.buttons["publishListing"], in: app)
        app.tabBars.buttons[language == "tr" ? "Satışlar" : "Selling"].tap()
        app.buttons["sale.resale-item-42-0-0"].tap()
        if followFeed { XCTAssertTrue(app.buttons["acceptBuyerOffer"].waitForExistence(timeout: 10)) }
        capture("buyer offer: \(language)", app: app)
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.otherElements["saleCompleted"].exists || app.staticTexts[language == "tr" ? "Satıldı" : "Sold"].exists)
        capture("trade result: \(language)", app: app)
        app.terminate()
        app.launch()
        app.tabBars.buttons[inventory].tap()
        XCTAssertTrue(app.staticTexts[language == "tr" ? "İlk ürününü pazarda bul." : "Find your first item in the market."].waitForExistence(timeout: 5))
        app.tabBars.buttons[language == "tr" ? "Profil" : "Profile"].tap()
        app.buttons["openTradeHistory"].tap()
        XCTAssertTrue(app.buttons["trade.resale-item-42-0-0"].waitForExistence(timeout: 5))
        if followFeed {
            app.tabBars.buttons[market].tap()
            tap(app.buttons["listing.listing-42-1"], in: app)
            tap(app.buttons["toggleWatch"], in: app)
            app.navigationBars.buttons.firstMatch.tap()
            app.tabBars.buttons[language == "tr" ? "Profil" : "Profile"].tap()
            app.navigationBars.buttons.firstMatch.tap()
            tap(app.buttons["developerTools"], in: app)
            tap(app.buttons["debugAdvanceDay"], in: app)
            XCTAssertTrue(app.navigationBars[language == "tr" ? "Sen yokken" : "While you were away"].waitForExistence(timeout: 5))
            tap(app.buttons[language == "tr" ? "Tamam" : "Done"], in: app)
            app.tabBars.buttons[market].tap()
            tap(app.buttons["listing.listing-44-0"], in: app)
            XCTAssertTrue(app.buttons["openConversation"].exists)
            app.terminate()
            app.launch()
            XCTAssertTrue(app.navigationBars[market].waitForExistence(timeout: 10))
            app.switches["watchedOnly"].coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            tap(app.buttons["listing.listing-42-1"], in: app)
            XCTAssertFalse(app.buttons["openConversation"].exists)
            let expired = app.staticTexts[language == "tr" ? "İlanın süresi doldu" : "Listing expired"]
            let bought = app.staticTexts[language == "tr" ? "Başka bir alıcı aldı" : "Bought by another trader"]
            XCTAssertTrue(expired.exists || bought.exists)
            app.swipeUp()
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Actual archived watched listing: \(language)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        if followTrends {
            app.navigationBars.buttons.firstMatch.tap()
            tap(app.buttons["developerTools"], in: app)
            tap(app.buttons["debugAdvanceDay"], in: app)
            XCTAssertTrue(app.navigationBars[language == "tr" ? "Sen yokken" : "While you were away"].waitForExistence(timeout: 5))
            tap(app.buttons[language == "tr" ? "Tamam" : "Done"], in: app)
            app.tabBars.buttons[market].tap()
            tap(app.buttons["openMarketTrends"], in: app)
            let trend = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "marketTrend.")).firstMatch
            tap(trend, in: app)
            XCTAssertTrue(app.staticTexts[language == "tr" ? "Devam ediyor" : "Active"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts[language == "tr" ? "Kalan süre" : "Time remaining"].exists)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Actual market trend: \(language)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.terminate()
            app.launch()
            tap(app.buttons["openMarketTrends"], in: app)
            XCTAssertTrue(app.staticTexts[language == "tr" ? "Devam ediyor" : "Active"].waitForExistence(timeout: 5))
        }
    }
    @MainActor
    func testConnectedTradeEnglish() { connectedTrade(language: "en") }
    @MainActor
    func testConnectedTradeTurkish() { connectedTrade(language: "tr", repairStarter: true) }

    @MainActor
    func testLargeTurkishRepairTrade() {
        connectedTrade(language: "tr", flags: ["--uitest-large-type", "--uitest-reduce-motion"], repairStarter: true)
    }

    @MainActor
    func testReducedMotionDarkTradeEnglish() {
        connectedTrade(language: "en", flags: ["--uitest-reduce-motion", "--uitest-dark"], repairStarter: true)
    }

    @MainActor
    private func connectedTrade(language: String, flags: [String] = [], repairStarter: Bool = false) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US", "--uitest-save", UUID().uuidString] + flags
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["askIssues"], in: app)
        let send = app.buttons["sendOffer"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: send)
        waitForExpectations(timeout: 10)
        let field = app.textFields["offerAmount"]
        tap(field, in: app)
        let value = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count) + "1600")
        app.buttons[turkish ? "Tamam" : "Done"].tap()
        tap(send, in: app)
        XCTAssertTrue(app.buttons["acceptSellerCounter"].waitForExistence(timeout: 10))
        capture("seller counter: \(language)", app: app)
        tap(app.buttons["acceptSellerCounter"], in: app)
        XCTAssertTrue(app.staticTexts["purchaseBudgetAmount"].isHittable)
        capture("purchase cash decision: \(language)", app: app)
        tap(app.buttons["confirmPurchase"], in: app)
        XCTAssertTrue(app.buttons["continueToItem"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts[turkish ? "İlan artık mevcut değil" : "Listing unavailable"].exists)
        capture("purchase commitment: \(language)", app: app)
        tap(app.buttons["continueToItem"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        XCTAssertTrue(app.staticTexts[turkish ? "Temel inceleme tamamlandı" : "Basic inspection complete"].waitForExistence(timeout: 5))
        capture("connected inspection: \(language)", app: app)
        if repairStarter {
            let repair = app.buttons["repair.damagedPort"]
            for _ in 0..<8 {
                if repair.exists && repair.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(app.staticTexts["repairMargin.damagedPort"].label.contains("+"))
            XCTAssertTrue(app.staticTexts[turkish ? "Değer artışı onarımı karşılayıp kazanç payını artırabilir." : "The added value may cover the repair and leave more margin."].exists)
            XCTAssertTrue(app.buttons["createListing"].exists)
            capture("repair quote: \(language)", app: app)
            tap(repair, in: app)
            XCTAssertFalse(app.buttons["repair.damagedPort"].exists)
            capture("starter repaired: \(language)", app: app)
        }
        tap(app.buttons["createListing"], in: app)
        let asking = app.textFields["askingPrice"]
        let originalPrice = asking.value as? String
        tap(app.buttons["priceSuggestion.2"], in: app)
        XCTAssertNotEqual(asking.value as? String, originalPrice)
        tap(app.buttons["priceSuggestion.1"], in: app)
        XCTAssertEqual(asking.value as? String, originalPrice)
        capture("pricing choices: \(language)", app: app)
        tap(app.buttons["publishListing"], in: app)
        tap(app.buttons["followPlayerListing"], in: app)
        XCTAssertTrue(app.buttons["acceptBuyerOffer"].waitForExistence(timeout: 10))
        tap(app.buttons[turkish ? "Karşı teklif gönder" : "Send counteroffer"].firstMatch, in: app)
        tap(app.buttons["sendBuyerCounter"], in: app)
        XCTAssertTrue(app.buttons["acceptBuyerOffer"].exists)
        XCTAssertTrue(app.staticTexts["buyerOfferAmount"].isHittable)
        capture("buyer counter: \(language)", app: app)
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts["tradePayoff"].isHittable)
        capture("connected payoff: \(language)", app: app)
        tap(app.buttons["returnToHunt"], in: app)
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["listing.listing-42-1"].exists)
        capture("next hunt: \(language)", app: app)
    }

    @MainActor
    func testPurchaseBudgetEnglish() { purchaseBudget(language: "en", spendFirst: false) }
    @MainActor
    func testPurchaseBudgetTurkish() { purchaseBudget(language: "tr", spendFirst: false) }
    @MainActor
    func testPurchaseCashLimitEnglish() { purchaseBudget(language: "en", spendFirst: true) }
    @MainActor
    func testPurchaseCashLimitTurkish() { purchaseBudget(language: "tr", spendFirst: true) }

    @MainActor
    private func purchaseBudget(language: String, spendFirst: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        let initialCash = app.staticTexts["marketCash"].label
        if spendFirst {
            // Three actual purchases leave 570.85; no money or save fixture is injected.
            for slot in [1, 3, 5] {
                tap(app.buttons["listing.listing-42-\(slot)"], in: app)
                tap(app.buttons["openConversation"], in: app)
                tap(app.buttons["sendOffer"], in: app)
                tap(app.buttons["confirmPurchase"], in: app)
                app.navigationBars.buttons.firstMatch.tap()
                app.navigationBars.buttons.firstMatch.tap()
            }
            for _ in 0..<5 {
                if app.buttons["listing.listing-42-0"].isHittable { break }
                app.swipeDown()
            }
        }
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        XCTAssertTrue(app.buttons["confirmPurchase"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["purchaseBudgetAmount"].isHittable)
        XCTAssertEqual(app.buttons["confirmPurchase"].isEnabled, !spendFirst)
        let expected = spendFirst ? (turkish ? "1.107,23" : "1,107.23") : (turkish ? "18.321,92" : "18,321.92")
        XCTAssertTrue(app.staticTexts["purchaseBudgetAmount"].label.contains(expected))
        if spendFirst {
            XCTAssertTrue(app.staticTexts[turkish ? "Kullanılabilir nakdin yeterli değil." : "You don’t have enough available cash."].exists)
        }
        capture("purchase budget \(spendFirst ? "shortfall" : "preview"): \(language)", app: app)
        tap(app.buttons["declinePurchase"], in: app)
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].exists)
        let unchangedCash = app.staticTexts["marketCash"].label
        if spendFirst { XCTAssertTrue(unchangedCash.contains(turkish ? "570,85" : "570.85")) }
        else { XCTAssertEqual(unchangedCash, initialCash) }
        app.terminate()
        app.launch()
        XCTAssertEqual(app.staticTexts["marketCash"].label, unchangedCash)
        app.tabBars.buttons[turkish ? "Mesajlar" : "Messages"].tap()
        tap(app.buttons["conversation.listing-42-0"], in: app)
        XCTAssertFalse(app.buttons["confirmPurchase"].exists)
        XCTAssertFalse(app.buttons["continueToItem"].exists)
        XCTAssertFalse(app.buttons["followDelivery"].exists)
    }

    @MainActor
    func testBuyerCounterDecisionEnglish() { buyerCounterDecision(language: "en") }
    @MainActor
    func testBuyerCounterDecisionTurkish() { buyerCounterDecision(language: "tr") }

    @MainActor
    private func buyerCounterDecision(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        tap(app.buttons["continueToItem"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        tap(app.buttons["createListing"], in: app)
        tap(app.buttons["publishListing"], in: app)
        tap(app.buttons["followPlayerListing"], in: app)
        let amount = app.staticTexts["buyerOfferAmount"]
        let originalOffer = amount.label
        XCTAssertFalse(app.textFields["buyerCounterAmount"].exists)
        capture("buyer first offer: \(language)", app: app)
        tap(app.buttons[turkish ? "Karşı teklif gönder" : "Send counteroffer"].firstMatch, in: app)
        XCTAssertTrue(app.textFields["buyerCounterAmount"].exists)
        XCTAssertTrue(app.staticTexts[turkish ? "Kabul ederse ürün karşı teklif ettiğin fiyattan satılır." : "If they accept, the item sells at your counteroffer."].exists)
        app.swipeUp()
        capture("buyer counter commitment: \(language)", app: app)
        tap(app.buttons["sendBuyerCounter"], in: app)
        XCTAssertTrue(app.staticTexts[turkish ? "Alıcıdan karşı teklif" : "Buyer counteroffer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["buyerCounterAmount"].exists)
        XCTAssertTrue(app.buttons["acceptBuyerOffer"].exists)
        XCTAssertTrue(app.staticTexts[turkish ? "Alıcı sınırını söyledi. Zorlarsan satış kaçabilir." : "They’ve named their limit. Pushing again could lose the sale."].exists)
        let counter = amount.label
        XCTAssertFalse(counter.isEmpty)
        capture("buyer limit decision: \(language)", app: app)
        app.terminate()
        app.launch()
        tap(app.buttons["marketBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts[turkish ? "Alıcıdan karşı teklif" : "Buyer counteroffer"].exists)
        XCTAssertEqual(amount.label, counter)
        XCTAssertFalse(app.textFields["buyerCounterAmount"].exists)
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts["tradePayoff"].exists)
        XCTAssertFalse(app.buttons["acceptBuyerOffer"].exists)
        tap(app.buttons["returnToHunt"], in: app)
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].exists)
        XCTAssertFalse(originalOffer.isEmpty)
    }

    @MainActor
    func testLiveListingCanKeepHuntingEnglish() { liveListingCanKeepHunting(language: "en") }
    @MainActor
    func testLiveListingCanKeepHuntingTurkish() { liveListingCanKeepHunting(language: "tr") }

    @MainActor
    private func liveListingCanKeepHunting(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        tap(app.buttons["continueToItem"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        tap(app.buttons["createListing"], in: app)
        let asking = app.textFields["askingPrice"]
        let sensiblePrice = asking.value as? String ?? ""
        tap(asking, in: app)
        asking.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: sensiblePrice.count) + "99999")
        app.buttons[turkish ? "Tamam" : "Done"].tap()
        tap(app.buttons["publishListing"], in: app)
        tap(app.buttons["followPlayerListing"], in: app)
        XCTAssertTrue(app.staticTexts[turkish ? "Henüz alıcı teklifi yok." : "No buyer offers yet."].exists)
        XCTAssertFalse(app.buttons["acceptBuyerOffer"].exists)
        XCTAssertFalse(app.buttons["findAnotherBuyer"].exists)
        capture("live listing waiting: \(language)", app: app)
        tap(app.buttons["returnToHunt"], in: app)
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].exists)
        app.terminate()
        app.launch()
        app.tabBars.buttons[turkish ? "Satışlar" : "Selling"].tap()
        tap(app.buttons["sale.resale-item-42-0-0"], in: app)
        XCTAssertFalse(app.buttons["acceptBuyerOffer"].exists)
        tap(app.buttons[turkish ? "İlan fiyatını güncelle" : "Update asking price"].firstMatch, in: app)
        let revision = app.textFields["salePrice"]
        tap(revision, in: app)
        let old = revision.value as? String ?? ""
        revision.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + sensiblePrice)
        app.buttons[turkish ? "Tamam" : "Done"].tap()
        tap(app.buttons["updateSalePrice"], in: app)
        XCTAssertTrue(app.buttons["acceptBuyerOffer"].waitForExistence(timeout: 10))
        capture("buyer after price revision: \(language)", app: app)
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts["tradePayoff"].exists)
    }

    @MainActor
    func testRepairWaitsForExpertEnglish() { repairWaitsForExpert(language: "en") }
    @MainActor
    func testRepairWaitsForExpertTurkish() { repairWaitsForExpert(language: "tr") }

    @MainActor
    private func repairWaitsForExpert(language: String) {
        continueAfterFailure = false
        let turkish = language == "tr"
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-reduce-motion"]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        XCTAssertTrue(app.buttons["confirmPurchase"].waitForExistence(timeout: 10))
        tap(app.buttons["confirmPurchase"], in: app)
        XCTAssertTrue(app.buttons["continueToItem"].waitForExistence(timeout: 10))
        tap(app.buttons["continueToItem"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        tap(app.buttons["professionalInspect"], in: app)
        let repair = app.buttons["repair.damagedPort"]
        XCTAssertTrue(repair.exists)
        XCTAssertFalse(repair.isEnabled)
        XCTAssertTrue(app.staticTexts[turkish ? "Uzman incelemesi bitince onarım yapabilirsin." : "Repair is available when the expert inspection finishes."].exists)
        capture("repair waiting for expert: \(language)", app: app)
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: repair)
        waitForExpectations(timeout: 12)
        XCTAssertTrue(app.staticTexts["repairMargin.damagedPort"].label.contains("+"))
        capture("repair available after expert: \(language)", app: app)
        tap(repair, in: app)
        XCTAssertFalse(repair.exists)
        tap(app.buttons["createListing"], in: app)
        XCTAssertTrue(app.textFields["askingPrice"].exists)
    }

    @MainActor
    func testInspectionReportReopensWithoutChangingTruth() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons["Inventory"].tap()
        tap(app.buttons["inventory.item-42-0"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        let condition = app.staticTexts["inspectionCondition"]
        XCTAssertTrue(condition.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        let knownCondition = condition.label
        tap(app.buttons["openItemFacts"], in: app)
        app.navigationBars.buttons.firstMatch.tap()
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        XCTAssertEqual(condition.label, knownCondition)
        XCTAssertFalse(app.buttons["skipReveal"].exists)
        capture("reopened inspection report: en", app: app)
    }

    @MainActor
    func testCounterDecisionEnglish() { counterDecision(language: "en") }

    @MainActor
    func testCounterDecisionTurkish() { counterDecision(language: "tr") }

    @MainActor
    private func counterDecision(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-0"], in: app)
        tap(app.buttons["openConversation"], in: app)
        let field = app.textFields["offerAmount"]
        tap(field, in: app)
        let initial = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: initial.count) + "1600")
        app.buttons[turkish ? "Tamam" : "Done"].tap()
        tap(app.buttons["sendOffer"], in: app)
        XCTAssertTrue(app.buttons["acceptSellerCounter"].waitForExistence(timeout: 5))
        XCTAssertFalse(field.exists)
        capture("seller decision: \(language)", app: app)
        tap(app.buttons[turkish ? "Pazarlığa devam et" : "Keep bargaining"], in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let previous = field.value as? String
        tap(app.buttons["offerHalfway"], in: app)
        XCTAssertNotEqual(field.value as? String, previous)
        XCTAssertFalse(app.buttons["confirmPurchase"].exists)
        capture("editable seller reply: \(language)", app: app)
        tap(app.buttons["sendOffer"], in: app)
        XCTAssertTrue(app.buttons["acceptSellerCounter"].waitForExistence(timeout: 5))
        XCTAssertFalse(field.exists)
        tap(app.buttons["acceptSellerCounter"], in: app)
        XCTAssertTrue(app.buttons["confirmPurchase"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTradeContinuationEnglish() { tradeContinuation(language: "en") }

    @MainActor
    func testTradeContinuationTurkish() { tradeContinuation(language: "tr") }

    @MainActor
    private func tradeContinuation(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        app.tabBars.buttons[turkish ? "Mesajlar" : "Messages"].tap()
        XCTAssertTrue(app.staticTexts[turkish ? "Bir ilanı aç, satıcıyla konuş. Tek bir ipucu pazarlığı değiştirebilir." : "Open a listing. Talk to the seller. One clue can change the deal."].waitForExistence(timeout: 5))
        capture("empty inbox: \(language)", app: app)
        tap(app.buttons["returnToHunt"], in: app)
        for slot in 0...1 {
            tap(app.buttons["listing.listing-42-\(slot)"], in: app)
            tap(app.buttons["openConversation"], in: app)
            tap(app.buttons["sendOffer"], in: app)
            tap(app.buttons["confirmPurchase"], in: app)
            app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
            tap(app.buttons["inventory.item-42-\(slot)"], in: app)
            tap(app.buttons["basicInspect"], in: app)
            tap(app.buttons["createListing"], in: app)
            tap(app.buttons["publishListing"], in: app)
            app.terminate()
            app.launch()
            XCTAssertTrue(app.buttons["marketBuyerOffer"].waitForExistence(timeout: 5))
            capture("waiting buyer trade \(slot + 1): \(language)", app: app)
            tap(app.buttons["marketBuyerOffer"], in: app)
            XCTAssertTrue(app.buttons["acceptBuyerOffer"].exists)
            if slot == 1 {
                app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
                tap(app.buttons["inventory.item-42-\(slot)"], in: app)
                tap(app.buttons["continueOwnedSale"], in: app)
                XCTAssertTrue(app.buttons["acceptBuyerOffer"].exists)
                app.tabBars.buttons[turkish ? "Mesajlar" : "Messages"].tap()
                tap(app.buttons["conversation.listing-42-\(slot)"], in: app)
                XCTAssertFalse(app.buttons["followDelivery"].exists)
                tap(app.buttons["continueConversationSale"], in: app)
                XCTAssertTrue(app.buttons["acceptBuyerOffer"].exists)
            }
            tap(app.buttons["acceptBuyerOffer"], in: app)
            XCTAssertTrue(app.staticTexts["tradePayoff"].exists)
            app.terminate()
            app.launch()
            XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["marketBuyerOffer"].exists)
            app.tabBars.buttons[turkish ? "Mesajlar" : "Messages"].tap()
            let archivedRow = app.buttons["conversation.listing-42-\(slot)"]
            XCTAssertTrue(archivedRow.staticTexts[turkish ? "Satıldı" : "Sold"].exists)
            capture("completed inbox: \(language)", app: app)
            tap(archivedRow, in: app)
            XCTAssertTrue(app.buttons["continueToTrade"].exists)
            XCTAssertFalse(app.buttons["followDelivery"].exists)
            XCTAssertFalse(app.buttons["continueToItem"].exists)
            capture("settled conversation trade \(slot + 1): \(language)", app: app)
            tap(app.buttons["continueToTrade"], in: app)
            XCTAssertTrue(app.staticTexts["tradePayoff"].exists)
            tap(app.buttons["returnToHunt"], in: app)
            XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].exists)
        }
    }

    @MainActor
    func testKnownFaultLossEnglish() { lossEvidence(language: "en", known: true) }
    @MainActor
    func testKnownFaultLossTurkish() { lossEvidence(language: "tr", known: true) }
    @MainActor
    func testUnknownFaultLossEnglish() { lossEvidence(language: "en", known: false) }
    @MainActor
    func testUnknownFaultLossTurkish() { lossEvidence(language: "tr", known: false) }

    @MainActor
    func testRepairCostLossEnglish() { lossEvidence(language: "en", known: true, repair: true) }
    @MainActor
    func testRepairCostLossTurkish() { lossEvidence(language: "tr", known: true, repair: true) }

    @MainActor
    private func lossEvidence(language: String, known: Bool, repair: Bool = false) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        let scenario = repair ? "repair cost" : known ? "known" : "unknown"
        let shownFault = known && !repair
        let slot = known ? 0 : 2
        let fault = known ? "damagedPort" : "drift"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-\(slot)"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        tap(app.buttons["continueToItem"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        XCTAssertEqual(app.buttons["repair.\(fault)"].exists, known)
        if repair { tap(app.buttons["repair.\(fault)"], in: app) }
        tap(app.buttons["createListing"], in: app)
        let asking = app.textFields["askingPrice"]
        tap(asking, in: app)
        let old = asking.value as? String ?? ""
        asking.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + (repair ? "2200" : "100"))
        app.buttons[turkish ? "Tamam" : "Done"].tap()
        tap(app.buttons["publishListing"], in: app)
        tap(app.buttons["followPlayerListing"], in: app)
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts["tradePayoff"].label.contains("-"))
        capture("loss evidence immediate \(scenario): \(language)", app: app)
        XCTAssertEqual(app.staticTexts["tradeDefect.\(fault)"].exists, shownFault)
        let lesson = app.staticTexts["tradeLesson"].label
        if repair {
            XCTAssertEqual(lesson, turkish ? "Satış, alış fiyatını karşıladı ama onarım ücreti kârı eritti." : "The sale covered the purchase, but the repair bill used up the margin.")
        }
        tap(app.buttons[turkish ? "Alışveriş dökümü" : "Trade breakdown"], in: app)
        XCTAssertEqual(app.staticTexts["tradeLesson"].label, lesson)
        XCTAssertEqual(app.staticTexts["tradeDefect.\(fault)"].exists, shownFault)
        capture("loss evidence receipt \(scenario): \(language)", app: app)
        app.terminate()
        app.launch()
        app.tabBars.buttons[turkish ? "Profil" : "Profile"].tap()
        tap(app.buttons["openTradeHistory"], in: app)
        tap(app.buttons["trade.resale-item-42-\(slot)-0"], in: app)
        XCTAssertEqual(app.staticTexts["tradeLesson"].label, lesson)
        XCTAssertEqual(app.staticTexts["tradeDefect.\(fault)"].exists, shownFault)
        capture("loss evidence history \(scenario): \(language)", app: app)
        tap(app.buttons["returnToHunt"], in: app)
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].exists)
    }

    @MainActor
    func testRepairAndLossEnglish() { repairAndLoss(language: "en") }
    @MainActor
    func testRepairAndLossTurkish() { repairAndLoss(language: "tr") }

    @MainActor
    private func repairAndLoss(language: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        let turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US", "--uitest-save", UUID().uuidString, "--uitest-instant"]
        app.launch()
        tap(app.buttons["listing.listing-42-2"], in: app)
        tap(app.buttons["openConversation"], in: app)
        tap(app.buttons["askIssues"], in: app)
        capture("risk clue: \(language)", app: app)
        tap(app.buttons["sendOffer"], in: app)
        tap(app.buttons["confirmPurchase"], in: app)
        app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
        tap(app.buttons["inventory.item-42-2"], in: app)
        tap(app.buttons["basicInspect"], in: app)
        tap(app.buttons["professionalInspect"], in: app)
        XCTAssertTrue(app.buttons["repair.drift"].waitForExistence(timeout: 5))
        tap(app.buttons["repair.drift"], in: app)
        XCTAssertFalse(app.buttons["repair.drift"].exists)
        capture("repaired: \(language)", app: app)
        app.terminate()
        app.launch()
        app.tabBars.buttons[turkish ? "Envanter" : "Inventory"].tap()
        tap(app.buttons["inventory.item-42-2"], in: app)
        XCTAssertFalse(app.buttons["repair.drift"].exists)
        tap(app.buttons["createListing"], in: app)
        let asking = app.textFields["askingPrice"]
        tap(asking, in: app)
        let current = asking.value as? String ?? ""
        asking.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + "100")
        app.buttons[turkish ? "Tamam" : "Done"].tap()
        tap(app.buttons["publishListing"], in: app)
        tap(app.buttons["followPlayerListing"], in: app)
        tap(app.buttons["acceptBuyerOffer"], in: app)
        XCTAssertTrue(app.staticTexts["tradePayoff"].label.contains("-"))
        capture("loss lesson: \(language)", app: app)
        tap(app.buttons["returnToHunt"], in: app)
        XCTAssertTrue(app.navigationBars[turkish ? "Pazar" : "Market"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func capture(_ name: String, app: XCUIApplication) {
        // Allow the deliberately short game transitions to settle before visual QA.
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable && element.isEnabled { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
        element.tap()
    }

}
