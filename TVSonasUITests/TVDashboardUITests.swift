import XCTest

// MARK: - TVDashboardUITests (T018)

@MainActor
final class TVDashboardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = [
            "USE_MOCK_WEATHER": "1",
            "USE_MOCK_CALENDAR": "1",
            "USE_MOCK_LOCATION": "1",
            "USE_MOCK_TASKS": "1",
            "USE_MOCK_PHOTOS": "1",
            "USE_MOCK_JAM": "1"
        ]
    }

    // MARK: - Scenario 1: Dashboard panels present with mock data

    func testDashboardPanelsPresentWithMockData() {
        app.launch()

        XCTAssertTrue(
            app.buttons["WeatherPanel"].waitForExistence(timeout: 30),
            "WeatherPanel should be visible on the dashboard"
        )
        XCTAssertTrue(
            app.buttons["EventsPanel"].waitForExistence(timeout: 5),
            "EventsPanel should be visible on the dashboard"
        )
        XCTAssertTrue(
            app.buttons["LocationPanel"].waitForExistence(timeout: 5),
            "LocationPanel should be visible on the dashboard"
        )
        XCTAssertTrue(
            app.buttons["TasksPanel"].waitForExistence(timeout: 5),
            "TasksPanel should be visible on the dashboard"
        )
        XCTAssertTrue(
            app.buttons["JamPanel"].waitForExistence(timeout: 5),
            "JamPanel should be visible on the dashboard"
        )
        XCTAssertTrue(
            app.buttons["PhotosPanel"].waitForExistence(timeout: 5),
            "PhotosPanel should be visible on the dashboard"
        )
    }
}
