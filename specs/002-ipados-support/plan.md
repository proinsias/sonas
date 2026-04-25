# Implementation Plan: Sonas u2014 Full iPadOS Support

**Branch**: `002-ipados-support` | **Date**: 2026-04-25 | **Spec**: specs/002-ipados-support/spec.md **Input**: Feature
specification from `specs/002-ipados-support/spec.md`

## Summary

Sonas already renders an adaptive 3-column grid on iPad (`DashboardView.swift`, `.regular/.regular` size class). This
plan elevates that foundation to a fully native iPadOS experience: a `NavigationSplitView` sidebar replacing the
`NavigationStack` at Regular horizontal size class, keyboard shortcuts via SwiftUI `.commands` and `.keyboardShortcut`,
pointer hover/context-menu support on all primary cards, multi-window enabled via `UIApplicationSupportsMultipleScenes`,
and Stage Manager compatibility via scene size restrictions. The iPhone layout and all existing tests remain unmodified.

## Technical Context

- **Language/Version**: Swift 5.10 / SwiftUI, iPadOS 17+ (minimum deployment target: iOS 17)
- **Tooling**: `mise` for tool version management (XcodeGen, SwiftLint); GitHub Actions for CI/CD
- **Primary Dependencies**: SwiftUI (NavigationSplitView, .commands, .hoverEffect, .contextMenu), UIKit
  (UIWindowScene.SizeRestrictions for Stage Manager)
- **Storage**: No new storage; existing SwiftData CacheService unchanged
- **Testing**: Swift Testing + XCTest; new UI test target for iPad layout; existing contract/unit/integration tests
  unchanged
- **Target Platform**: iPadOS 17+ (primary target for this feature); iPhone unaffected
- **Project Type**: Mobile app (SwiftUI multi-platform, single codebase)
- **Performance Goals**: Layout transitions at system-standard 60/120fps; sidebar show/hide u2264100ms; multi-window
  state restoration u2264500ms (cached data path, matching existing dashboard baseline)
- **Constraints**: No new dependencies permitted; no changes to existing service layer or data models; iPhone layout
  must be regression-free; sidebar navigation limited to Regular horizontal size class only
- **Scale/Scope**: 7 navigable sections (Location, Calendar, Weather, Tasks, Photos, Jam, Settings) + Dashboard
  overview; 6u20138 keyboard shortcuts

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Pre-Research Check

- [x] **I. Code Quality**: All new code is SwiftUI-native (NavigationSplitView, .commands, .hoverEffect). No new
      dependencies introduced. New types (`AppSection`, `SidebarView`, iPad navigation container) have single, clear
      responsibilities. All public surfaces typed explicitly.

- [x] **II. Test-First**: Acceptance tests identified for each user story (UI tests for iPad layout, sidebar navigation,
      keyboard shortcut registration, multi-window scene opening). Failure baseline can be established before coding:
      existing `DashboardUITests` runs on iPhone; new `iPadLayoutUITests` will fail until sidebar is implemented.

- [x] **III. UX Consistency**: `NavigationSplitView` is Apple's own HIG-mandated pattern; no one-off components.
      Existing `PanelView`, `ErrorStateView`, `LoadingStateView` reused. `.hoverEffect` and `.contextMenu` are design-
      system-level additions applied via shared view extensions in `View+PointerInteraction.swift`. All interactive
      elements remain keyboard-navigable and WCAG 2.1 AA compliant.

- [x] **IV. Performance**: No new polling or subscriptions introduced. `NavigationSplitView` column transitions are
      system-managed (no custom animation code). Sidebar state is `@State` / `@SceneStorage` u2014 no heap allocation
      growth. Memory profiling gate: verify no scene-level retain cycles when opening a second window.

### Post-Design Re-Check

- [x] **I. Code Quality**: `AppSection` enum centralises all navigation state; no string-based routing. `iPadShell`
      container view isolates all iPad-specific chrome from the shared `DashboardView`.

- [x] **II. Test-First**: Contract: sidebar navigation tests fail before `iPadShell` is built. UI tests for keyboard
      shortcut overlay fail before `.commands` modifier is added. Multi-window test fails before
      `UIApplicationSupportsMultipleScenes` is set.

- [x] **III. UX Consistency**: Sidebar icon/label pairs use only existing `Icons.swift` SF Symbol aliases. Context menu
      actions (Directions, Copy Location, Open in Maps) are consistent with system patterns. Hover effect style
      (`.highlight`) matches system standard across all interactive cards.

- [x] **IV. Performance**: `UIWindowScene.SizeRestrictions` sets minimum width to 320pt (Slide Over minimum) and maximum
      unbounded u2014 no custom resize handler required. `@SceneStorage("selectedSection")` persists sidebar selection
      without extra service calls.

## Project Structure

### Documentation (this feature)

```text
specs/002-ipados-support/
u251cu2500u2500 plan.md              # This file
u251cu2500u2500 research.md          # Phase 0 output
u251cu2500u2500 data-model.md        # Phase 1 output
u251cu2500u2500 quickstart.md        # Phase 1 output
u251cu2500u2500 contracts/
u2502   u251cu2500u2500 iPad-Navigation.md  # NavigationSplitView / AppSection contract
u2502   u2514u2500u2500 KeyboardShortcuts.md # .commands registry contract
u2514u2500u2500 tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (new and modified files)

```text
Sonas/
u251cu2500u2500 App/
u2502   u251cu2500u2500 SonasApp.swift                      # MODIFY: add .windowResizability, enable multi-window
u2502   u2514u2500u2500 AppSection.swift                    # NEW: enum of all navigable app sections
u251cu2500u2500 Platform/
u2502   u2514u2500u2500 iPad/
u2502       u251cu2500u2500 iPadShell.swift                 # NEW: NavigationSplitView root for Regular width
u2502       u2514u2500u2500 SidebarView.swift               # NEW: sidebar section list with keyboard nav
u251cu2500u2500 Features/
u2502   u2514u2500u2500 Dashboard/
u2502       u2514u2500u2500 DashboardView.swift             # MODIFY: inject iPadShell at root; no layout change
u251cu2500u2500 Shared/
u2502   u251cu2500u2500 Commands/
u2502   u2502   u2514u2500u2500 SonasCommands.swift             # NEW: SwiftUI .commands definitions
u2502   u2514u2500u2500 Extensions/
u2502       u2514u2500u2500 View+PointerInteraction.swift   # NEW: .hoverEffect + .contextMenu helpers
SonasTests/
u251cu2500u2500 Unit/
u2502   u2514u2500u2500 AppSectionTests.swift            # NEW: AppSection enum / section metadata
SonasUITests/
u2514u2500u2500 iPadLayoutUITests.swift            # NEW: iPad sidebar, keyboard, multi-window UI tests
```

**Info.plist change**: `UIApplicationSupportsMultipleScenes` u2192 `YES` (enables multi-window on iPadOS).
