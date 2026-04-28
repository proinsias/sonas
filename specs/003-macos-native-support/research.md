# Research: Sonas — macOS Native Support

**Branch**: `003-macos-native-support` | **Date**: 2026-04-28

## Decision Log

### D-001: MenuBarExtra + WindowGroup — Combined Pattern

**Decision**: Use SwiftUI `MenuBarExtra(.window style)` + `WindowGroup` together in one `App` struct.

**Rationale**: `MenuBarExtra` with `.window` style renders a rich SwiftUI popover (SC-002: ≤300ms). Combining it with
`WindowGroup` gives the app a Dock icon at all times (FR-016) and a resizable main window (FR-004, FR-005). The
`MenuBarExtra`-only pattern (no `WindowGroup`) terminates the app when the user removes the icon from the menu bar —
unsuitable for a family dashboard. Combined pattern is fully supported on macOS 13+.

**Alternatives considered**: AppKit `NSStatusItem` wrapper — rejected; more code, no benefit over SwiftUI `MenuBarExtra`
on macOS 15.

---

### D-002: Window State Restoration — Rely on SwiftUI Built-in

**Decision**: Use the standard SwiftUI `WindowGroup` automatic state restoration (macOS built-in) rather than custom
`NSWindowRestoration` code.

**Rationale**: On macOS, `WindowGroup` automatically saves and restores window positions and sizes via the system's
window restoration mechanism. First launch has no saved state → system opens a default window (satisfying FR-009
first-launch rule). Subsequent launches restore the window count (zero open windows = silent launch to menu bar).
`@SceneStorage` handles per-window section selection.

**Alternatives considered**: Manual `NSWindowRestoration` — rejected; unnecessary complexity when the SwiftUI default
behaviour meets all requirements.

---

### D-003: Source Layout — Parallel to TV/Watch Pattern

**Decision**: macOS target sources = `Sonas/Platform/macOS/` + `Sonas/Features/` + `Sonas/Shared/`. The iOS app entry
point (`Sonas/App/SonasApp.swift`) and iPad UIKit scene delegate (`IPadSceneDelegate.swift`) are excluded by not
including their source paths.

**Rationale**: Mirrors the clean pattern already established for `WatchSonas` and `TVSonas`. No `#if os(macOS)` guards
needed in existing files because the incompatible files are simply absent from the macOS target's source paths.

**Alternatives considered**: Include all of `Sonas/` with platform guards (`#if os(iOS)`) — rejected; scatters macOS
awareness through iOS code and violates single-responsibility principle.

---

### D-004: Mac Catalyst Removal

**Decision**: Set `SUPPORTS_MACCATALYST: NO` in the iOS target's `settings.base` in `project.yml` and remove the current
`SUPPORTS_MACCATALYST: YES` line.

**Rationale**: FR-001 (clarified) mandates a clean replacement — no Catalyst build at any point. Existing App Store
users on Mac receive the native app on update via the macOS bundle ID change (a new separate submission is needed since
Catalyst and native macOS use different bundle paths; App Store Connect supports this migration).

**Alternatives considered**: Keep Catalyst in parallel — rejected per clarification Q1.

---

### D-005: SpotifyiOS SDK — Already Guarded

**Decision**: No changes needed to `SpotifyJamService.swift`. The SDK import is already inside
`#if canImport(SpotifyiOS)`, so the file compiles on macOS returning "not available" paths. The macOS target simply
omits `SpotifyiOS` from its dependencies (no `platformFilter` entry).

**Rationale**: Existing iOS guard pattern already handles the macOS case gracefully. The Music panel shows read-only
now-playing data via `JamSession` model from `CacheService`, which has no iOS-only dependencies.

---

### D-006: Notification Architecture — MacNotificationService

**Decision**: New `MacNotificationService.swift` in `Sonas/Platform/macOS/` registers two `UNNotificationCategory`
instances with action buttons and implements `UNUserNotificationCenterDelegate` to post internal `NotificationCenter`
messages on action tap.

**Rationale**: `UserNotifications` is available on macOS 10.14+ and supports `UNNotificationAction` for action buttons.
The app must register categories at startup. On action tap, the delegate posts `.sonasNavigationRequested` (existing
notification name) so `MacShell` reacts identically to keyboard shortcuts.

**Categories defined**:

- `com.sonas.location.arrival`: action `show-map` → posts `.sonasNavigationRequested` with `.location`
- `com.sonas.calendar.upcoming`: action `open-calendar` → posts `.sonasNavigationRequested` with `.calendar`

---

### D-007: GoogleSignIn on macOS

**Decision**: GoogleSignIn-iOS 7.1.0 supports macOS via `AppAuth` + `ASWebAuthenticationSession`. Include the
`GoogleSignIn` package in the macOS target with no `platformFilter` (same as iOS). No additional SDK or configuration
required beyond the existing `GIDClientID` key.

**Rationale**: The package's SPM manifest includes macOS as a supported platform. `GIDSignIn.sharedInstance.handle(url)`
is called on the `onOpenURL` modifier which works identically on macOS.

---

### D-008: UIKit Dependencies — None in Shared/Features

**Decision**: All feature views and shared code compile on macOS without modification. Only two files use UIKit:
`SonasApp.swift` (iOS `@main`) and `IPadSceneDelegate.swift` (iOS UIKit scene delegate). Both are excluded from the
macOS target by source path design.

**Evidence**: `grep` of `import UIKit` and `UIViewRepresentable` across `Sonas/Features/` and `Sonas/Shared/` found zero
matches (except `PhotoServiceMock.swift` in `Mocks/`, which is also excluded). `BackgroundTasks` import is only in
`SonasApp.swift`.
