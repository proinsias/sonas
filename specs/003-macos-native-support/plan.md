# Implementation Plan: Sonas — macOS Native Support

**Branch**: `003-macos-native-support` | **Date**: 2026-04-28 | **Spec**: specs/003-macos-native-support/spec.md
**Input**: Feature specification from `specs/003-macos-native-support/spec.md`

## Summary

Sonas currently renders on macOS via Mac Catalyst (`SUPPORTS_MACCATALYST: YES`), which presents the iOS UI unchanged.
This plan replaces Catalyst with a dedicated native macOS target (`MacSonas`) that follows the same platform-layer
pattern already established by `WatchSonas` and `TVSonas`. The new target shares all of `Sonas/Features/` and
`Sonas/Shared/` unchanged and adds a thin `Sonas/Platform/macOS/` layer providing: a `MenuBarExtra` popover (always-on
family status), a `NavigationSplitView` main window, macOS menu bar commands, multi-window support, macOS Notification
Centre integration, and offline graceful degradation via the existing `CacheService`.

## Technical Context

**Language/Version**: Swift 6.0 / SwiftUI, macOS 15+  
**Primary Dependencies**: SwiftUI (MenuBarExtra, NavigationSplitView, WindowGroup, .commands), WeatherKit, EventKit,
PhotoKit, CoreLocation, CloudKit, GoogleSignIn-iOS 7.1.0 (macOS via AppAuth), UserNotifications (macOS notification
action buttons)  
**Storage**: Shared SwiftData `CacheService` (unchanged); `@AppStorage` / `@SceneStorage` for UI state  
**Testing**: Swift Testing + XCTest; new `MacSonasUITests` scheme; contract tests for `MacNotificationService`  
**Target Platform**: macOS 15+ (this feature); iOS 17+ (unaffected)  
**Project Type**: Native desktop macOS app sharing codebase with existing iOS/watchOS/tvOS targets  
**Performance Goals**: Menu bar popover ≤300ms (SC-002); new window ≤500ms (SC-005); offline section load ≤1s (SC-008);
all UI interactions ≤100ms (Constitution §IV)  
**Constraints**: No new external dependencies; Mac Catalyst removed from iOS target; `SpotifyiOS` excluded from macOS
target; all existing iPhone/iPad behaviour unchanged  
**Scale/Scope**: Family use (≤10 users); 7 navigable sections + Dashboard overview + menu bar extra; 6 keyboard
shortcuts + full macOS menu bar

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Pre-Research Check

- [x] **I. Code Quality**: New macOS platform layer (`MacSonasApp`, `MacShell`, `MacSidebarView`,
      `MacMenuBarPopoverView`, `MacSonasCommands`, `MacNotificationService`) — each has a single, clear responsibility.
      No new external dependencies. All public surfaces explicitly typed. Dead code (Catalyst build path) removed.

- [x] **II. Test-First**: Acceptance tests identified for all 5 user stories (macOS UI tests: sidebar navigation, menu
      bar popover open/close, keyboard shortcut fire, notification action deep-link, multi-window independence).
      Contract tests for `MacNotificationService` cover all 5 notification scenarios. Test failure baseline established
      before any implementation code is written.

- [x] **III. UX Consistency**: `NavigationSplitView` + sidebar is the Apple HIG-recommended macOS navigation pattern.
      `MenuBarExtra(.window)` is the SwiftUI standard API. `SonasCommands` (existing) extended with macOS-only
      `CommandMenu("File")` entries rather than a parallel one-off implementation. All panel views (`PanelView`,
      `LoadingStateView`, `ErrorStateView`) reused unchanged.

- [x] **IV. Performance**: All performance targets defined in spec and SC. Menu bar popover reads only `CacheService`
      (synchronous SwiftData fetch — no network call). `MenuBarState` is a lightweight `@Observable` with no polling
      loop; it refreshes lazily when the popover opens and whenever the main window refreshes. Memory profiling gate:
      verify no retain cycles on multi-window open/close using Instruments (Allocations template) before shipping.

### Post-Design Re-Check

- [x] **I. Code Quality**: `MacNotificationService` protocol isolates `UNUserNotificationCenter` behind a testable
      interface. `MacWindowState` centralises per-window scene storage to a single `@SceneStorage` key. No string-based
      routing; all navigation uses the existing `AppSection` enum.

- [x] **II. Test-First**: Contract tests for `MacNotificationService` (5 tests in `contracts/MacNotificationService.md`)
      all fail before implementation. UI tests for menu bar popover and keyboard shortcuts fail before `MacSonasApp` is
      built. Multi-window test fails before `WindowGroup` is wired.

- [x] **III. UX Consistency**: `MacSidebarView` mirrors `SidebarView` (iPad) to ensure visual consistency while allowing
      macOS-specific toolbar placement. The `MenuBarExtraStyle.window` popover uses the same `PanelView` design tokens
      as the main window (colours, typography, spacing).

- [x] **IV. Performance**: `MenuBarState.refresh()` is a single `CacheService.loadLocations()` + `loadEvents()` +
      `loadWeather()` call sequence (same as iPad dashboard bootstrap). No new polling. Window open latency relies on
      SwiftUI's `WindowGroup` lazy initialisation — ViewModel creation is deferred to `MacShell.onAppear`.

## Project Structure

### Documentation (this feature)

```text
specs/003-macos-native-support/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   ├── MacShell.md
│   ├── MacMenuBarPopoverView.md
│   └── MacNotificationService.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
MacSonas/                            ← NEW (parallel to WatchSonas/, TVSonas/)
└── Assets.xcassets                  ← macOS app icon + accent colour

Sonas/Platform/macOS/                ← NEW — macOS-specific platform layer
├── MacSonasApp.swift                ← @main; WindowGroup + MenuBarExtra + .commands
├── MacShell.swift                   ← NavigationSplitView root view; @SceneStorage per window
├── MacSidebarView.swift             ← Sidebar list (AppSection navigation)
├── MacMenuBarPopoverView.swift      ← Compact family status popover
├── MacSonasCommands.swift           ← macOS menu bar: File > New Window, View > sections, etc.
└── MacNotificationService.swift     ← UNUserNotificationCenter categories + delegate

project.yml                          ← MODIFIED: add MacSonas target; SUPPORTS_MACCATALYST: NO
Sonas/Shared/Extensions/
└── Notification+Sonas.swift         ← MODIFIED: add .sonasWindowOpenRequested name

SonasTests/MacNotificationServiceTests.swift   ← NEW (or under SonasTests/)
MacSonasUITests/                     ← NEW test scheme (macOS UI tests)
├── MacDashboardUITests.swift
├── MacMenuBarUITests.swift
├── MacKeyboardShortcutUITests.swift
├── MacNotificationUITests.swift
└── MacMultiWindowUITests.swift
```

**Structure Decision**: macOS-specific code lives entirely in `Sonas/Platform/macOS/`, following the established
`Platform/iPad/`, `Platform/TV/`, `Platform/Watch/` pattern. The macOS XcodeGen target sources `Sonas/Platform/macOS/` +
`Sonas/Features/` + `Sonas/Shared/` — identical in shape to the TV and Watch targets. `Sonas/App/SonasApp.swift` and
`Sonas/Platform/iPad/IPadSceneDelegate.swift` are excluded by source path (neither directory is listed in the macOS
target's sources).

### XcodeGen Target Definition (project.yml addition)

```yaml
MacSonas:
 type: application
 platform: macOS
 deploymentTarget: '15.0'
 sources:
  - path: Sonas/Platform/macOS
  - path: Sonas/Features
    excludes:
     - '**/*.md'
  - path: Sonas/Shared
    excludes:
     - 'Mocks/**'
     - '**/*.md'
  - path: MacSonas/Assets.xcassets
 info:
  path: MacSonas/Info.plist
  properties:
   CFBundleDisplayName: Sonas
   CFBundleShortVersionString: '$(MARKETING_VERSION)'
   CFBundleVersion: '$(CURRENT_PROJECT_VERSION)'
   NSLocationWhenInUseUsageDescription: 'Sonas shows your family members on a map.'
   NSPhotoLibraryUsageDescription: 'Sonas reads your iCloud Shared Album to display family photos.'
   GIDClientID: 'placeholder.apps.googleusercontent.com'
   LSApplicationCategoryType: 'public.app-category.lifestyle'
   LSUIElement: false
 settings:
  base:
   PRODUCT_BUNDLE_IDENTIFIER: com.ci.sonas.mac
   ENABLE_HARDENED_RUNTIME: YES
 dependencies:
  - package: GoogleSignIn
 schemes:
  MacSonas:
   build:
    targets:
     MacSonas: all
   run:
    config: Debug
   test:
    config: Debug
    targets:
     - MacSonasUITests
```

### iOS Target Catalyst Removal (project.yml modification)

```yaml
# In targets.Sonas.settings.base — add:
SUPPORTS_MACCATALYST: NO
# Remove (or change to NO):
# SUPPORTS_MACCATALYST: YES
```

## Implementation Phases

### Phase 1: Project Scaffold (no UI yet)

**Goal**: Build compiles green for `MacSonas` target; all tests run (and fail) for new test files.

1. Create `MacSonas/Assets.xcassets` with placeholder app icon
2. Create `MacSonas/Info.plist` (or inline in `project.yml`)
3. Create stub `Sonas/Platform/macOS/` files (each with `// TODO` bodies)
4. Update `project.yml`: add `MacSonas` target, set `SUPPORTS_MACCATALYST: NO` on `Sonas`
5. Run `xcodegen generate`
6. Confirm `MacSonas` scheme builds without errors
7. Write all `MacNotificationServiceTests` (5 contract tests — must fail at this point)
8. Write skeleton `MacSonasUITests` (one test per user story — must fail)

### Phase 2: Core Window (US1 — P1)

**Goal**: Main window opens with sidebar and all sections navigable.

1. Implement `MacSonasApp.swift`: `WindowGroup(id: "main")` + `.commands { MacSonasCommands() }`
2. Implement `MacShell.swift`: `NavigationSplitView` with `@SceneStorage`, ViewModel creation, `.onReceive` for
   `.sonasNavigationRequested`
3. Implement `MacSidebarView.swift`: `List(selection:)` with `AppSection` items, `.listStyle(.sidebar)`, Settings button
   at bottom
4. Wire toolbar: Refresh button (`sonasRefreshRequested`), window title "Sonas"
5. Acceptance test: US1 scenarios 1–4 pass in `MacDashboardUITests`

### Phase 3: Menu Bar Extra (US2 — P2)

**Goal**: Menu bar icon visible at all times; popover shows family status.

1. Add `MenuBarExtra("Sonas", systemImage: "house.fill")` to `MacSonasApp.body` with `.menuBarExtraStyle(.window)`
2. Implement `MenuBarState` `@Observable` class; populate from `CacheService` on popover open
3. Implement `MacMenuBarPopoverView.swift`: location names, next event, weather, offline indicator, "Open Sonas" button
4. Wire "Open Sonas" to `openWindow(id: "main")`
5. Acceptance test: US2 scenarios 1–4 pass in `MacMenuBarUITests`; SC-002 (≤300ms) verified

### Phase 4: macOS Menus & Shortcuts (US3 — P3)

**Goal**: Full macOS menu bar and all keyboard shortcuts work.

1. Implement `MacSonasCommands.swift`:
   - `CommandGroup(replacing: .newItem)`: "New Window" → `openWindow(id: "main")`
   - Extend existing `CommandMenu("Navigate")` with macOS-appropriate grouping
   - `CommandGroup(after: .windowArrangement)`: standard Window menu entries
2. Verify Cmd+1–7 section switching, Cmd+R refresh, Cmd+W close, Cmd+, settings
3. Acceptance test: US3 scenarios 1–4 pass in `MacKeyboardShortcutUITests`; SC-004 verified

### Phase 5: Notifications (US4 — P4)

**Goal**: Location arrival and calendar event notifications with action buttons.

1. Implement `MacNotificationService.swift`: `register()`, two categories, `UNUserNotificationCenterDelegate`
2. Wire `MacSonasApp.init` to call `Task { await MacNotificationService.shared.register() }`
3. Extend `LocationViewModel` with `#if os(macOS)` block to call `scheduleLocationArrival` on member arrival
4. Extend `EventsViewModel` with `#if os(macOS)` block to call `scheduleCalendarReminder` on event load
5. Acceptance test: US4 scenarios 1–4 pass in `MacNotificationUITests`; SC-003 verified
6. All 5 `MacNotificationServiceTests` now pass

### Phase 6: Multi-Window (US5 — P5)

**Goal**: Multiple independent windows supported.

1. Verify `WindowGroup` multi-window works out of the box (open second window via Cmd+N / File > New Window)
2. Confirm `@SceneStorage("mac.selectedSection")` is per-window (each window has independent selection)
3. Add `defaultSize(width: 1200, height: 800)` and `windowResizability(.contentSize)` modifiers
4. Verify Spaces and Stage Manager: drag windows between Spaces, verify independence
5. Acceptance test: US5 scenarios 1–4 pass in `MacMultiWindowUITests`; SC-005 (≤500ms) verified

### Phase 7: Offline Graceful Degradation (FR-017 / SC-008)

**Goal**: All sections show cached data with "last updated" indicator when offline.

1. Add `isOffline: Bool` to `MenuBarState`; set via `NetworkMonitor` or reachability check
2. Add `lastRefreshed: Date?` to all section ViewModels (already tracked in some)
3. In `MacShell` detail views: wrap in offline banner component showing "Last updated [time]" when offline
4. In `MacMenuBarPopoverView`: show "Last updated [time]" footer when `isOffline`
5. Acceptance test: SC-008 (≤1s offline load) verified with network disabled in simulator

### Phase 8: Polish & App Store Submission Prep

1. Replace placeholder app icon with final asset (all macOS sizes)
2. Verify SC-006: clean Xcode build log with zero Catalyst warnings
3. Memory profile: Instruments Allocations on open/close 5 windows; verify no leaks
4. Set up `MacSonas` scheme in CI (GitHub Actions)
5. App Store Connect: new macOS app submission (separate from iOS)
