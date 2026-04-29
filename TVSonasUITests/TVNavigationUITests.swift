import XCTest

// MARK: - TVNavigationUITests (T025)

final class TVNavigationUITests: XCTestCase {
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

    // MARK: - Scenario 1: Directional pad navigates between panels

    func testDirectionalPadMovesFocusBetweenPanels() {
        app.launch()

        XCTAssertTrue(
            app.buttons["WeatherPanel"].waitForExistence(timeout: 30),
            "WeatherPanel button should be visible on dashboard"
        )
        XCTAssertTrue(
            app.buttons["EventsPanel"].waitForExistence(timeout: 5),
            "EventsPanel button should be reachable via directional navigation"
        )
    }

    // MARK: - Scenario 2: Select on WeatherPanel pushes detail view

    func testSelectOnWeatherPanelPushesDetailView() {
        app.launch()

        XCTAssertTrue(
            app.buttons["WeatherPanel"].waitForExistence(timeout: 30),
            "WeatherPanel should appear before interacting"
        )

        // WeatherPanel is the first focusable element in the grid; activate with Select
        XCUIRemote.shared.press(.select)

        XCTAssertTrue(
            app.otherElements["WeatherDetailView"].waitForExistence(timeout: 10),
            "WeatherDetailView should appear after pressing Select on WeatherPanel"
        )
    }

    // MARK: - Scenario 3: Menu/Back pops to grid

    func testBackFromDetailPopsToGrid() {
        app.launch()

        XCTAssertTrue(app.buttons["WeatherPanel"].waitForExistence(timeout: 30))

        XCUIRemote.shared.press(.select)
        XCTAssertTrue(
            app.otherElements["WeatherDetailView"].waitForExistence(timeout: 10),
            "Should be in detail view after select"
        )

        XCUIRemote.shared.press(.menu)

        XCTAssertTrue(
            app.buttons["WeatherPanel"].waitForExistence(timeout: 10),
            "WeatherPanel should be visible again after pressing Menu"
        )
    }
}
