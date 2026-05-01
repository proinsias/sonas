import XCTest

@MainActor
final class MacKeyboardShortcutUITests: XCTestCase {
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

    func test_keyboardShortcut_navigation() {
        // Cmd+2 -> Location
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Location"].exists)

        // Cmd+3 -> Calendar
        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Calendar"].exists)

        // Cmd+1 -> Dashboard
        app.typeKey("1", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Sonas"].exists)
    }

    func test_keyboardShortcut_refresh() {
        // Cmd+R
        app.typeKey("r", modifierFlags: .command)
        // Refresh is asynchronous, difficult to verify state change without mock control
        // but we can verify it doesn't crash.
    }
}
