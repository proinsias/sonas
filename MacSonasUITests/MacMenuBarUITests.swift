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

    /// Debug helper: prints labels of the first `limit` static text elements found in the hierarchy.
    private func debugPrintStaticTextLabels(from query: XCUIElementQuery, limit: Int) {
        let allTextElements = query
        let allTextCount = allTextElements.count
        print("Found \(allTextCount) static text elements in app")
        for idx in 0 ..< min(allTextCount, limit) {
            let element = allTextElements.element(boundBy: idx)
            if let label = element.label as? String {
                print("  Text[\(idx)]: '\(label)'")
            }
        }
    }

    func test_menuBar_popover_opens() {
        var menuBar = app.statusItems["Sonas"]
        if !menuBar.exists {
            menuBar = app.statusItems["Home"]
        }

        XCTAssertTrue(menuBar.waitForExistence(timeout: 5))
        menuBar.click()

        // Give the popover time to animate in and update.
        sleep(2)

        // Debug: print first few static text labels to see accessibility hierarchy
        debugPrintStaticTextLabels(from: app.descendants(matching: .staticText), limit: 20)

        // .textCase(.uppercase) is visual only; accessibility labels stay mixed-case.
        // Search descendants-of-any to cope with MenuBarExtra(.window) popups that
        // may appear outside the immediate children of app.
        XCTAssertTrue(
            app.descendants(matching: .staticText)
                .matching(identifier: "Family Locations")
                .firstMatch
                .waitForExistence(timeout: 20),
            "Family Locations label must appear in popover"
        )
        XCTAssertTrue(
            app.descendants(matching: .staticText)
                .matching(identifier: "Next Event")
                .firstMatch
                .exists
        )
        XCTAssertTrue(
            app.descendants(matching: .staticText)
                .matching(identifier: "Weather")
                .firstMatch
                .exists
        )
        XCTAssertTrue(
            app.descendants(matching: .button)
                .matching(identifier: "Open Sonas")
                .firstMatch
                .exists
        )
    }
}
