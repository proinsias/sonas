import SwiftUI

// MARK: - WatchSonasApp

// Entry point for the watchOS target (WatchSonas).

@main
struct WatchSonasApp: App {
    var body: some Scene {
        WindowGroup {
            WatchDashboardView(members: [], nextEvent: nil)
        }
    }
}
