import SwiftUI
import UserNotifications

@main
struct MacSonasApp: App {
    @State private var menuBarState = MenuBarState()
    @Environment(\.openWindow) private var openWindow

    init() {
        Task {
            await MacNotificationService.shared.register()
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            MacShell()
                .environment(menuBarState)
                .onReceive(NotificationCenter.default.publisher(for: .sonasWindowOpenRequested)) { _ in
                    openWindow(id: "main")
                }
        }
        .defaultSize(width: 1200, height: 800)
        .windowResizability(.contentSize)
        .commands {
            MacSonasCommands()
        }

        MenuBarExtra("Sonas", systemImage: "house.fill") {
            MacMenuBarPopoverView()
                .environment(menuBarState)
        }
        .menuBarExtraStyle(.window)
    }
}
