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

        // Give the view a moment to update after the click
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Let's first see if ANY text appears to debug
        let allTextCount = app.descendants(matching: .staticText).count
        print("Found \(allTextCount) static text elements in app")

        // .textCase(.uppercase) is visual only; accessibility labels stay mixed-case.
        // Search descendants-of-any to cope with MenuBarExtra(.window) popups that
        // may appear outside the immediate children of app.
        let familyLoc = app.descendants(matching: .staticText).matching(identifier: "Family Locations").firstMatch
        XCTAssertTrue(
            familyLoc.waitForExistence(timeout: 10),
            "Family Locations label must appear in popover"
        )
        XCTAssertTrue(
            app.descendants(matching: .staticText).matching(identifier: "Next Event").firstMatch.exists
        )
        XCTAssertTrue(
            app.descendants(matching: .staticText).matching(identifier: "Weather").firstMatch.exists
        )
        XCTAssertTrue(
            app.descendants(matching: .button).matching(identifier: "Open Sonas").firstMatch.exists
        )
    }
}
