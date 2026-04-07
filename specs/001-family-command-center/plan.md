# Implementation Plan: Sonas — iOS Family Command Center

**Branch**: `001-family-command-center` | **Date**: 2026-04-07 | **Spec**: specs/001-family-command-center/spec.md
**Input**: Feature specification from `/specs/001-family-command-center/spec.md`

## Summary

Sonas is a SwiftUI-first iOS 18+ app that displays a unified Family Command Center dashboard.
All data is fetched on-device with no custom backend. Family member locations are shared via a
CloudKit private container (Apple infrastructure). Weather is provided by WeatherKit + a secondary
AQI API. Calendar events are aggregated from EventKit (iCloud) and the Google Calendar REST API.
Photos come from PhotoKit (iCloud Shared Album). Tasks are fetched from the Todoist REST API.
Spotify Jam sessions are initiated via the Spotify iOS SDK and displayed as a CoreImage QR code.
A single SwiftUI codebase with adaptive layouts targets iOS, iPadOS, macOS, watchOS, and tvOS.

## Technical Context

**Language/Version**: Swift 5.10 / SwiftUI, iOS 18+ (minimum deployment target: iOS 17 for SwiftData)
**Primary Dependencies**: WeatherKit, EventKit, PhotoKit, CoreLocation, CloudKit, GoogleSignIn-iOS SDK, Google Calendar REST API v3, Todoist REST API v2, Spotify iOS SDK (SpotifyiOS), CoreImage (QR), SwiftData, BackgroundTasks, UserNotifications
**Storage**: SwiftData (on-device cache only); CloudKit private container for location relay — no custom server-side database
**Testing**: Swift Testing framework (iOS 17+) + XCTest; contract tests via URLProtocol stubbing for REST APIs; UI tests via XCUITest
**Target Platform**: iOS 18+ (primary); iPadOS 18+ / macOS 15+ (Catalyst or native SwiftUI) / watchOS 11+ / tvOS 18+ (adaptive layout extensions)
**Project Type**: Mobile app (SwiftUI multi-platform, single codebase)
**Performance Goals**: Dashboard visible with cached data in ≤500ms; full live data in ≤2s; UI interactions ≤100ms; photo gallery at 60fps; background Todoist refresh best-effort every 5 min (foreground) / 15 min (background via BGAppRefreshTask)
**Constraints**: No custom backend; no server-side personal data storage; ≤150MB peak memory; offline degraded mode mandatory; 9+ App Store age rating; no analytics/ad SDKs; AirQuality data from secondary API (WeatherKit does not provide AQI)
**Scale/Scope**: 2–15 family members per household; single shared CloudKit container; single iCloud Shared Album; up to 3 Todoist family projects; 7-day weather window; 48-hour calendar window

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Check

- [x] **I. Code Quality**: Swift's type system enforces explicit typing on all public surfaces.
  SwiftUI composability maps to single-responsibility views. SwiftLint configured as a CI gate.
  All dependencies (WeatherKit, EventKit, PhotoKit, GoogleSignIn, Todoist SDK, SpotifyiOS) have
  active maintenance and clear licenses. No dead code permitted in PRs.

- [x] **II. Test-First**: Swift Testing + XCTest covers all layers. Contract tests via
  URLProtocol stubbing are identified for Todoist REST v2, Google Calendar REST v3, and
  Spotify Web API. CloudKit integration tests via `CKContainer` test environment. Coverage
  gate ≥80% on `Sonas/` source target.

- [x] **III. UX Consistency**: Shared SwiftUI component library defined (PanelView, ErrorStateView,
  LoadingStateView, RefreshablePanel). Dynamic Type + `.accessibilityLabel` + `.accessibilityHint`
  required on all interactive controls. WCAG 2.1 AA colour contrast enforced via design-system
  palette. Screenshots required in all UI-touching PRs.

- [x] **IV. Performance**: Async/await throughout all service layers; cached SwiftData records
  rendered on first frame (≤500ms); live data fills in asynchronously. Memory profiling required
  for CloudKit subscription, CoreLocation manager, and photo cache. 60fps enforced for gallery
  carousel via `TimelineView`.

### Post-Design Re-Check

- [x] **I. Code Quality**: Feature-module structure (one Swift package per integration service)
  enforces single-responsibility. All services hidden behind Swift protocols — no concrete type
  leaks into views.

- [x] **II. Test-First**: Contract test targets defined for all 4 external REST APIs. CloudKit
  test container identified. Photo and location services use injectable protocols enabling
  mock injection without network.

- [x] **III. UX Consistency**: `DashboardLayout` adapts to `horizontalSizeClass` and
  `verticalSizeClass` without per-platform `#if os()` in view code. All error messages routed
  through `PanelErrorState` to guarantee consistent human-readable copy.

- [x] **IV. Performance**: Location update interval capped at 60s via CloudKit subscription
  throttle. Photo thumbnail pre-fetch limited to 20 images. Todoist refresh uses foreground
  `Timer` (5 min) + `BGAppRefreshTask` (background). All memory budgets fit within ≤150MB.

## Project Structure

### Documentation (this feature)

```text
specs/001-family-command-center/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output — Swift service protocol definitions
│   ├── LocationService.md
│   ├── WeatherService.md
│   ├── CalendarService.md
│   ├── TaskService.md
│   ├── PhotoService.md
│   ├── JamService.md
│   └── CacheService.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Sonas/                              # Xcode project root
├── App/
│   ├── SonasApp.swift              # @main entry point, scene configuration
│   └── AppConfiguration.swift     # UserDefaults-backed app settings model
│
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift     # Root adaptive layout (iPhone/iPad/Mac/TV)
│   │   └── DashboardViewModel.swift
│   ├── Clock/
│   │   └── ClockPanelView.swift    # Live date/time display (TimelineView)
│   ├── Location/
│   │   ├── LocationPanelView.swift
│   │   ├── LocationViewModel.swift
│   │   └── LocationService.swift   # CloudKit location relay read/write
│   ├── Weather/
│   │   ├── WeatherPanelView.swift
│   │   ├── WeatherViewModel.swift
│   │   └── WeatherService.swift    # WeatherKit + AQI API aggregator
│   ├── Calendar/
│   │   ├── EventsPanelView.swift
│   │   ├── EventsViewModel.swift
│   │   └── CalendarService.swift   # EventKit + Google Calendar REST
│   ├── Tasks/
│   │   ├── TasksPanelView.swift
│   │   ├── TasksViewModel.swift
│   │   └── TodoistService.swift    # Todoist REST API v2
│   ├── Photos/
│   │   ├── PhotoGalleryView.swift  # Auto-rotating TimelineView carousel
│   │   ├── PhotoViewModel.swift
│   │   └── PhotoService.swift      # PhotoKit iCloud Shared Album
│   ├── SpotifyJam/
│   │   ├── JamPanelView.swift
│   │   ├── JamViewModel.swift
│   │   └── SpotifyJamService.swift # Spotify iOS SDK + CoreImage QR
│   └── Settings/
│       └── SettingsView.swift          # Home location, account connections, album/project selection
│
├── Shared/
│   ├── Components/
│   │   ├── PanelView.swift         # Base panel chrome (title, loading, error states)
│   │   ├── ErrorStateView.swift    # Human-readable error display
│   │   ├── LoadingStateView.swift  # Skeleton / shimmer placeholder
│   │   └── RefreshControl.swift    # Pull-to-refresh wrapper
│   ├── DesignSystem/
│   │   ├── Colors.swift            # Family palette (WCAG 2.1 AA verified)
│   │   ├── Typography.swift        # Dynamic Type scale definitions
│   │   └── Icons.swift             # SF Symbols aliases
│   ├── Cache/
│   │   └── CacheService.swift      # SwiftData-backed panel cache
│   ├── Logging/
│   │   └── SonasLogger.swift       # OSLog wrapper with PII-scrubbing guard
│   ├── Mocks/                      # Protocol mock implementations (never linked in Release)
│   │   ├── LocationServiceMock.swift
│   │   ├── CalendarServiceMock.swift
│   │   ├── WeatherServiceMock.swift
│   │   ├── TaskServiceMock.swift
│   │   ├── PhotoServiceMock.swift
│   │   └── JamServiceMock.swift
│   └── Extensions/
│       └── View+Accessibility.swift
│
├── Platform/
│   ├── Watch/
│   │   └── WatchDashboardView.swift    # Compact glance: time, 2 locations, 1 event
│   └── TV/
│       └── TVDashboardView.swift       # Lean-back full-screen layout
│
SonasTests/
├── Contract/
│   ├── CacheContractTests.swift         # SwiftData in-memory ModelContainer
│   ├── LocationContractTests.swift      # CloudKit container stub
│   ├── TodoistContractTests.swift       # URLProtocol stub — Todoist REST v2
│   ├── GoogleCalendarContractTests.swift
│   ├── SpotifyContractTests.swift
│   ├── AQIContractTests.swift
│   ├── WeatherContractTests.swift
│   └── PhotoContractTests.swift         # mock PHAssetCollection
├── Integration/
│   ├── LocationCloudKitTests.swift      # CloudKit test container
│   ├── WeatherIntegrationTests.swift
│   ├── PhotoIntegrationTests.swift      # mock album → carousel renders
│   ├── JamIntegrationTests.swift        # mock SDK → QR Image renders
│   └── DashboardIntegrationTests.swift
├── Performance/
│   └── PerformanceTests.swift           # XCTest measure{} — load time + UI response
└── Unit/
    ├── WeatherServiceTests.swift
    ├── CalendarServiceTests.swift
    ├── TodoistServiceTests.swift
    ├── PhotoServiceTests.swift
    ├── CacheServiceTests.swift
    └── JamServiceTests.swift

SonasUITests/
└── DashboardUITests.swift
```

**Structure Decision**: Single Xcode project with feature-module folder structure. No separate
Swift packages for v1 (single target reduces build complexity). Platform variants (Watch, TV)
are separate Xcode targets sharing the `Shared/` layer. macOS and iPadOS run from the same
iOS target using SwiftUI adaptive layout (no Catalyst overhead for v1; native SwiftUI Mac
target is a v2 candidate).

## Complexity Tracking

> No Constitution Check violations requiring justification. All gates passed.
