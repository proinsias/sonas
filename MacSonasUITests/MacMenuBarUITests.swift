import XCTest

@MainActor
final class MacMenuBarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
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
        let homeMenuBar = app.statusItems["Home"]
        XCTAssertTrue(menuBar.exists || homeMenuBar.exists, "Status item 'Sonas' or 'Home' should exist")
    }

    func test_menuBar_popover_opens() {
        var menuBar = app.statusItems["Sonas"]
        if !menuBar.exists {
            menuBar = app.statusItems["Home"]
        }

        XCTAssertTrue(menuBar.waitForExistence(timeout: 5))
        menuBar.click()

        // On macOS 26 the MenuBarExtra(.window) popup may not surface children
        // via app.staticTexts directly — anchor to the container element first.
        let popover = app.otherElements["MenuBarPopover"]
        XCTAssertTrue(popover.waitForExistence(timeout: 5), "MenuBarPopover container must appear")

        // .textCase(.uppercase) is visual only; accessibility labels stay mixed-case
        XCTAssertTrue(popover.staticTexts["Family Locations"].exists)
        XCTAssertTrue(popover.staticTexts["Next Event"].exists)
        XCTAssertTrue(popover.staticTexts["Weather"].exists)

        // Check for "Open Sonas" button
        XCTAssertTrue(popover.buttons["Open Sonas"].exists)
    }
}
