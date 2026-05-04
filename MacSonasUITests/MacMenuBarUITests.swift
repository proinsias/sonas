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

        // MenuBarExtra(.window) opens a separate window. Try finding it across
        // all windows of the app, not just descendants of the main app element.
        var found = false
        for windowIdx in 0 ..< app.windows.count {
            let window = app.windows.element(boundBy: windowIdx)
            let texts = window.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'family loc'"))
            if !texts.isEmpty {
                found = true
                print("Found 'family loc' in window \(windowIdx)")
                break
            }
        }
        XCTAssertTrue(found, "Family Locations should appear in at least one window after menu bar click")
    }
}
