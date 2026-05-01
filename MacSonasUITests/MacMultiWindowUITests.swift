import XCTest

@MainActor
final class MacMultiWindowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() async throws {
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

    func test_multiWindow_independence() {
        // First window is open
        let window1 = app.windows["main"]
        XCTAssertTrue(window1.exists)

        // Open second window via File > New Window (Cmd+N)
        app.typeKey("n", modifierFlags: .command)

        // Now there should be 2 windows
        XCTAssertEqual(app.windows.count, 2)
    }
}
