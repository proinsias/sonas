import Foundation
@testable import Sonas
import Testing

@Suite("Notification Extension Unit Tests")
struct NotificationSonasTests {
    @Test
    func `verify custom sonas notifications are correctly defined`() {
        #expect(Notification.Name.sonasRefreshRequested.rawValue == "sonasRefreshRequested")
        #expect(Notification.Name.sonasSettingsRequested.rawValue == "sonasSettingsRequested")
        #expect(Notification.Name.sonasNavigationRequested.rawValue == "sonasNavigationRequested")
    }
}
