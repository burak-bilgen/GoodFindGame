import XCTest

@MainActor final class NotebookUITests: XCTestCase {
    func testEmptyNotebookKeepsTheHuntReachable() {
        continueAfterFailure = false
        let app = makeApp(code: "en", locale: "en_US")
        app.launch()
        openNotebook(app)
        XCTAssertTrue(app.staticTexts["notebookEmpty"].waitForExistence(timeout: 5))
        reveal(app.buttons["returnToHunt"], app)
        app.buttons["returnToHunt"].tap()
        XCTAssertTrue(app.navigationBars["Market"].waitForExistence(timeout: 5))
    }

    func testRecordedTradesOpenReceiptsAcrossLanguagesAndLargeText() {
        continueAfterFailure = false
        for (code, locale, large) in [("en", "en_US", false), ("tr", "tr_TR", true), ("de", "de_DE", false), ("fr", "fr_FR", false), ("es", "es_ES", false), ("it", "it_IT", false)] {
            let app = makeApp(code: code, locale: locale)
            app.launchArguments.append("--uitest-competition-fixture")
            if large { app.launchArguments.append("--uitest-large-type") }
            app.launch()
            openNotebook(app)
            let latest = app.descendants(matching: .any)["notebookLatest.gaming"].firstMatch
            reveal(latest, app)
            latest.tap()
            let receipt = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "notebookReceipt.")).firstMatch
            reveal(receipt, app)
            capture("Notebook \(code) large=\(large)", app)
            receipt.tap()
            XCTAssertTrue(app.staticTexts["tradePayoff"].waitForExistence(timeout: 5))
            app.terminate(); app.launch()
            openNotebook(app)
            XCTAssertFalse(app.staticTexts["notebookEmpty"].exists)
            app.terminate()
        }
    }
    private func makeApp(code: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(code))", "-AppleLocale", locale, "--uitest-save", UUID().uuidString, "--uitest-instant", "--uitest-reduce-motion"]
        return app
    }
    private func openNotebook(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["gameTab.3"].waitForExistence(timeout: 10))
        app.buttons["gameTab.3"].tap()
        let history = app.buttons["salesHistory"]
        XCTAssertTrue(history.waitForExistence(timeout: 5)); history.tap()
        let notebook = app.buttons["openNotebook"]
        reveal(notebook, app); notebook.tap()
    }
    private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        if !element.exists || !element.isHittable {
            capture("Missing notebook control", app)
            print(app.debugDescription)
        }
        XCTAssertTrue(element.exists)
        XCTAssertTrue(element.isHittable)
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
}
