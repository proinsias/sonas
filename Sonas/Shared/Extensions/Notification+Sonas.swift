import Foundation

extension Notification.Name {
    /// Posted when the user requests a manual refresh of all dashboard panels (⌘+R).
    static let sonasRefreshRequested = Notification.Name("sonasRefreshRequested")

    /// Posted when the user requests to open app settings (⌘+,).
    static let sonasSettingsRequested = Notification.Name("sonasSettingsRequested")

    /// Posted when the user requests navigation to a specific section via keyboard shortcut.
    /// The `object` of the notification is the target `AppSection`.
    static let sonasNavigationRequested = Notification.Name("sonasNavigationRequested")

    /// Posted by MacNotificationService to trigger window open + navigation on macOS.
    static let sonasWindowOpenRequested = Notification.Name("sonasWindowOpenRequested")
}
