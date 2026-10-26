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

    func testSpanishAndItalianRootNavigationAndSettings() {
        continueAfterFailure = false
        for (code, locale, title) in [("es", "es_ES", "Ajustes"), ("it", "it_IT", "Impostazioni")] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale, "--uitest-save", UUID().uuidString, "--uitest-reduce-motion"]
            app.launch()
            XCTAssertTrue(app.buttons["gameTab.4"].waitForExistence(timeout: 10))
            app.buttons["gameTab.4"].tap()
            tap(app.buttons["openSettings"], in: app)
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            XCTAssertTrue(app.switches["soundSetting"].exists)
            capture("Settings \(code)", app: app)
            app.terminate()
        }
    }

    func testCompleteTradeSpanishAndItalian() {
        completeTrade(locales: [("es", "es_ES"), ("it", "it_IT")])
    }

    func testLargeTextTradeSpanishAndItalian() {
        completeTrade(flags: ["--uitest-large-type"], locales: [("es", "es_ES"), ("it", "it_IT")])
    }

    func testCompleteTradeGermanAndFrench() {
        completeTrade()
    }

    func testLargeTextTradeGermanAndFrench() {
        completeTrade(flags: ["--uitest-large-type"])
    }

    private func completeTrade(flags: [String] = [], locales: [(String, String)] = [("de", "de_DE"), ("fr", "fr_FR")]) {
        continueAfterFailure = false
        for (code, locale) in locales {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale,
                                   "--uitest-save", UUID().uuidString, "--uitest-instant", "--uitest-reduce-motion"] + flags
            app.launch()
            XCTAssertTrue(app.buttons["listing.listing-42-0"].waitForExistence(timeout: 10))
            capture("Market \(code)", app: app)
            tap(app.buttons["listing.listing-42-0"], in: app)
            capture("Listing \(code)", app: app)
            app.swipeUp()
            XCTAssertTrue(app.descendants(matching: .any)["tradeRead"].firstMatch.exists)
            capture("Trade appraisal \(code)", app: app)
            tap(app.buttons["openConversation"], in: app)
            tap(app.buttons["askIssues"], in: app)
            tap(app.buttons["sendOffer"], in: app)
            tap(app.buttons["confirmPurchase"], in: app)
            tap(app.buttons["continueToItem"], in: app)
            tap(app.buttons["basicInspect"], in: app)
            XCTAssertTrue(app.descendants(matching: .any)["revealedDefect.damagedPort"].firstMatch.waitForExistence(timeout: 5))
            capture("Inspection decision \(code)", app: app)
            if ["fr", "it"].contains(code) { tap(app.buttons["repair.damagedPort"], in: app) }
            tap(app.buttons["createListing"], in: app)
            tap(app.buttons["publishListing"], in: app)
            tap(app.buttons["followPlayerListing"], in: app)
            XCTAssertTrue(app.buttons["acceptBuyerOffer"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["gameTab.3"].value as? String, ["de": "Ein Käufer wartet", "fr": "Un acheteur attend", "es": "Un comprador está esperando", "it": "Un acquirente aspetta"][code])
            if !flags.isEmpty {
                let views = app.descendants(matching: .any)["listingViewsStat"].firstMatch
                let favorites = app.descendants(matching: .any)["listingFavoritesStat"].firstMatch
                XCTAssertTrue(views.exists && favorites.exists)
                XCTAssertFalse((views.value as? String ?? "").isEmpty)
                XCTAssertLessThanOrEqual(views.frame.height, favorites.frame.height * 1.2, "The views count must not wrap its digits")
                XCTAssertLessThanOrEqual(favorites.frame.height, views.frame.height * 1.2, "The favorite count must not wrap its digits")
                for stat in [views, favorites] {
                    XCTAssertGreaterThanOrEqual(stat.frame.minX, 0)
                    XCTAssertLessThanOrEqual(stat.frame.maxX, app.frame.width)
                }
            }
            capture("Buyer decision \(code)", app: app)
            tap(app.buttons["acceptBuyerOffer"], in: app)
            XCTAssertTrue(app.staticTexts["tradePayoff"].waitForExistence(timeout: 5))
            capture("Trade outcome \(code)", app: app)
            tap(app.buttons["returnToHunt"], in: app)
            XCTAssertTrue(app.buttons["listing.listing-42-1"].exists)
            app.terminate()
            app.launch()
            tap(app.buttons["gameTab.3"], in: app)
            tap(app.buttons["salesHistory"], in: app)
            XCTAssertTrue(app.buttons["trade.resale-item-42-0-0"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable && element.isEnabled { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
        element.tap()
    }

    private func capture(_ name: String, app: XCUIApplication) {
        // Match the main trade captures: let native navigation settle before export.
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
    }

}
