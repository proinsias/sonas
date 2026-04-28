import XCTest

final class MacMultiWindowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
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
