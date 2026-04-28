import XCTest

final class MacMenuBarUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func test_menuBar_exists() {
        let menuBar = app.statusItems["Sonas"]
        XCTAssertTrue(menuBar.exists)
    }

    func test_menuBar_popover_opens() {
        let menuBar = app.statusItems["Sonas"]
        menuBar.click()

        // Check for sections in popover
        XCTAssertTrue(app.staticTexts["Family Locations"].exists)
        XCTAssertTrue(app.staticTexts["Next Event"].exists)
        XCTAssertTrue(app.staticTexts["Weather"].exists)

        // Check for "Open Sonas" button
        XCTAssertTrue(app.buttons["Open Sonas"].exists)
    }
}
