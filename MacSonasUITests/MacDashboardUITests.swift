import XCTest

final class MacDashboardUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func test_sidebar_containsAllSections() {
        let sidebar = app.lists["Sidebar"]
        XCTAssertTrue(sidebar.exists)

        let sections = ["Dashboard", "Location", "Calendar", "Weather", "Tasks", "Photos", "Jam"]
        for section in sections {
            XCTAssertTrue(sidebar.buttons[section].exists, "Section \(section) should exist in sidebar")
        }
    }

    func test_navigation_updatesDetailView() {
        let sidebar = app.lists["Sidebar"]

        // Navigate to Calendar
        sidebar.buttons["Calendar"].click()
        XCTAssertTrue(app.staticTexts["Calendar"].exists)

        // Navigate to Weather
        sidebar.buttons["Weather"].click()
        XCTAssertTrue(app.staticTexts["Weather"].exists)

        // Navigate back to Dashboard
        sidebar.buttons["Dashboard"].click()
        XCTAssertTrue(app.staticTexts["Sonas"].exists)
    }

    func test_window_defaultSize() {
        let window = app.windows["main"]
        XCTAssertTrue(window.exists)
        // Default size 1200x800
        XCTAssertEqual(window.frame.width, 1200, accuracy: 10)
        XCTAssertEqual(window.frame.height, 800, accuracy: 10)
    }
}
