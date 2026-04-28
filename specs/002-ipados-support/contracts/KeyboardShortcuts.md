# Contract: Keyboard Shortcut Registry

**File**: `Sonas/Shared/Commands/SonasCommands.swift` **Consumed by**: `SonasApp.WindowGroup` via
`.commands { SonasCommands() }`

---

## Purpose

`SonasCommands` registers all application-level keyboard shortcuts with the SwiftUI command system. It provides the
Command-key overlay shown when the user holds u2318 on an external keyboard (FR-004), with no additional implementation
required beyond declaring the commands.

---

## Interface

```swift
/// Registers all Sonas keyboard shortcuts with the SwiftUI .commands system.
/// Apply to WindowGroup: WindowGroup { ... }.commands { SonasCommands() }
struct SonasCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            // Settings shortcut (u21984+,) already handled via AppSection.keyboardShortcut on SidebarView
        }
        CommandMenu("Navigate") {
            // Section navigation shortcuts (u21984+1 through u21984+7)
            // Declared here so they appear in the Command overlay
        }
        CommandGroup(after: .pasteboard) {
            // u21984+R: Refresh all panels
        }
    }
}
```

---

## Registered Shortcuts

| Command               | Shortcut   | Appears in Overlay? |
| --------------------- | ---------- | ------------------- |
| Navigate to Dashboard | u21984 + 1 | Yes                 |
| Navigate to Location  | u21984 + 2 | Yes                 |
| Navigate to Calendar  | u21984 + 3 | Yes                 |
| Navigate to Weather   | u21984 + 4 | Yes                 |
| Navigate to Tasks     | u21984 + 5 | Yes                 |
| Navigate to Photos    | u21984 + 6 | Yes                 |
| Navigate to Jam       | u21984 + 7 | Yes                 |
| Settings              | u21984 + , | Yes (system slot)   |
| Refresh               | u21984 + R | Yes                 |

**Constraints**:

- Shortcuts MUST NOT conflict with system-reserved combinations (u21984+H, u21984+Tab, u21984+Space, etc.)
- Shortcut labels in the overlay MUST match the `AppSection.title` values for consistency
- `SonasCommands` MUST be stateless u2014 it dispatches via `NotificationCenter` or shared observable state, never
  holding view model references directly
- The Refresh shortcut (`u21984+R`) posts a `Notification.Name.sonasRefreshRequested` notification; `DashboardViewModel`
  and individual panel view models observe this notification

---

## PointerInteraction Extension

**File**: `Sonas/Shared/Extensions/View+PointerInteraction.swift`

```swift
extension View {
    /// Applies a system-standard highlight hover effect.
    /// No-op on non-pointer devices.
    func panelHoverEffect() -> some View

    /// Adds a location card context menu: Get Directions, Copy Location, Open in Maps.
    func locationCardContextMenu(
        memberName: String,
        coordinate: CLLocationCoordinate2D?
    ) -> some View

    /// Adds an event row context menu: Copy Event Title, Add Reminder.
    func eventRowContextMenu(event: CalendarEvent) -> some View
}
```

**Constraints**:

- `panelHoverEffect()` MUST use `.hoverEffect(.highlight)` u2014 NOT `.lift` (reserved for photo thumbnails)
- Context menu actions that open other apps (Maps, Reminders) MUST use `UIApplication.shared.open(_:)` with graceful
  no-op if the URL scheme is unavailable
- MUST be applied at the card level, not wrapping the entire panel
