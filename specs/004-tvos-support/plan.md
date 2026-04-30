# Implementation Plan: Sonas — tvOS Full Support

**Branch**: `004-tvos-support` | **Date**: 2026-04-28 | **Spec**: specs/004-tvos-support/spec.md  
**Input**: Feature specification from `specs/004-tvos-support/spec.md`

## Summary

The existing tvOS target (`TVSonas`) is a three-panel stub using hardcoded fixture data. This plan upgrades it to a
fully functional tvOS app: all six family panels (Location, Weather, Calendar, Tasks, Photos, Spotify Jam) powered by
live services, proper tvOS focus-engine navigation with panel expand/collapse, an auto-advancing photo slideshow, and a
new `TVTopShelfExtension` target that surfaces a family photo and the next event on the Apple TV home screen.

Two platform constraints drive the only new service implementations:

- **EventKit unavailable on tvOS** → new `TVCalendarService` wraps only the existing `GoogleCalendarClient` (Google
  Calendar REST v3); EventKit import guarded with `#if !os(tvOS)` in `CalendarService.swift`.
- **SpotifyiOS SDK is iOS-only** → new `TVSpotifyReadService` polls the Spotify Web API for the currently playing track
  (display-only; no playback control).

Google Calendar authentication on tvOS uses the OAuth 2.0 Device Authorization Grant flow (`TVDeviceAuthFlow` +
`TVDeviceAuthView`). All other services (WeatherKit, PhotoKit, CloudKit location) are available on tvOS and are reused
without modification.

## Technical Context

**Language/Version**: Swift 6.0 / SwiftUI, tvOS 18+  
**Primary Dependencies**: SwiftUI, WeatherKit (tvOS 16+), PhotoKit (tvOS 10+), CloudKit, CoreLocation (read-only on
tvOS), GoogleSignIn-iOS 7.1.0 (token storage only; device-flow replaces browser-based OAuth); Spotify Web API (REST; no
SDK dependency)  
**Storage**: Shared `CacheService` (SwiftData); `@AppStorage` for device-flow credential  
**Testing**: XCTest + Swift Testing; new `TVSonasUITests` XCGen target; contract tests for `TVCalendarService` and
`TVSpotifyReadService` in `SonasTests`  
**Target Platform**: tvOS 18+ (this feature only); iOS, macOS, watchOS targets unaffected  
**Project Type**: Native tvOS app sharing `Sonas/Features/` and `Sonas/Shared/` with all other targets  
**Performance Goals**: All panels display live data within 30 s of launch (SC-001); panel navigate + expand/collapse
under 5 s (SC-002); data never > 5 min stale during active session (SC-003); stable and responsive after 8 h continuous
display (SC-004); all UI interactions ≤ 100 ms (Constitution §IV)  
**Constraints**: No new third-party packages; SpotifyiOS SDK excluded from TVSonas target; EventKit excluded from tvOS
build; location publishing disabled on tvOS (read-only consumer); Google OAuth uses device-flow only (no browser
redirect); Tasks panel display-only (no Todoist write operations on TV)  
**Scale/Scope**: Family use (≤ 10 members); 6 panels + detail views + Top Shelf extension; 1 new XCGen target

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Pre-Research Check

- [x] **I. Code Quality**: Each new file has a single, clear responsibility: `TVShell` (layout coordinator),
      `TVCalendarService` (Google REST calendar), `TVSpotifyReadService` (Spotify REST read), `TVDeviceAuthFlow` (OAuth
      device grant state machine), `TVDeviceAuthView` (code display UI), `TVSlideshowPanelView` (auto-advancing photo),
      `TVTopShelfExtension` (home screen shelf). No new external packages. All public surfaces explicitly typed.

- [x] **II. Test-First**: Acceptance tests identified for all 4 user stories (`TVSonasUITests`: live data on dashboard,
      remote focus navigation, panel detail expand/collapse, slideshow advance, Top Shelf photo display). Contract tests
      for `TVCalendarService` (4 scenarios) and `TVSpotifyReadService` (3 scenarios) are written to fail before
      implementation begins.

- [x] **III. UX Consistency**: Existing `PanelView`, `ErrorStateView`, `LoadingStateView`, and all design tokens
      (colors, typography, icons) are reused unchanged. tvOS-specific interactions (`.focusable()`,
      `.buttonStyle(.card)`, `TVMonoscapeFont`) are confined to the Platform/TV layer. No new one-off components that
      duplicate existing shared components.

- [x] **IV. Performance**: Dashboard initial render uses `CacheService` (same path as iOS). Spotify REST polling at 30 s
      intervals (well within 5-min refresh budget). Memory profiling gate: 8 h continuous display run with Instruments
      Allocations template before the feature is considered done (SC-004).

### Post-Design Re-Check

- [x] **I. Code Quality**: `TVCalendarService` reuses `GoogleCalendarClient` (no duplication). `TVSpotifyReadService` is
      a thin REST wrapper with no business logic beyond response decoding. Platform guard `#if !os(tvOS)` in
      `CalendarService.swift` eliminates EventKit import cleanly without forking the service tree.

- [x] **II. Test-First**: Contract test scenarios (see `contracts/`) map 1:1 to service protocol methods; all are
      written before implementation code exists.

- [x] **III. UX Consistency**: All panels retain the `PanelView` chrome (title bar, stale badge, error state). Focus
      highlight uses tvOS system card style, which is the Apple HIG standard for TV apps — no custom focus rendering.

- [x] **IV. Performance**: `TVSpotifyReadService` polls at 30 s; `TVCalendarService` refreshes every 5 min (matching
      iOS). WeatherKit and CloudKit location use the unchanged service implementations. No retain-cycle risk identified
      in the task/continuation model used by `AsyncStream`.

## Project Structure

### Documentation (this feature)

```text
specs/004-tvos-support/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   ├── TVCalendarService.md
│   └── TVSpotifyReadService.md
└── tasks.md             ← Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
Sonas/Platform/TV/
├── TVSonasApp.swift                  (existing — no changes)
├── TVDashboardView.swift             (existing → simplified to a thin coordinator)
├── TVShell.swift                     (new — top-level NavigationStack + grid layout)
├── TVPanelDetailView.swift           (new — routes each panel to its full-screen detail)
├── TVSlideshowPanelView.swift        (new — TimelineView auto-advancing photo slideshow)
├── TVCalendarService.swift           (new — Google REST-only calendar for tvOS)
├── TVSpotifyReadService.swift        (new — Spotify Web API polling, read-only)
├── TVDeviceAuthFlow.swift            (new — OAuth 2.0 Device Authorization Grant)
└── TVDeviceAuthView.swift            (new — on-screen code + URL display)

TVTopShelfExtension/
├── TVSonasTopShelfExtension.swift    (new target entry point)
└── TopShelfContentProvider.swift     (new — TVContentProvider implementation)

SonasTests/
├── TVCalendarServiceTests.swift      (new — contract tests)
└── TVSpotifyReadServiceTests.swift   (new — contract tests)

TVSonasUITests/                       (new target)
├── TVDashboardUITests.swift          (new)
├── TVNavigationUITests.swift         (new)
└── TVSlideshowUITests.swift          (new)
```

**Modified files**:

```text
Sonas/Features/Calendar/CalendarService.swift   — guard EventKit with #if !os(tvOS)
Sonas/Features/Location/LocationService.swift   — guard startPublishing() with #if !os(tvOS)
Sonas/Features/SpotifyJam/JamViewModel.swift    — extend platform guard to cover tvOS
Sonas/Shared/Mocks/CalendarServiceMock.swift    — already protocol-based; no change required
project.yml.template                            — add TVTopShelfExtension target; add WeatherKit
                                                  entitlement + TVSonasUITests to TVSonas scheme
project.yml                                     — same as template (local copy)
```

**Structure Decision**: Single-project, multi-target layout matching the existing WatchSonas/MacSonas pattern. All
shared business logic stays in `Sonas/Features/` and `Sonas/Shared/`; platform-specific UI and services live in
`Sonas/Platform/TV/`.

## Performance Baselines

_Recorded during Phase 7 (T037) — tvOS Simulator, Apple TV 4K (3rd generation), all mocks enabled._

| Metric                             | Baseline | SC-004 Gate                   |
| ---------------------------------- | -------- | ----------------------------- |
| Heap at launch (after 30 s)        | ~45 MB   | < 150 MB                      |
| Heap after 30 min continuous       | ~47 MB   | < 200 MB (< 5 MB growth/hour) |
| Peak heap                          | ~55 MB   | < 250 MB                      |
| Dashboard first frame (cache cold) | < 500 ms | ≤ 500 ms                      |
| Panel navigate + expand            | < 1 s    | ≤ 5 s (SC-002)                |
| Spotify REST poll interval         | 30 s     | —                             |
| Weather refresh interval           | 15 min   | ≤ 5 min (SC-003)              |

> **SC-004 gate**: A full 8-hour continuous-display run with Instruments Allocations + Leaks must confirm no monotonic
> heap growth before the feature is marked ready to ship to production. Run with
> `xcrun simctl spawn <device-udid> <TVSonas-bundle>` or from a connected Apple TV 4K. Record the final heap figure here
> once the 8-hour run is complete.
>
> **8-hour run status**: Pending — run before merging to main.

## Complexity Tracking

> No constitution violations. Table omitted.
