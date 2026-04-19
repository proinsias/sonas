import SwiftUI

// MARK: - TVSonasApp

// Entry point for the Apple TV target (TVSonas).
// Mirrors the pattern of SonasApp.swift for the iOS target.

@main
struct TVSonasApp: App {
    var body: some Scene {
        WindowGroup {
            TVDashboardView()
        }
    }
}
