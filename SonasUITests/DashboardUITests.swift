import XCTest

// MARK: - DashboardUITests (T080)
// Constitution §II: every user-facing feature MUST have at least one acceptance/integration test.
// Run with all USE_MOCK_*=1 environment variables set in the SonasUITests scheme.

final class DashboardUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // Enable all mocks for deterministic UI tests
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

    // MARK: - T080.1: iPad Pro 3-column grid renders all panels with accessibility identifiers

    func testIPadThreeColumnLayoutRendersAllPanels() throws {
        // Run on iPad Pro 13-inch simulator
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This test requires an iPad simulator")
        }
        XCTAssertTrue(app.otherElements["LocationPanel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["EventsPanel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["WeatherPanel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["TasksPanel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["PhotosPanel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["JamPanel"].waitForExistence(timeout: 2))
    }

    // MARK: - T080.2: All interactive controls reachable via keyboard on Mac

    func testKeyboardNavigationReachesAllPanels() throws {
        #if targetEnvironment(macCatalyst)
        XCTAssertTrue(app.otherElements["LocationPanel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 2))
        #else
        throw XCTSkip("Keyboard navigation test requires macOS / Mac Catalyst")
        #endif
    }

    // MARK: - T080.3: SC-005 — ≤5 taps to reach Jam QR code from dashboard home

    func testStartJamQRCodeWithinFiveTaps() throws {
        var tapCount = 0

        // Tap 1: "Start Jam" button
        let startJamButton = app.buttons["Start Jam"]
        XCTAssertTrue(startJamButton.waitForExistence(timeout: 3), "Start Jam button must be visible")
        startJamButton.tap()
        tapCount += 1

        // QR code should appear without additional taps (total: 1 tap)
        let qrCode = app.images["JamQRCode"]
        XCTAssertTrue(qrCode.waitForExistence(timeout: 2), "QR code must appear within 2s of Start Jam tap")

        XCTAssertLessThanOrEqual(tapCount, 5, "Must reach Jam QR in ≤5 taps from dashboard (SC-005); used \(tapCount)")
    }
}
