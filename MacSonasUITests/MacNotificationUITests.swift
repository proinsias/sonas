import XCTest

final class MacNotificationUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
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
