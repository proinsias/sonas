import SwiftUI

struct MacSonasCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                NotificationCenter.default.post(name: .sonasSettingsRequested, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandGroup(after: .pasteboard) {
            Button("Refresh All") {
                NotificationCenter.default.post(name: .sonasRefreshRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        CommandMenu("View") {
            ForEach(AppSection.allCases.filter { $0 != .settings }) { section in
                Button(section.title) {
                    NotificationCenter.default.post(name: .sonasNavigationRequested, object: section)
                }
                .keyboardShortcut(section.keyboardShortcut)
            }
        }
    }
}
