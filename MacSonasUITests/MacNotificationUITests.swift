import XCTest

@MainActor
final class MacNotificationUITests: XCTestCase {
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

    func test_notification_permission_requested() {
        // First run should request notification permission
        // Difficult to verify in UITest without resetting simulator/permissions
    }

    func test_notification_categories_registered() {
        // Verify via system settings or just check app state if exposed
    }
}
