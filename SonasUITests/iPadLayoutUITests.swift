import XCTest

/// UI Tests for iPadOS-specific layout and interaction.
final class IPadLayoutUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
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
    }

    // MARK: - US1: Expanded Multi-Panel Dashboard

    func testDashboardLayoutOniPad() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This test requires an iPad simulator")
        }

        app.launch()

        // Verify sidebar is visible (FR-011)
        let dashboardButton = app.buttons["Dashboard"]
        XCTAssertTrue(
            dashboardButton.waitForExistence(timeout: 5),
            "Sidebar 'Dashboard' button should be visible on iPad"
        )

        // Verify multiple panels are visible simultaneously (US1 / SC-001)
        XCTAssertTrue(app.otherElements["LocationPanel"].exists, "Location panel should be visible")
        XCTAssertTrue(app.otherElements["EventsPanel"].exists, "Events panel should be visible")
        XCTAssertTrue(app.otherElements["WeatherPanel"].exists, "Weather panel should be visible")
    }

    // MARK: - US2: Keyboard Navigation

    func testKeyboardShortcuts() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This test requires an iPad simulator")
        }

        app.launch()

        // Test Command+2 (Location)
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Location"].waitForExistence(timeout: 2), "Should navigate to Location via ⌘+2")

        // Test Command+1 (Dashboard)
        app.typeKey("1", modifierFlags: .command)
        XCTAssertTrue(app.buttons["Dashboard"].isSelected || app.otherElements["LocationPanel"].exists)
    }

    // MARK: - US2.2: Context Menus (FR-006)

    func testContextMenus() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This test requires an iPad simulator")
        }

        app.launch()

        // Long press a family member to show context menu (simulates right-click/pointer context menu)
        // Note: In UI tests, press(forDuration:) triggers the context menu.
        let memberRow = app.staticTexts["Alice"].firstMatch
        XCTAssertTrue(memberRow.waitForExistence(timeout: 5))
        memberRow.press(forDuration: 2.0)

        XCTAssertTrue(
            app.buttons["Get Directions"].waitForExistence(timeout: 2),
            "Context menu 'Get Directions' should appear"
        )
        XCTAssertTrue(app.buttons["Open in Maps"].exists, "Context menu 'Open in Maps' should appear")
        XCTAssertTrue(app.buttons["Copy Location"].exists, "Context menu 'Copy Location' should appear")
    }
}
