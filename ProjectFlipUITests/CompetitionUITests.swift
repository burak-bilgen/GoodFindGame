import XCTest

@MainActor final class CompetitionUITests: XCTestCase {
    func testCompetitionEnglish() { verifyCompetition(language: "en") }
    func testCompetitionTurkish() { verifyCompetition(language: "tr") }
    func testCompetitionLargeTurkish() { verifyCompetition(language: "tr", flags: ["--uitest-large-type", "--uitest-reduce-motion"]) }
    func testCompetitionReducedMotionEnglish() { verifyCompetition(language: "en", flags: ["--uitest-reduce-motion"]) }
    func testCompetitionIsOptionalBeforeFirstTrade() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--uitest-save", UUID().uuidString]
        app.launch()
        XCTAssertTrue(app.buttons["listing.listing-42-0"].waitForExistence(timeout: 10))
        app.buttons["gameTab.4"].tap()
        reveal(app.buttons["openCompetition"], in: app)
        app.buttons["openCompetition"].tap()
        XCTAssertTrue(app.staticTexts["localCompetition"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["connectGameCenter"].exists)
        XCTAssertFalse(app.buttons["startWeekly"].exists)
        XCTAssertTrue(app.staticTexts["Complete three career trades to enter your first weekly challenge."].exists)
        app.buttons["gameTab.0"].tap()
        XCTAssertTrue(app.buttons["listing.listing-42-0"].exists)
    }
    private func verifyCompetition(language: String, flags: [String] = []) {
        continueAfterFailure = false
        let app = XCUIApplication(), turkish = language == "tr"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", turkish ? "tr_TR" : "en_US",
                               "--uitest-save", UUID().uuidString, "--uitest-competition-fixture"] + flags
        app.launch()
        XCTAssertTrue(app.buttons["gameTab.4"].waitForExistence(timeout: 10))
        app.buttons["gameTab.4"].tap()
        reveal(app.buttons["openCompetition"], in: app)
        app.buttons["openCompetition"].tap()
        XCTAssertTrue(app.staticTexts["weeklyScore"].waitForExistence(timeout: 5))
        capture("Competition \(language) \(flags)", app: app)
        reveal(app.buttons["startWeekly"], in: app)
        app.buttons["startWeekly"].tap()
        XCTAssertTrue(app.buttons["leaveWeekly"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[turkish ? "Haftanın Al-Satı · Ayrı sermaye" : "Weekly Flip · Separate bankroll"].exists)
        let cash = app.staticTexts["marketCash"]
        XCTAssertTrue(cash.waitForExistence(timeout: 5))
        XCTAssertTrue(cash.label.contains(turkish ? "40.000" : "1,000"))
        capture("Isolated weekly market \(language) \(flags)", app: app)
        app.buttons["leaveWeekly"].tap()
        reveal(app.staticTexts["localCompetition"], in: app)
        XCTAssertFalse(app.buttons["connectGameCenter"].exists)
        capture("Optional Game Center \(language)", app: app)
        // Reopen from a durable file; never ask for authentication in an automated test.
        app.terminate(); app.launch()
        app.buttons["gameTab.4"].tap()
        reveal(app.buttons["openCompetition"], in: app)
        app.buttons["openCompetition"].tap()
        reveal(app.buttons["startWeekly"], in: app)
        XCTAssertTrue(app.buttons["startWeekly"].label.contains(turkish ? "dön" : "Return"))
        reveal(app.buttons["finalizeWeekly"], in: app)
        app.buttons["finalizeWeekly"].tap()
        let finish = app.buttons["confirmFinalizeWeekly"].firstMatch
        XCTAssertTrue(finish.waitForExistence(timeout: 5)); finish.tap()
        XCTAssertTrue(app.staticTexts[turkish ? "Bu haftanın sonucu kesinleşti" : "This week’s result is final"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["startWeekly"].exists)
        capture("Finalized offline \(language)", app: app)
    }
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Element unavailable: \(element)")
    }
    private func capture(_ title: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = title; attachment.lifetime = .keepAlways; add(attachment)
    }
}
