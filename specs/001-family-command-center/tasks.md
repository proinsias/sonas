# Tasks: Sonas — iOS Family Command Center

**Input**: Design documents from `specs/001-family-command-center/` **Prerequisites**: plan.md ✓, spec.md ✓, research.md
✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: Included — constitution check §II (Test-First) is a mandatory gate; all contract test fixtures are defined in
`contracts/`; coverage gate ≥80% on `Sonas/` source target.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other [P] tasks in the same phase (different files, no incomplete dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- All file paths are relative to the repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xcode project initialisation and build tooling

- [x] T001 Create Xcode project `Sonas.xcodeproj` with targets: `Sonas` (iOS 17+ deployment), `SonasTests`,
      `SonasUITests`, `WatchSonas` (watchOS 11+), `TVSonas` (tvOS 18+) at repo root
- [x] T002 Configure `Sonas` target capabilities: WeatherKit, CloudKit (container `iCloud.com.yourteam.sonas` —
      auto-derived from bundle ID at runtime), Background Modes (Background fetch, Remote notifications) in Xcode
      Signing & Capabilities
- [x] T003 [P] Add SPM/SDK package dependencies to `Sonas.xcodeproj`: `GoogleSignIn-iOS` and `SpotifyiOS` pinned to
      **exact SemVer versions** (e.g., `GoogleSignIn-iOS 7.1.0`; resolve latest stable at time of addition); commit
      `Package.resolved` to version control _(Constitution §Quality — exact version pinning required)_
- [x] T004 [P] Add required `Info.plist` keys to `Sonas/Info.plist`: `NSLocationWhenInUseUsageDescription`,
      `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSPhotoLibraryUsageDescription`, `SPTClientID`, `SPTRedirectURL`,
      `com.googleusercontent.apps.{CLIENT_ID}` URL scheme, and `sonas` URL scheme
- [x] T005 [P] Configure `.swiftlint.yml` at repo root aligned to Swift API design guidelines; add SwiftLint run-script
      build phase to the `Sonas` target; include a custom `identifier_name` or `function_body_length` rule and a
      `custom_rules` entry enforcing the `given_.*_when_.*_then_.*` pattern for test function names in `SonasTests/`
      _(Constitution §II — test names MUST follow `given_<state>_when_<action>_then_<outcome>`)\_
- [x] T006 Configure `SonasTests` and `SonasUITests` schemes with `-enableCodeCoverage YES`; add a CI build script that
      fails if `Sonas/` source coverage drops below 80%

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Design system, shared components, domain models, cache layer, and app entry point that ALL user stories
depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 [P] Implement WCAG 2.1 AA family colour palette in `Sonas/Shared/DesignSystem/Colors.swift`
- [x] T008 [P] Implement Dynamic Type scale definitions in `Sonas/Shared/DesignSystem/Typography.swift`
- [x] T009 [P] Implement SF Symbols aliases for all panels in `Sonas/Shared/DesignSystem/Icons.swift`
- [x] T010 [P] Implement `View+Accessibility.swift` extension with `.accessibilityLabel` and `.accessibilityHint`
      convenience modifiers in `Sonas/Shared/Extensions/View+Accessibility.swift`
- [x] T011 [P] Implement `PanelView` base chrome (title bar, loading slot, error slot, last-updated badge) in
      `Sonas/Shared/Components/PanelView.swift`
- [x] T012 [P] Implement `ErrorStateView` with a human-readable copy slot in
      `Sonas/Shared/Components/ErrorStateView.swift`
- [x] T013 [P] Implement `LoadingStateView` skeleton/shimmer placeholder in
      `Sonas/Shared/Components/LoadingStateView.swift`
- [x] T014 [P] Implement `RefreshControl` pull-to-refresh SwiftUI wrapper in
      `Sonas/Shared/Components/RefreshControl.swift`
- [x] T015 Implement `AppConfiguration` struct with `UserDefaults`-backed fields and Keychain-backed token storage
      (Google OAuth, Todoist API token, Spotify token) in `Sonas/App/AppConfiguration.swift`
- [x] T016 [P] Define `FamilyMember` and `LocationSnapshot` structs with all fields, constraints, and `isStale` computed
      property in `Sonas/Shared/Models/LocationModels.swift`
- [x] T017 [P] Define `CalendarEvent` struct and `CalendarSource` enum in `Sonas/Shared/Models/CalendarModels.swift`
- [x] T018 [P] Define `WeatherSnapshot`, `DayForecast`, `PressureTrend`, `MoonPhase` (with `displayName` and
      `symbolName`), and `AQICategory` in `Sonas/Shared/Models/WeatherModels.swift`
- [x] T019 [P] Define `Task`, `TaskDue`, and `TaskPriority` structs/enums in `Sonas/Shared/Models/TaskModels.swift`
- [x] T020 [P] Define `Photo`, `JamSession`, and `JamStatus` structs/enums in `Sonas/Shared/Models/MediaModels.swift`
- [x] T021 Define SwiftData `@Model` cache classes (`CachedWeatherSnapshot`, `CachedLocationSnapshot`,
      `CachedCalendarEvent`, `CachedTask`, `CachedJamSession`) each with a `lastUpdated: Date` field in
      `Sonas/Shared/Cache/CachedModels.swift`
- [x] T022 [P] Define `CacheServiceProtocol` (save/load per panel type, `evictStaleEntries`) in
      `Sonas/Shared/Cache/CacheService.swift`
- [x] T023 [P] Implement `CacheContractTests` (in-memory `ModelContainer`; save/load round-trip; `evictStaleEntries`
      removes entries older than TTL) in `SonasTests/Contract/CacheContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Confirm T023 FAILS before writing T024 implementation.
- [x] T024 Implement `CacheService` conforming to `CacheServiceProtocol` with per-type TTL eviction (Weather 1h,
      Location 5min, CalendarEvent past end-time, Task 24h, JamSession on `.ended`) in
      `Sonas/Shared/Cache/CacheService.swift`
- [x] T025 Implement `SonasApp.swift` with `ModelContainer` initialisation, service environment injection via
      `.environment`, `BGTaskScheduler.register` + **no-op placeholder handler** for `com.sonas.refresh` (full handler
      implemented in T089), and `ScenePhase.active` eviction hook in `Sonas/App/SonasApp.swift`
- [x] T025-L [P] Implement `SonasLogger` using `OSLog` with one subsystem per feature module (`location`, `weather`,
      `calendar`, `tasks`, `photos`, `jam`, `cache`); PII-scrubbing guard that omits precise coordinates and display
      names at non-local-only environments in `Sonas/Shared/Logging/SonasLogger.swift` _(Constitution §Quality Logging —
      all service implementations in Phases 3–7 MUST call `SonasLogger` for key data events)_

**Checkpoint**: Foundation ready — design system, all domain models, cache layer, and app entry point are complete. User
story implementation can now begin.

---

## Phase 3: User Story 1 — At-a-Glance Family Dashboard (Priority: P1) 🎯 MVP

**Goal**: Single-screen dashboard showing live clock, all family member locations (via CloudKit relay), and 48-hour
calendar events (iCloud + Google); graceful degradation when any source is unavailable.

**Independent Test**: Launch with `USE_MOCK_LOCATION=1 USE_MOCK_CALENDAR=1`. Dashboard MUST show mock family member
location labels and mock event titles within 500ms, all on one screen with no extra taps. Disable mocks and verify real
CloudKit + EventKit data appear.

### Implementation

- [x] T026 [P] [US1] Define `LocationServiceProtocol` (familyLocations `AsyncStream`, `startPublishing`,
      `stopPublishing`, `refresh`) in `Sonas/Features/Location/LocationService.swift`
- [x] T027 [P] [US1] Define `CalendarServiceProtocol` (`fetchUpcomingEvents(hours:)`, `connectGoogleAccount`,
      `disconnectGoogleAccount`, `isGoogleConnected`) in `Sonas/Features/Calendar/CalendarService.swift`
- [x] T028 [P] [US1] Implement `LocationServiceMock` (returns fixture `[FamilyMember]` via `AsyncStream`; respects
      `USE_MOCK_LOCATION` env flag) in `Sonas/Shared/Mocks/LocationServiceMock.swift`
- [x] T029 [P] [US1] Implement `CalendarServiceMock` (returns fixture `[CalendarEvent]`; respects `USE_MOCK_CALENDAR`
      env flag) in `Sonas/Shared/Mocks/CalendarServiceMock.swift`
- [x] T031 [P] [US1] Implement `LocationContractTests` (CloudKit container stub returning 2 `FamilyLocation` records;
      assert `familyLocations` emits 2 `FamilyMember` values with correct `placeName` and `recordedAt`) in
      `SonasTests/Contract/LocationContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Run T031 — confirm it FAILS — before writing T030.
- [x] T030 [US1] Implement `LocationService` conforming to `LocationServiceProtocol` (CLLocationManager for own device,
      reverse-geocoding `placeName` before CloudKit write, `CKQuerySubscription` for push-based family member updates,
      60s/50m write throttle) in `Sonas/Features/Location/LocationService.swift`
- [x] T034 [P] [US1] Implement `GoogleCalendarContractTests` (URLProtocol stub returning Google Calendar JSON fixture;
      assert returned events include both EventKit mock events and Google-sourced events; assert sort order ascending;
      assert duplicate title+startDate appears only once) in `SonasTests/Contract/GoogleCalendarContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Run T034 — confirm it FAILS — before writing T032 and T033.
- [x] T032 [US1] Implement `GoogleCalendarClient` (Google Calendar REST v3 fetch with `timeMin`/`timeMax`, OAuth token
      refresh via GoogleSignIn SDK, Keychain token storage, `needsGoogleReconnect` flag on 401) in
      `Sonas/Features/Calendar/CalendarService.swift`
- [x] T033 [US1] Implement `CalendarService` conforming to `CalendarServiceProtocol` (EventKit
      `EKEventStore.requestFullAccessToEvents`, `GoogleCalendarClient` for Google accounts, deduplication by
      title+startDate, 48-hour window, ascending sort) in `Sonas/Features/Calendar/CalendarService.swift`
- [x] T035 [US1] Implement `ClockPanelView` (TimelineView updating every second, prominent date and local time display)
      in `Sonas/Features/Clock/ClockPanelView.swift`
- [x] T036 [US1] Implement `LocationViewModel` (`@Observable`; subscribes to `LocationService.familyLocations`; computes
      staleness labels; handles "Location unavailable" for stale/nil snapshots) in
      `Sonas/Features/Location/LocationViewModel.swift`
- [x] T037 [US1] Implement `LocationPanelView` (name + `placeName` label per member; "Location unavailable" for
      stale/nil; scrollable list supporting >10 members; "Enable location in Settings" prompt when permission denied) in
      `Sonas/Features/Location/LocationPanelView.swift`
- [x] T038 [US1] Implement `EventsViewModel` (`@Observable`; calls `CalendarService.fetchUpcomingEvents(hours: 48)`;
      empty-state message; `needsGoogleReconnect` flag exposed to view) in
      `Sonas/Features/Calendar/EventsViewModel.swift`
- [x] T039 [US1] Implement `EventsPanelView` (next 3 events with title, date/time, attendees; "Nothing scheduled" empty
      state; per-account Google reconnect prompt) in `Sonas/Features/Calendar/EventsPanelView.swift`
- [x] T040 [US1] Implement `DashboardViewModel` (`@Observable`; owns all service instances or receives them via
      injection; exposes per-panel loading/error/data state; coordinates service start and refresh) in
      `Sonas/Features/Dashboard/DashboardViewModel.swift`
- [x] T041 [US1] Implement `DashboardView` single-column iPhone layout hosting `ClockPanelView`, `LocationPanelView`,
      and `EventsPanelView` in a vertical `ScrollView` in `Sonas/Features/Dashboard/DashboardView.swift`
- [x] T042 [P] [US1] Implement `LocationCloudKitTests` in `SonasTests/Integration/LocationCloudKitTests.swift`: (a)
      write one `FamilyLocation` record to CloudKit test container; assert `LocationService.refresh()` returns that
      member with correct `placeName`; (b) simulate a second device writing an updated `FamilyLocation` record; assert
      `familyLocations` `AsyncStream` emits the updated member within 60 s via `CKQuerySubscription` — covers FR-017
- [x] T043 [US1] Implement `DashboardIntegrationTests` (all-mock service injection; assert dashboard renders all three
      US1 panels within 500ms; assert "Location unavailable" panel renders when mock returns nil location) in
      `SonasTests/Integration/DashboardIntegrationTests.swift`
- [x] T093 [US1] Implement minimal `SettingsView` shell in `Sonas/Features/Settings/SettingsView.swift` with: (a) home
      location search + coordinate picker stored to `AppConfiguration.homeLocation` (prerequisite for WeatherService in
      Phase 4); (b) Google Calendar connect/disconnect wrapping `CalendarService.connectGoogleAccount()`; wire as a
      modal sheet from `DashboardView` toolbar button in `Sonas/Features/Dashboard/DashboardView.swift`

**Checkpoint**: MVP dashboard (clock + location + events) is fully functional and independently testable. Settings shell
allows real-device configuration for subsequent phases. Deploy to TestFlight for family validation.

---

## Phase 4: User Story 2 — Comprehensive Weather Display (Priority: P2)

**Goal**: Weather panel shows all 8 required attributes (temperature/description, humidity, wind, pressure, AQI,
sunrise/sunset, moon phase) plus 7-day forecast strip simultaneously on a standard phone screen; offline degradation
with "Last updated" label.

**Independent Test**: Set `USE_MOCK_WEATHER=1`. Weather panel MUST display all 8 attributes and a 7-day strip using
fixture data without any scroll or tap. Disable mock: confirm real WeatherKit + Open-Meteo values appear.

### Implementation

- [x] T044 [P] [US2] Define `WeatherServiceProtocol`
      (`fetchWeather(for:) -> (current: WeatherSnapshot, forecast: [DayForecast])`) in
      `Sonas/Features/Weather/WeatherService.swift`
- [x] T045 [P] [US2] Implement `WeatherServiceMock` (returns fixture `WeatherSnapshot` with all fields populated +
      7-element `[DayForecast]`; respects `USE_MOCK_WEATHER` env flag) in `Sonas/Shared/Mocks/WeatherServiceMock.swift`
- [x] T047 [P] [US2] Implement `AQIContractTests` (URLProtocol stub returning `{"current":{"us_aqi":42}}`; assert
      `WeatherSnapshot.airQualityIndex == 42`; assert `airQualityIndex == nil` when stub returns HTTP 500) in
      `SonasTests/Contract/AQIContractTests.swift`
- [x] T048 [P] [US2] Implement `WeatherContractTests` (WeatherKit mock + AQI URLProtocol stub; assert
      `snapshot.airQualityIndex == 42`; assert `forecast.count == 7`; assert `forecast[0].id` equals today midnight) in
      `SonasTests/Contract/WeatherContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Run T047 + T048 — confirm both FAIL — before writing T046.
- [x] T046 [US2] Implement `WeatherService` conforming to `WeatherServiceProtocol` (concurrent `async let` for
      WeatherKit `.current`+`.daily` and Open-Meteo `/v1/air-quality?current=us_aqi`; maps all WeatherKit fields to
      `WeatherSnapshot`; `airQualityIndex = nil` when AQI fetch fails) in `Sonas/Features/Weather/WeatherService.swift`
- [x] T049 [US2] Implement `WeatherViewModel` (`@Observable`; loads cached `WeatherSnapshot` on init for ≤500ms first
      frame; 15-min foreground `Timer` refresh; "Last updated" timestamp from cache; retry control on error) in
      `Sonas/Features/Weather/WeatherViewModel.swift`
- [x] T050 [US2] Implement `WeatherPanelView` (current conditions section with all 8 attributes visible without scroll
      on standard iPhone; horizontal 7-day forecast strip with high/low + SF Symbol per day) in
      `Sonas/Features/Weather/WeatherPanelView.swift`
- [x] T051 [P] [US2] Implement `WeatherServiceTests` (unit; assert correct `MoonPhase` enum from WeatherKit phase value;
      assert `airQualityIndex == nil` and no throw when AQI fetch fails; assert
      `WeatherServiceError.locationNotConfigured` when home coordinate is nil) in
      `SonasTests/Unit/WeatherServiceTests.swift`
- [x] T052 [US2] Integrate `WeatherPanelView` into `DashboardView` below the US1 panels in
      `Sonas/Features/Dashboard/DashboardView.swift`

**Checkpoint**: Weather panel independently functional. All 8 attributes verified in contract + unit tests.

---

## Phase 5: User Story 3 — Family Tasks via Todoist (Priority: P3)

**Goal**: Tasks panel shows open tasks from configured Todoist family projects grouped by project; tasks can be marked
complete with optimistic UI and rollback on error; 5-minute foreground refresh and `BGAppRefreshTask` background
refresh.

**Independent Test**: Set `USE_MOCK_TASKS=1`. Tasks panel MUST show mock tasks grouped by project. Tap a checkbox: task
disappears optimistically. Disable mock: connect real Todoist API token and confirm live tasks appear and can be
completed.

### Implementation

- [x] T053 [P] [US3] Define `TaskServiceProtocol` (`fetchTasks`, `completeTask(id:)`, `connectTodoist(apiToken:)`,
      `disconnectTodoist`, `isConnected`) in `Sonas/Features/Tasks/TodoistService.swift`
- [x] T054 [P] [US3] Implement `TaskServiceMock` (returns fixture `[Task]` grouped by project; `completeTask` succeeds
      immediately; respects `USE_MOCK_TASKS` env flag) in `Sonas/Shared/Mocks/TaskServiceMock.swift`
- [x] T056 [P] [US3] Implement `TodoistContractTests` (URLProtocol stubs for GET /projects, GET /tasks, POST /close 204,
      POST /close 429 with `Retry-After: 60`; assert tasks grouped by `projectName`; assert `completeTask` succeeds on
      204; assert `TaskServiceError.rateLimitExceeded` on 429) in `SonasTests/Contract/TodoistContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Run T056 — confirm it FAILS — before writing T055.
- [x] T055 [US3] Implement `TodoistService` conforming to `TaskServiceProtocol` (GET /projects + GET /tasks per project;
      POST /tasks/{id}/close; cursor pagination via `X-Next-Cursor`; 300ms inter-request delay; 429 back-off with
      `Retry-After`; Keychain API token) in `Sonas/Features/Tasks/TodoistService.swift`
- [x] T057 [US3] Implement `TasksViewModel` (`@Observable`; foreground 5-min `Timer`; optimistic `isCompleting = true`
      on checkbox tap; rollback `isCompleting = false` + error toast on API error; pull-to-refresh; exposes paginated
      task list grouped by project) in `Sonas/Features/Tasks/TasksViewModel.swift`
- [x] T058 [US3] Implement `TasksPanelView` (tasks grouped by `projectName` in `List`; completion checkbox with
      optimistic state; "Show more" pagination affordance at 100-task boundary; "Connect Todoist" empty state;
      connection-error state with reconnect button) in `Sonas/Features/Tasks/TasksPanelView.swift`
- [x] T059 [P] [US3] Implement `TodoistServiceTests` (unit; assert cursor pagination accumulates tasks across pages;
      assert optimistic rollback when `completeTask` throws; assert `TaskServiceError.authenticationFailed` on 401) in
      `SonasTests/Unit/TodoistServiceTests.swift`
- [x] T060 [US3] Integrate `TasksPanelView` into `DashboardView` below the US2 panel in
      `Sonas/Features/Dashboard/DashboardView.swift`

**Checkpoint**: Tasks panel independently functional. Optimistic complete, rollback, and rate-limit handling verified in
tests.

---

## Phase 6: User Story 4 — Shared Family Photos (Priority: P4)

**Goal**: Photo gallery panel displays a rotating carousel of the 20 most recent photos from the designated iCloud
Shared Album, auto-advancing every 10–30 seconds; tap expands to full-screen. Deleted photos disappear gracefully on
next rotation.

**Independent Test**: Set `USE_MOCK_PHOTOS=1`. Gallery MUST display bundled test images rotating automatically without
any tap. Tap a photo: full-screen modal opens with swipe-through navigation. Disable mock: connect real iCloud Shared
Album and confirm rotation.

### Implementation

- [x] T061 [P] [US4] Define `PhotoServiceProtocol` (`fetchRecentPhotos(limit:)`, `loadThumbnail(for:size:)`,
      `loadFullImage(for:)`, `selectSharedAlbum()`, `selectedAlbumName`) in `Sonas/Features/Photos/PhotoService.swift`
- [x] T062 [P] [US4] Implement `PhotoServiceMock` (returns 5 fixture `Photo` items; `loadThumbnail` returns a bundled
      test image; respects `USE_MOCK_PHOTOS` env flag) in `Sonas/Shared/Mocks/PhotoServiceMock.swift`
- [x] T064 [P] [US4] Implement `PhotoContractTests` (mock `PHAssetCollection` with 5 `PHAsset` stubs; assert
      `fetchRecentPhotos` returns 5 photos sorted by `creationDate` descending; assert `PhotoServiceError.albumEmpty`
      when album has no assets) in `SonasTests/Contract/PhotoContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Run T064 — confirm it FAILS — before writing T063.
- [x] T063 [US4] Implement `PhotoService` conforming to `PhotoServiceProtocol`
      (`PHAssetCollection.fetchAssetCollections` with `.albumCloudShared`; `PHFetchOptions` sorted `creationDate`
      descending, limit 20; `PHImageManager.requestImage` with `.opportunistic` delivery; `PHPhotoLibraryChangeObserver`
      for real-time change detection) in `Sonas/Features/Photos/PhotoService.swift`
- [x] T065 [US4] Implement `PhotoViewModel` (`@Observable`; fetches 20 most-recent photos on init;
      `PHPhotoLibraryChangeObserver` removes deleted photos without crash; exposes `selectedAlbumName` for empty-state
      prompt) in `Sonas/Features/Photos/PhotoViewModel.swift`
- [x] T066 [US4] Implement `PhotoGalleryView` (`TimelineView` carousel with 15-second auto-advance interval at 60fps;
      full-screen modal sheet on tap with swipe-through navigation; "Select a shared album" prompt when none configured;
      "Add photos" prompt when album is empty) in `Sonas/Features/Photos/PhotoGalleryView.swift`
- [x] T067 [P] [US4] Implement `PhotoServiceTests` (unit; assert sort order is `creationDate` descending; assert limit
      of 20 is enforced; assert `PHPhotoLibraryChangeObserver` triggers re-fetch that omits a deleted photo ID) in
      `SonasTests/Unit/PhotoServiceTests.swift`
- [x] T068 [US4] Integrate `PhotoGalleryView` into `DashboardView` below the US3 panel in
      `Sonas/Features/Dashboard/DashboardView.swift`
- [x] T068-I [P] [US4] Implement `PhotoIntegrationTests` (mock `PHAssetCollection` with 5 assets injected via
      `PhotoServiceMock`; assert `PhotoGalleryView` renders ≥1 thumbnail within 500 ms; assert
      `PHPhotoLibraryChangeObserver` callback removes a deleted photo from the carousel without crash) in
      `SonasTests/Integration/PhotoIntegrationTests.swift` _(Constitution §II — every user-facing feature MUST have an
      integration test)_

**Checkpoint**: Photo gallery independently functional. Auto-rotation and graceful deleted-photo handling verified in
tests.

---

## Phase 7: User Story 5 — Spotify Jam QR Code (Priority: P5)

**Goal**: Jam panel allows starting and ending a Spotify Group Session via the Spotify iOS SDK; displays the join QR
code generated with CoreImage; handles not-installed and not-connected states.

**Independent Test**: Set `USE_MOCK_JAM=1`. Tap "Start Jam": QR code MUST appear on screen. Tap "End Jam": QR removed.
Disable mock: connect real Spotify account and verify Jam session creation and QR scan.

### Implementation

- [x] T069 [P] [US5] Define `JamServiceProtocol` (`currentSession`, `startJam()`, `endJam()`, `connectSpotify()`,
      `isSpotifyConnected`, `isSpotifyInstalled`) in `Sonas/Features/SpotifyJam/SpotifyJamService.swift`
- [x] T070 [P] [US5] Implement `JamServiceMock` (`startJam` returns fixture `JamSession` with
      `joinURL = "https://spotify.com/jam/abc123"`; `endJam` sets `status = .ended`; respects `USE_MOCK_JAM` env flag)
      in `Sonas/Shared/Mocks/JamServiceMock.swift`
- [x] T072 [P] [US5] Implement `SpotifyContractTests` (mock `SPTSessionManager` returning valid token; mock
      `SPTAppRemote` returning `joinURL = "https://spotify.com/jam/abc123"`; assert `startJam()` returns
      `JamSession.status == .active` and `joinURL` matches; assert `startJam()` throws
      `JamServiceError.spotifyNotInstalled` when `isSpotifyInstalled == false`) in
      `SonasTests/Contract/SpotifyContractTests.swift`
  > 🔴 **TEST-FIRST GATE**: Run T072 — confirm it FAILS — before writing T071.
- [x] T071 [US5] Implement `SpotifyJamService` conforming to `JamServiceProtocol` (`SPTConfiguration` with `clientID`
      and `redirectURL` from Info.plist; `SPTSessionManager` for OAuth via `ASWebAuthenticationSession`;
      `SPTAppRemote.playerAPI.startGroupSession` returning `joinURL`; Keychain token storage; `appRemoteDisconnected`
      sets `status = .ended`) in `Sonas/Features/SpotifyJam/SpotifyJamService.swift`
- [x] T073 [US5] Implement `JamViewModel` (`@Observable`; state machine: none → active → ending → ended; exposes
      `currentSession` and `isLoading`; handles `appRemoteDisconnected` by transitioning to `.ended` and removing QR) in
      `Sonas/Features/SpotifyJam/JamViewModel.swift`
- [x] T074 [US5] Implement `JamPanelView` (QR code via `CIFilter.qrCodeGenerator` scaled to 200×200pt from
      `JamSession.joinURL`; "Start Jam" / "End Jam" buttons; "Install Spotify" App Store deep-link prompt when not
      installed; "Connect Spotify" OAuth prompt when not connected) in `Sonas/Features/SpotifyJam/JamPanelView.swift`
- [x] T075 [P] [US5] Implement `JamServiceTests` (unit; assert `joinURL` string encodes correctly as QR CIImage data;
      assert state machine transitions none→active→ending→ended; assert `appRemoteDisconnected` forces `.ended` from
      `.active` without calling `endJam`) in `SonasTests/Unit/JamServiceTests.swift`
- [x] T076 [US5] Integrate `JamPanelView` into `DashboardView` below the US4 panel in
      `Sonas/Features/Dashboard/DashboardView.swift`
- [x] T076-I [P] [US5] Implement `JamIntegrationTests` (`JamServiceMock` injected; assert `JamPanelView` renders a
      non-nil `Image` from `CIFilter.qrCodeGenerator` output within 500 ms of `startJam()` resolving; assert QR `Image`
      accessibility identifier disappears after `endJam()`) in `SonasTests/Integration/JamIntegrationTests.swift`
      _(Constitution §II — every user-facing feature MUST have an integration test)_

**Checkpoint**: Jam panel independently functional. QR generation and all state machine transitions verified in tests.

---

## Phase 8: User Story 6 — Multi-Platform Accessibility (Priority: P6)

**Goal**: Dashboard adapts to iPad (3-column grid), Mac (mouse + keyboard), Apple Watch (compact glance), and Apple TV
(lean-back grid) using SwiftUI adaptive layout breakpoints and separate target views for watchOS and tvOS.

**Independent Test**: Run on iPad Pro 13-inch simulator (iOS 18). Dashboard MUST display all panels in a 3-column grid
without horizontal scrolling and with no empty space exceeding 30% of the viewport.

### Implementation

- [x] T077 [US6] Update `DashboardView` to implement `AdaptiveLayout` using `horizontalSizeClass` / `verticalSizeClass`:
      `.compact` → 1-column scroll (iPhone portrait); `.regular`/`.compact` → 2-column (iPhone landscape);
      `.regular`/`.regular` → 3-column `LazyVGrid` (iPad/Mac) matching the panel grid defined in research.md §Decision 8
      in `Sonas/Features/Dashboard/DashboardView.swift`
- [x] T078 [P] [US6] Implement `WatchDashboardView` (`TimelineView` live clock, first-name-only labels for ≤2 family
      members, next event title, `.containerBackground` for Watch complication registration) in
      `Sonas/Platform/Watch/WatchDashboardView.swift`
- [x] T079 [P] [US6] Implement `TVDashboardView` (full-screen `LazyVGrid` with focus-engine navigation via
      `focusable()`, passive read-only layout — no task completion or Jam initiation) in
      `Sonas/Platform/TV/TVDashboardView.swift`
- [x] T080 [US6] Implement `DashboardUITests` in `SonasUITests/DashboardUITests.swift`: (a) assert 3-column grid renders
      on iPad Pro 13-inch simulator with all panel accessibility identifiers visible; (b) assert all interactive
      controls are reachable via keyboard on Mac Designed for iPad; (c) assert that tapping "Start Jam" from the
      dashboard home requires ≤ 5 `XCUIElement` tap calls before the QR code accessibility identifier is visible —
      covers SC-005

**Checkpoint**: App runs on iPhone, iPad, Mac, Apple Watch, and Apple TV with platform-appropriate layouts verified by
UI tests.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Background refresh, offline degradation, integration tests, and quality gates across all user stories

- [ ] T082 [P] Implement offline degraded mode in `PanelView`: when `CacheService` returns stale data, display the
      cached value overlaid with a "Last updated [timestamp]" badge and a retry affordance; assert all panels remain
      functional when one source throws `networkUnavailable` in `Sonas/Shared/Components/PanelView.swift`
- [x] T083 [P] Implement `WeatherIntegrationTests` (requires WeatherKit entitlement; fetch real `WeatherSnapshot` for a
      hard-coded coordinate in CI; assert `snapshot` is non-nil and `forecast.count == 7`) in
      `SonasTests/Integration/WeatherIntegrationTests.swift`
- [x] T084 [P] Implement `CalendarServiceTests` (unit; EventKit mock + Google Calendar URLProtocol stub; assert
      deduplication removes one event when title+startDate match across sources; assert sort order ascending; assert
      `isGoogleConnected == false` after `disconnectGoogleAccount`) in `SonasTests/Unit/CalendarServiceTests.swift`
- [x] T085 [P] Implement `CacheServiceTests` (unit; assert `loadWeather()` returns `nil` after TTL eviction; assert
      location staleness thresholds — fresh <5 min, stale 5–30 min, very stale >30 min — produce correct `isStale` and
      display label) in `SonasTests/Unit/CacheServiceTests.swift`
- [ ] T086 Run the quickstart.md §6 first-launch checklist on iPhone 16 Pro simulator with all `USE_MOCK_*=1` flags set;
      resolve any rendering failures or missing permission prompts across `Sonas/`
- [ ] T087 Run SwiftLint across `Sonas/` and resolve all violations; confirm zero-warning CI build with the
      `.swiftlint.yml` gate
- [ ] T088 Run `xcodebuild test -enableCodeCoverage YES` on `SonasTests`; identify files below 80% coverage and add
      targeted unit tests in `SonasTests/Unit/` to meet the gate
- [x] T089 Implement `BGAppRefreshTask` full handler in `SonasApp.swift` (replacing the no-op from T025): on task
      execution fetch weather snapshot, AQI, and Todoist tasks; write results to `CacheService`; schedule next task via
      `BGTaskScheduler.submit`; expiry handler cancels in-flight work in `Sonas/App/SonasApp.swift`
- [x] T090 [P] Implement performance verification tests in `SonasTests/Performance/PerformanceTests.swift`: use
      `XCTestCase.measure {}` to assert (a) cached-data dashboard render ≤ 500 ms — inject pre-populated `CacheService`
      and measure `DashboardView` body evaluation; (b) `WeatherViewModel` cache-load path ≤ 500 ms; (c) UI transition
      from tap to next screen ≤ 100 ms _(Constitution §IV — baselines MUST be verified in task checklist)_
- [ ] T091 [P] Profile memory for all four polling/subscription services using Instruments Leaks + Allocations on a real
      device or simulator; document peak RSS measurements in plan.md Complexity Tracking table; confirm total ≤ 150 MB
      peak with all services active _(Constitution §IV — memory MUST be profiled for polling services)_
- [ ] T092 [P] Expand `SettingsView` (built in T093) with remaining account management: Todoist API token entry with
      validation, Spotify connect/disconnect, photo album picker, temperature unit toggle in
      `Sonas/Features/Settings/SettingsView.swift`
- [x] T094 [P] Implement `SettingsUITests` in `SonasUITests/SettingsUITests.swift`: (a) assert home location picker
      saves coordinate to `AppConfiguration` and the saved value is reflected in `WeatherPanelView` on next launch; (b)
      assert Todoist token entry invokes `TaskService.connectTodoist` and panel transitions from "Connect Todoist" to
      task list; (c) assert photo album picker selection persists after app restart _(Constitution §II — every
      user-facing feature MUST have at least one acceptance/integration test)_

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — **BLOCKS all user stories**
- **US1–US5 (Phases 3–7)**: All depend on Phase 2 completion; can proceed independently in parallel once Phase 2 is done
- **US6 (Phase 8)**: Depends on all US1–US5 `DashboardView` integration tasks (T041, T052, T060, T068, T076) — all
  panels must exist before layout adaptation
- **Polish (Phase 9)**: Depends on all targeted user stories being complete

### User Story Dependencies

- **US1 (P1)**: Start after Phase 2 — no dependency on other stories — **this is the MVP**
- **US2 (P2)**: Start after Phase 2 — independent of US1; **T049 (WeatherViewModel) requires
  `AppConfiguration.homeLocation` to be settable — complete T093 (minimal SettingsView) before real-device US2
  testing**; final task T052 appends to `DashboardView`
- **US3 (P3)**: Start after Phase 2 — independent of US1/US2; final task T060 appends to `DashboardView`
- **US4 (P4)**: Start after Phase 2 — independent of all previous stories; final task T068 appends to `DashboardView`
- **US5 (P5)**: Start after Phase 2 — independent of all previous stories; final task T076 appends to `DashboardView`
- **US6 (P6)**: Start after T041 + T052 + T060 + T068 + T076 are merged — requires all panels to exist in
  `DashboardView`

### Within Each User Story

1. Define protocol (can be done in parallel with other story protocols)
2. Implement mock (parallel with protocol definition — same interface, different file)
3. **Write contract tests** (parallel with mock — both depend only on the protocol) — **🔴 run and confirm FAILING
   before next step**
4. Implement real service (depends on step 3 tests being confirmed red)
5. ViewModel (depends on service protocol)
6. View (depends on ViewModel)
7. Integration into `DashboardView` (last task of each story — **serialize to avoid merge conflicts**)

### Parallel Opportunities

- T003, T004, T005 in Phase 1 can run simultaneously
- T007–T020 in Phase 2 (design system + models) can all run simultaneously
- T022 (CacheServiceProtocol) and T023 (CacheContractTests) can run in parallel; T024 (CacheService impl) MUST follow
  T023 being confirmed red
- Within each user story: protocol + mock + contract tests can all run in parallel with **each other**; the real service
  implementation MUST follow the contract tests being confirmed failing
- US2, US3, US4, US5 can all start in parallel once Phase 2 is complete (if team capacity allows)
- T078 (Watch) and T079 (TV) in Phase 8 are always parallel
- T082–T085 in Phase 9 are all parallel; T089–T092, T094 are also parallel with each other

---

## Parallel Example: User Story 1

```
# Step 1 — Parallel protocol + mock kickoff:
T026: Define LocationServiceProtocol        T027: Define CalendarServiceProtocol
T028: Implement LocationServiceMock         T029: Implement CalendarServiceMock

# Step 2 — Write contract tests (parallel with each other; both depend only on protocol):
T031: LocationContractTests                 T034: GoogleCalendarContractTests
       ↓ RUN + CONFIRM FAILS                       ↓ RUN + CONFIRM FAILS

# Step 3 — Implement real services (ONLY after tests are red):
T030: Implement LocationService
T032: Implement GoogleCalendarClient
T033: Implement CalendarService

# Step 4 — After T030 + T033 complete — parallel:
T035: ClockPanelView                        T036: LocationViewModel
                                            T038: EventsViewModel

# Step 5 — After T036 / T038:
T037: LocationPanelView                     T039: EventsPanelView

# Step 6 — After T037 + T039:
T040: DashboardViewModel
T041: DashboardView (US1 shell)             T042: LocationCloudKitTests (parallel)
T043: DashboardIntegrationTests
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (**CRITICAL** — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Clock, location, and events render on-device with mock data; run contract + integration tests
5. Deploy to TestFlight for family validation before proceeding to US2

### Incremental Delivery

1. Setup + Foundational → project builds cleanly with full design system
2. US1 → At-a-glance MVP dashboard → TestFlight (family validation gate)
3. US2 → Add weather panel → TestFlight
4. US3 → Add tasks panel → TestFlight
5. US4 → Add photo gallery → TestFlight
6. US5 → Add Spotify Jam → TestFlight
7. US6 → iPad / Mac / Watch / TV layouts → App Store submission

### Parallel Team Strategy

With multiple developers once Phase 2 is complete:

- **Developer A**: US1 (Location + Calendar + Dashboard shell) — highest priority
- **Developer B**: US2 (Weather — WeatherKit + AQI)
- **Developer C**: US3 (Todoist Tasks)
- **Developer D**: US4 + US5 (Photos + Jam — smaller stories that share no files)

Each developer's final task (`DashboardView` integration) must be **serialized** to avoid merge conflicts.

---

## Notes

- [P] tasks = different files, no incomplete dependencies — safe to run in parallel
- [USn] label maps each task to its spec.md user story for traceability
- Set all `USE_MOCK_*=1` environment variables in the Xcode debug scheme from day 1 — enables fully offline development
  with no real credentials
- All `DashboardView` integration tasks (T041, T052, T060, T068, T076, T077) and the T093 toolbar-button wire-up touch
  the **same file** — serialize these commits to avoid merge conflicts
- WeatherKit entitlement activation can take hours on Apple Developer portal — start T002 on the first day of Phase 1
- **PR requirement (Constitution §III)**: Every PR that touches a view file MUST include at least one simulator
  screenshot or screen recording in the PR description; reviewers MUST reject UI PRs without visual evidence
- CloudKit schema is auto-created on first run in development containers; export and promote to production before
  TestFlight submission (see quickstart.md §8)
