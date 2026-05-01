import XCTest

@MainActor
final class MacMenuBarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = [
            "USE_MOCK_LOCATION": "1",
            "USE_MOCK_WEATHER": "1",
            "USE_MOCK_CALENDAR": "1",
            "USE_MOCK_TASKS": "1",
            "USE_MOCK_PHOTOS": "1",
            "USE_MOCK_JAM": "1"
        ]
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
