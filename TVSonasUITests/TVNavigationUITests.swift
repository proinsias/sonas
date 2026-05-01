import XCTest

// MARK: - TVNavigationUITests (T025)

@MainActor
final class TVNavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
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

    func testDirectionalPadMovesFocusBetweenPanels() async {
        app.launch()

        let weatherPanel = app.buttons["WeatherPanel"]
        let eventsPanel = app.buttons["EventsPanel"]

        XCTAssertTrue(weatherPanel.waitForExistence(timeout: 30))

        // Wait for focus to settle (SC-004)
        let hasFocus = NSPredicate(format: "hasFocus == true")
        let focusExpectation = expectation(for: hasFocus, evaluatedWith: weatherPanel)
        await fulfillment(of: [focusExpectation], timeout: 10)

        XCUIRemote.shared.press(.right)

        XCTAssertTrue(
            eventsPanel.waitForExistence(timeout: 5),
            "EventsPanel should exist"
        )
    }

    // MARK: - Scenario 2: Select on WeatherPanel pushes detail view

    func testSelectOnWeatherPanelPushesDetailView() async {
        app.launch()

        let weatherPanel = app.buttons["WeatherPanel"]
        XCTAssertTrue(
            weatherPanel.waitForExistence(timeout: 30),
            "WeatherPanel should appear before interacting"
        )

        // Wait for focus to settle (SC-004)
        let hasFocus = NSPredicate(format: "hasFocus == true")
        let focusExpectation = expectation(for: hasFocus, evaluatedWith: weatherPanel)
        await fulfillment(of: [focusExpectation], timeout: 10)

        XCUIRemote.shared.press(.select)

        // Detail view might take a moment to push and render
        XCTAssertTrue(
            app.scrollViews["WeatherDetailView"].waitForExistence(timeout: 20),
            "WeatherDetailView should appear after pressing Select on focused WeatherPanel"
        )
    }

    // MARK: - Scenario 3: Menu/Back pops to grid

    func testBackFromDetailPopsToGrid() async {
        app.launch()

        let weatherPanel = app.buttons["WeatherPanel"]
        XCTAssertTrue(weatherPanel.waitForExistence(timeout: 30))

        // Wait for focus to settle (SC-004)
        let hasFocus = NSPredicate(format: "hasFocus == true")
        let focusExpectation = expectation(for: hasFocus, evaluatedWith: weatherPanel)
        await fulfillment(of: [focusExpectation], timeout: 10)

        XCUIRemote.shared.press(.select)

        XCTAssertTrue(
            app.scrollViews["WeatherDetailView"].waitForExistence(timeout: 20),
            "Should be in detail view after select"
        )

        // Menu button on Siri Remote pops the navigation stack
        XCUIRemote.shared.press(.menu)

        XCTAssertTrue(
            weatherPanel.waitForExistence(timeout: 20),
            "WeatherPanel should be visible again after pressing Menu"
        )
    }
}
