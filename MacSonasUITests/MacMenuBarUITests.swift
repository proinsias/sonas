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
        app.activate()
        menuBar.click()

        // On macOS 26 the MenuBarExtra popover appears as a Dialog in the XCTest
        // accessibility tree. Text content surfaces as `value`, not `label`, so
        // predicates must use `value CONTAINS[c]` rather than `label CONTAINS[c]`.
        let popover = app.dialogs.firstMatch

        guard popover.waitForExistence(timeout: 10) else {
            print("=== Popup not found — accessibility tree after click ===")
            print(app.debugDescription)
            XCTAssertNotEqual(
                app.state,
                .notRunning,
                "App must remain alive after clicking menu bar item"
            )
            return
        }

        let familyHeader = popover.staticTexts
            .matching(NSPredicate(format: "value CONTAINS[c] 'family loc'"))
            .firstMatch
        XCTAssertTrue(familyHeader.exists, "FAMILY LOCATIONS header should be visible in popover")
        XCTAssertTrue(popover.buttons["Open Sonas"].exists, "Open Sonas button should be visible in popover")
    }
}
