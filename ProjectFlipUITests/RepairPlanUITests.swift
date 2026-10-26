import XCTest

@MainActor final class RepairPlanUITests: XCTestCase {
    func testLargeTextCombinedRepairsRemainReachable() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--uitest-save", UUID().uuidString,
            "--uitest-instant", "--uitest-reduce-motion", "--uitest-repair-plan", "--uitest-large-type"]
        app.launch()
        XCTAssertTrue(app.buttons["gameTab.2"].waitForExistence(timeout: 10)); app.buttons["gameTab.2"].tap()
        tap(app.buttons["inventory.repair-plan-fixture"], app: app)
        tap(app.buttons["openRepairPlan"], app: app)
        XCTAssertGreaterThan(app.staticTexts["repairPlanProductTitle"].frame.height, 60, "The accessibility-size text fixture must actually be active.")
        tap(app.switches["planFault.damagedPort"], app: app)
        tap(app.switches["planFault.drift"], app: app)
        let apply = app.buttons["applyRepairPlan"]
        for _ in 0..<12 {
            if apply.exists && apply.isHittable && apply.frame.maxY <= app.buttons["gameTab.2"].frame.minY { break }
            app.swipeUp()
        }
        XCTAssertTrue(apply.isEnabled)
        XCTAssertLessThanOrEqual(apply.frame.maxY, app.buttons["gameTab.2"].frame.minY)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Large text combined repair plan"; shot.lifetime = .keepAlways; add(shot)
        apply.tap()
        XCTAssertFalse(app.buttons["repair.damagedPort"].exists)
        XCTAssertFalse(app.buttons["repair.drift"].exists)
        XCTAssertFalse(app.buttons["openRepairPlan"].exists)
        XCTAssertTrue(app.buttons["createListing"].exists)
    }

    func testSelectiveWorkIsChargedOnceAndPersistsAcrossLanguages() {
        continueAfterFailure = false
        for (language, locale) in [("en", "en_US"), ("tr", "tr_TR"), ("de", "de_DE"), ("fr", "fr_FR"), ("es", "es_ES"), ("it", "it_IT")] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale,
                "--uitest-save", UUID().uuidString, "--uitest-instant", "--uitest-reduce-motion", "--uitest-repair-plan"]
            app.launch()
            XCTAssertTrue(app.buttons["gameTab.2"].waitForExistence(timeout: 10)); app.buttons["gameTab.2"].tap()
            tap(app.buttons["inventory.repair-plan-fixture"], app: app)
            tap(app.buttons["openRepairPlan"], app: app)
            XCTAssertTrue(app.switches["planFault.drift"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.switches["planFault.batteryWear"].exists)
            XCTAssertFalse(app.buttons["applyRepairPlan"].isEnabled)
            app.switches["planFault.drift"].tap()
            let quote = app.staticTexts["planCost"].label
            XCTAssertFalse(quote.isEmpty)
            XCTAssertNotNil(quote.range(of: "[,.][0-9]{2}(?:[^0-9]|$)", options: .regularExpression), "The displayed bill must include the exact minor units charged.")
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Selective repair plan \(language)"; shot.lifetime = .keepAlways; add(shot)
            tap(app.buttons["applyRepairPlan"], app: app)
            XCTAssertFalse(app.buttons["repair.drift"].exists)
            XCTAssertTrue(app.buttons["repair.damagedPort"].exists)
            app.terminate(); app.launch()
            app.buttons["gameTab.2"].tap()
            tap(app.buttons["inventory.repair-plan-fixture"], app: app)
            tap(app.buttons["openRepairPlan"], app: app)
            XCTAssertFalse(app.switches["planFault.drift"].exists)
            XCTAssertTrue(app.switches["planFault.damagedPort"].exists)
            tap(app.buttons["leaveRepairPlan"], app: app)
            XCTAssertTrue(app.buttons["repair.damagedPort"].exists)
            app.terminate()
        }
    }

    private func tap(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<12 { if element.exists && element.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(element.exists)
        element.tap()
    }
}
