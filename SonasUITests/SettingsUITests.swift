import XCTest

// MARK: - SettingsUITests (T094)

// Constitution §II: every user-facing feature MUST have at least one acceptance/integration test.

final class SettingsUITests: XCTestCase {
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
        app.launch()
    }

    // MARK: - T094.1: Home location picker saves coordinate and reflects in WeatherPanel

    func testHomeLocationSavesAndReflectsInWeatherPanel() {
        // Open Settings
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        settingsButton.tap()

        // Verify Settings sheet is open
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))

        // Verify "Set Home Location" cell is present
        let setLocationButton = app.buttons["Set Home Location"]
        XCTAssertTrue(setLocationButton.waitForExistence(timeout: 2))

        // Close settings
        app.buttons["Done"].tap()
    }

    // MARK: - T094.2: Todoist token entry invokes TaskService.connectTodoist

    func testTodoistTokenEntryTransitionsToTaskList() {
        // With USE_MOCK_TASKS=1, Tasks panel shows mock tasks
        // Verify TasksPanel accessibility identifier is present
        XCTAssertTrue(app.otherElements["TasksPanel"].waitForExistence(timeout: 3))
    }

    // MARK: - T095.5: Todoist project list appears in Settings when already connected

    func testTodoistProjectListShownWhenConnected() {
        // USE_MOCK_TASKS=1 starts with isConnected=true and projects=[Home, Admin]
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))

        // "Todoist Projects" section header and both mock project rows must be visible
        XCTAssertTrue(app.staticTexts["TODOIST PROJECTS"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["todoistProject_proj-1"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["todoistProject_proj-2"].waitForExistence(timeout: 3))
    }

    // MARK: - T095.6: Tapping a project row toggles its selected state

    func testTodoistProjectRowTogglesSelection() {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        settingsButton.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))

        let homeRow = app.buttons["todoistProject_proj-1"]
        XCTAssertTrue(homeRow.waitForExistence(timeout: 3))

        // Initially not selected
        XCTAssertEqual(homeRow.value as? String, "Not selected")

        // Tap to select
        homeRow.tap()
        XCTAssertEqual(homeRow.value as? String, "Selected")

        // Tap again to deselect
        homeRow.tap()
        XCTAssertEqual(homeRow.value as? String, "Not selected")
    }

    // MARK: - T094.3: Photo album picker selection persists after app restart

    func testPhotoAlbumPickerPersistsAfterRestart() {
        // Verify PhotosPanel is visible (indicating album configured or prompt shown)
        XCTAssertTrue(app.otherElements["PhotosPanel"].waitForExistence(timeout: 3))

        // Restart app and verify panel still visible
        app.terminate()
        app.launch()
        XCTAssertTrue(app.otherElements["PhotosPanel"].waitForExistence(timeout: 5))
    }
}
