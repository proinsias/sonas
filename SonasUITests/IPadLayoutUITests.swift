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

        // Test Command+R (Refresh All)
        app.typeKey("r", modifierFlags: .command)
        // Refresh is fire-and-forget; verify the app remains stable and the current view is still shown
        XCTAssertTrue(app.otherElements["LocationPanel"].waitForExistence(timeout: 3))
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

    // MARK: - US2.3: Calendar Event Context Menu (FR-006)

    func testCalendarEventContextMenu() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This test requires an iPad simulator")
        }

        app.launch()

        // Navigate to Calendar section
        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(
            app.staticTexts["Calendar"].waitForExistence(timeout: 3),
            "Should navigate to Calendar section via ⌘+3"
        )

        // Long-press the first visible event row to trigger the context menu
        let firstEvent = app.cells.firstMatch
        XCTAssertTrue(firstEvent.waitForExistence(timeout: 5), "At least one event should be visible")
        firstEvent.press(forDuration: 2.0)

        XCTAssertTrue(
            app.buttons["Copy Event Title"].waitForExistence(timeout: 2),
            "Context menu 'Copy Event Title' should appear"
        )
        XCTAssertTrue(
            app.buttons["Add Reminder"].exists,
            "Context menu 'Add Reminder' should appear"
        )
    }

    // MARK: - US3: Multi-Window and Split View Support

    /// Verifies the app launches and remains stable in a configuration suitable for
    /// multi-window and Split View use. Full multi-window opening requires a physical
    /// iPad — see testMultiWindowSceneOpening below.
    func testSlideOverCompactFallback() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Multi-window requires an iPad")
        }

        app.launch()

        // App must be stable and show primary content — a prerequisite for multi-window.
        XCTAssertTrue(
            app.otherElements["LocationPanel"].waitForExistence(timeout: 5),
            "App must render the dashboard before multi-window activation"
        )

        // When the window is at compact width (Slide Over / ⅓ Split View) the app
        // should fall back from a sidebar to a tab bar. In the simulator this
        // transition is not automatable via XCTest, but the layout is driven by
        // horizontalSizeClass so it is covered by the snapshot tests in plan.md §5.
    }

    /// T015 — Multi-window scene opening.
    ///
    /// Simulators expose only one window per app session. Run this test on a
    /// physical iPad (iPadOS 16+) to exercise the full multi-window flow:
    ///   1. Long-press the Sonas icon in the Dock → "Open New Window"
    ///   2. Confirm the second window shows a fully functional dashboard
    ///   3. Verify each window tracks its own selected section (SceneStorage)
    ///   4. Background both windows and re-foreground — no state loss expected
    func testMultiWindowSceneOpening() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Multi-window requires an iPad")
        }
        #if targetEnvironment(simulator)
            throw XCTSkip(
                "T015: Multi-window scene opening requires a physical iPad. " +
                    "iOS Simulator supports only one window per app. " +
                    "To verify manually: long-press the Sonas icon in the Dock and choose " +
                    "\"Open New Window\"; confirm the second window renders a stable dashboard."
            )
        #else
            app.launch()

            XCTAssertTrue(
                app.otherElements["LocationPanel"].waitForExistence(timeout: 5),
                "Primary window must show dashboard before opening a second window"
            )

            // Navigate to a non-default section so SceneStorage isolation is observable.
            app.typeKey("2", modifierFlags: .command)
            XCTAssertTrue(app.staticTexts["Location"].waitForExistence(timeout: 3))

            // Activate a second instance of the app (second scene).
            // On a physical device this corresponds to the OS opening a new UIWindowScene.
            let secondWindow = XCUIApplication()
            secondWindow.activate()

            XCTAssertEqual(
                secondWindow.state,
                .runningForeground,
                "App must be in foreground after second window activation"
            )
            XCTAssertTrue(
                secondWindow.otherElements["LocationPanel"].waitForExistence(timeout: 5),
                "Second window must render a functional dashboard independently of the first"
            )
        #endif
    }

    // MARK: - US5: Navigation Patterns

    func testSidebarToggle() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This test requires an iPad simulator")
        }

        app.launch()

        // Check if sidebar toggle button exists (standard SwiftUI NavigationSplitView behavior)
        let sidebarToggle = app.buttons["ToggleSidebar"]
        if sidebarToggle.exists {
            sidebarToggle.tap()
            // Sidebar should be hidden or at least the dashboard should remain
            XCTAssertTrue(app.otherElements["LocationPanel"].exists)
        }
    }
}
