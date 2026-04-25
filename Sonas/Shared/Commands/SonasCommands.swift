import SwiftUI

/// Registers all Sonas keyboard shortcuts with the SwiftUI command system.
/// This provides the Command-key overlay on iPadOS (FR-004).
struct SonasCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
                NotificationCenter.default.post(name: .sonasSettingsRequested, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandMenu("Navigate") {
            ForEach(AppSection.allCases.filter { $0 != .settings }) { section in
                Button(section.title) {
                    NotificationCenter.default.post(name: .sonasNavigationRequested, object: section)
                }
                .keyboardShortcut(section.keyboardShortcut)
            }
        }

        CommandGroup(after: .pasteboard) {
            Button("Refresh All") {
                NotificationCenter.default.post(name: .sonasRefreshRequested, object: nil)
            }
            .keyboardShortcut("R", modifiers: .command)
        }
    }
}
