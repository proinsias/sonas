import XCTest

@MainActor
final class MacDashboardUITests: XCTestCase {
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

        // Handle location permission if it still appears despite mocks
        addUIInterruptionMonitor(withDescription: "Location Permission") { alert -> Bool in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.click()
                return true
            }
            return false
        }

        app.launch()
    }

    func test_sidebar_containsAllSections() {
        let sidebar = app.outlines["Sidebar"].exists ? app.outlines["Sidebar"] : app.tables["Sidebar"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "Sidebar should exist")

        let sections = ["Dashboard", "Location", "Calendar", "Weather", "Tasks", "Photos", "Jam"]
        for section in sections {
            XCTAssertTrue(sidebar.buttons[section].firstMatch.exists, "Section \(section) should exist in sidebar")
        }
    }

    func test_navigation_updatesDetailView() {
        let sidebar = app.outlines["Sidebar"].exists ? app.outlines["Sidebar"] : app.tables["Sidebar"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "Sidebar should exist")

        // Navigate to Calendar
        sidebar.buttons["Calendar"].firstMatch.click()
        XCTAssertTrue(app.staticTexts["Calendar"].waitForExistence(timeout: 5))

        // Navigate to Weather
        sidebar.buttons["Weather"].firstMatch.click()
        XCTAssertTrue(app.staticTexts["Weather"].waitForExistence(timeout: 5))

        // Navigate back to Dashboard
        sidebar.buttons["Dashboard"].firstMatch.click()
        XCTAssertTrue(app.staticTexts["Sonas"].waitForExistence(timeout: 5))
    }

    func test_window_defaultSize() {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "Main window should exist")
        // Default size 1200x800
        // Add small delay to allow window to settle to its default size
        usleep(500_000) // 500ms
        XCTAssertEqual(window.frame.width, 1200, accuracy: 20)
        XCTAssertEqual(window.frame.height, 800, accuracy: 20)
    }
}
