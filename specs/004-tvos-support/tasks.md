# Tasks: Sonas — tvOS Full Support

**Input**: Design documents from `specs/004-tvos-support/` **Prerequisites**: plan.md, spec.md, research.md,
data-model.md, contracts/

**Tests**: Included — the Constitution (§II) mandates test-first development for all features. Contract tests for
external integrations and UI tests for all user stories are required.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Exact file paths included in all descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add new build targets and entitlements so the project compiles cleanly before any implementation begins.

- [x] T001 Add `TVSonasUITests` bundle.ui-testing target (platform macOS → tvOS 18, sources: `TVSonasUITests/`, bundle
      ID `com.yourteam.sonas.tv.uitests`, depends on `TVSonas`) to `project.yml.template` and mirror to `project.yml`;
      add scheme entry under `TVSonas.test.targets`
- [x] T002 Add `TVTopShelfExtension` app-extension target (platform tvOS 18, sources: `TVTopShelfExtension/`, bundle ID
      `com.yourteam.sonas.tv.topshelf`) to `project.yml.template` and mirror to `project.yml`; add as dependency of
      `TVSonas` target
- [x] T003 Add WeatherKit entitlement (`com.apple.developer.weatherkit: true`) and AppGroup entitlement
      (`com.apple.security.application-groups: [group.com.sonas.topshelf]`) to `TVSonas` and `TVTopShelfExtension`
      targets in `project.yml.template` and `project.yml`; create `TVSonas/TVSonas.entitlements` and
      `TVTopShelfExtension/TVTopShelfExtension.entitlements`
- [x] T004 Create empty source directories: `TVSonasUITests/` and `TVTopShelfExtension/`; run `xcodegen generate` to
      update `Sonas.xcodeproj` with all three new targets and verify the project builds cleanly for tvOS Simulator
      (`xcodebuild build -scheme TVSonas`)
- [x] T005 Add `tests-ui-tv` task to `.mise.toml` mirroring the existing `tests-ui-mac` pattern but using
      `-scheme TVSonas -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)'`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Platform guards and shared models that ALL user stories depend on. No US work may begin until this phase is
complete.

**⚠️ CRITICAL**: These tasks block all user story phases.

- [x] T006 Add `#if !os(tvOS)` guards around the `@preconcurrency import EventKit` line and all EventKit-dependent code
      paths in `Sonas/Features/Calendar/CalendarService.swift` so the file compiles on tvOS (the tvOS app will use
      `TVCalendarService` instead); verify `xcodebuild build -scheme TVSonas` passes
- [x] T007 [P] Add `#if !os(tvOS)` guard around the `startPublishing()` method body in
      `Sonas/Features/Location/LocationService.swift` so it becomes a no-op on tvOS (the TV reads but never publishes
      its own location)
- [x] T008 [P] Extend the existing `#if os(iOS) && !targetEnvironment(macCatalyst)` guard in
      `Sonas/Features/SpotifyJam/JamViewModel.swift`'s `makeDefault()` to also exclude tvOS; return
      `JamViewModel(service: JamServiceMock())` on tvOS (Spotify SDK unavailable)
- [x] T009 [P] Add `TVCurrentTrack` struct (`id`, `title`, `artistName`, `albumArtURL: URL?`, `isPlaying`, `fetchedAt`;
      conforming to `Identifiable`, `Equatable`, `Sendable`) to `Sonas/Shared/Models/MediaModels.swift`

**Checkpoint**: Run `xcodebuild build -scheme TVSonas` — must pass with zero errors before continuing.

---

## Phase 3: User Story 1 — Live Family Dashboard (Priority: P1) 🎯 MVP

**Goal**: Replace all hardcoded fixture data with live service calls so every panel shows real family data.

**Independent Test**: Launch `TVSonas` scheme on Apple TV 4K Simulator with all `USE_MOCK_*=0` env vars; verify all
panels show non-fixture data (live weather, real events, real photos, real family locations).

### Contract Tests — Write FIRST, Confirm FAIL (Constitution §II)

- [x] T010 [P] [US1] Write `TVCalendarServiceTests` in `SonasTests/TVCalendarServiceTests.swift` — 4 scenarios from
      `contracts/TVCalendarService.md`: `given_googleConnected_when_fetchUpcomingEvents_then_returnsSortedEvents`,
      `given_notAuthenticated_when_fetchUpcomingEvents_then_throwsAuthError`,
      `given_networkError_when_fetchUpcomingEvents_then_throwsFetchFailed`,
      `given_tokenExpired_when_fetchUpcomingEvents_then_needsReauthIsTrue`; before writing the tests, extend
      `CalendarServiceMock` in `Sonas/Shared/Mocks/CalendarServiceMock.swift` to add stub properties
      `isGoogleConnected: Bool = true` and `needsReauth: Bool = false` (settable per test via init) so the test file
      compiles; run and confirm all FAIL
- [x] T011 [P] [US1] Write `TVSpotifyReadServiceTests` in `SonasTests/TVSpotifyReadServiceTests.swift` — 3 scenarios
      from `contracts/TVSpotifyReadService.md`:
      `given_authenticated_trackPlaying_when_fetchCurrentlyPlaying_then_returnsTrack`,
      `given_authenticated_nothingPlaying_when_fetchCurrentlyPlaying_then_returnsNil`,
      `given_notAuthenticated_when_fetchCurrentlyPlaying_then_returnsNilAndNoRequest`; run and confirm all FAIL
- [x] T011a [P] [US1] Create `TVSpotifyReadServiceMock` in `Sonas/Shared/Mocks/TVSpotifyReadServiceMock.swift` — a
      struct conforming to `TVSpotifyReadServiceProtocol` that returns a fixture `TVCurrentTrack` when `isAuthenticated`
      is true and `nil` when false; used by `USE_MOCK_JAM` env var wiring in `TVShell` (T016) and verified by T035

### Implementation

- [x] T012 [P] [US1] Implement `TVDeviceAuthState` enum (cases: `idle`, `pendingUserAction`, `polling`, `authorized`,
      `expired`, `failed`) and `TVDeviceAuthFlow` actor (methods: `startFlow()`, `poll()`, `cancel()`; polls
      `oauth2.googleapis.com/token` until authorized or expired) in `Sonas/Platform/TV/TVDeviceAuthFlow.swift`
- [x] T012a [P] [US1] Write `TVDeviceAuthFlowTests` in `SonasTests/TVDeviceAuthFlowTests.swift` — 6 scenarios covering
      all state transitions: `given_idle_when_startFlowSucceeds_then_pendingUserAction`,
      `given_pendingUserAction_when_pollCalled_then_stateIsPolling`, `given_polling_when_tokenReceived_then_authorized`,
      `given_polling_when_expiresAtElapsed_then_expired`, `given_polling_when_networkError_then_failed`,
      `given_anyState_when_cancelCalled_then_idle`; run and confirm all FAIL before T012 implementation
- [x] T013 [P] [US1] Implement `TVDeviceAuthView` — displays `user_code` and `accounts.google.com/device` URL as large
      TV-legible text with a spinner while `TVDeviceAuthFlow` polls in `Sonas/Platform/TV/TVDeviceAuthView.swift`; shown
      by `TVCalendarService` when `needsReauth` is true
- [x] T014 [US1] Implement `TVCalendarServiceProtocol` and `TVCalendarService` (wraps the existing
      `GoogleCalendarClient`; stores/reads OAuth token via `AppStorage`; exposes `isGoogleConnected` and `needsReauth`;
      triggers `TVDeviceAuthFlow` when token is absent) in `Sonas/Platform/TV/TVCalendarService.swift`; run
      `TVCalendarServiceTests` and confirm all PASS
- [x] T015 [P] [US1] Implement `TVSpotifyReadServiceProtocol` and `TVSpotifyReadService` (polls
      `api.spotify.com/v1/me/player/currently-playing` every 30 s; reads cached Spotify token from `AppStorage`; returns
      `TVCurrentTrack?`; returns `nil` without throwing when unauthenticated) in
      `Sonas/Platform/TV/TVSpotifyReadService.swift`; run `TVSpotifyReadServiceTests` and confirm all PASS
- [x] T016 [US1] Implement `TVShell` in `Sonas/Platform/TV/TVShell.swift` — initialises and holds all ViewModels
      (`WeatherViewModel`, `EventsViewModel` backed by `TVCalendarService`, `LocationViewModel`, `PhotoViewModel`,
      `TasksViewModel`, `JamViewModel`/`TVSpotifyReadService`); wires USE*MOCK*\* env var checks to match the existing
      `WeatherViewModel.makeDefault()` factory pattern on all VMs; displays a `LazyVGrid(columns: 3)` with
      `ClockPanelView`, `WeatherPanelView`, `EventsPanelView`, `LocationPanelView`, `PhotoGalleryView`, `TasksPanelView`
      panels
- [x] T017 [US1] Simplify `Sonas/Platform/TV/TVDashboardView.swift` to a one-liner that embeds `TVShell`; remove all
      fixture data structs (`TVWeatherFixture`, `TVEventFixture`) from the file
- [x] T018 [US1] Write `TVDashboardUITests` scenario 1 in `TVSonasUITests/TVDashboardUITests.swift` — launch app with
      mock env vars, verify `WeatherPanel`, `EventsPanel`, and `LocationPanel` accessibility identifiers are present and
      not showing loading state after 30 s

**Checkpoint**: `TVSonas` app launches on tvOS Simulator showing all panels with live (or mock) data. No fixture values
remain in Platform/TV source files.

---

## Phase 4: User Story 2 — Remote-Controlled Navigation (Priority: P2)

**Goal**: Every panel is focusable via Apple TV remote; selecting a panel expands it to full-screen detail; Back returns
to the grid with focus restored.

**Independent Test**: On tvOS Simulator, press directional pad to move focus between panels (focus highlight visible),
press Select to expand a panel, press Menu/Back to return with the same panel focused.

### Implementation

- [x] T019 [US2] Add `.focusable()` and `.buttonStyle(.card)` to each panel tile in `TVShell` and wrap the grid in a
      `NavigationStack` in `Sonas/Platform/TV/TVShell.swift`; bind a `@State selectedPanel: AppSection?` that triggers
      navigation to `TVPanelDetailView`
- [x] T020 [US2] Implement `TVPanelDetailView` in `Sonas/Platform/TV/TVPanelDetailView.swift` — switches on `AppSection`
      enum and routes to the appropriate full-screen detail view; handles `.weather`, `.calendar`, `.location`,
      `.photos`, `.tasks`, `.jam` cases
- [x] T021 [P] [US2] Implement full-screen weather detail (current conditions + 7-day forecast at TV scale) as a
      sub-view inside `TVPanelDetailView.swift` using the shared `WeatherViewModel`
- [x] T022 [P] [US2] Implement full-screen calendar detail (scrollable events list at TV scale) as a sub-view inside
      `TVPanelDetailView.swift` using the shared `EventsViewModel`
- [x] T023 [P] [US2] Implement full-screen location detail (`Map` with family member pins) as a sub-view inside
      `TVPanelDetailView.swift` using `LocationViewModel.members`
- [x] T024 [P] [US2] Implement full-screen photo detail (single photo with `onMoveCommand` left/right to browse; index
      tracked via `@State`) as a sub-view inside `TVPanelDetailView.swift` using `PhotoViewModel`
- [x] T025 [US2] Write `TVNavigationUITests` in `TVSonasUITests/TVNavigationUITests.swift` — directional pad moves
      focus, Select on `WeatherPanel` pushes detail view, Back pops and restores focus to `WeatherPanel`

**Checkpoint**: Full remote-navigation cycle (grid → detail → back) works for all 4 tested panel types.

---

## Phase 5: User Story 3 — Full Panel Coverage (Priority: P3)

**Goal**: All six family panels (plus clock) are present in a 3-column grid; the Photos panel auto-advances as a
slideshow; all text is legible at 3+ metres; Spotify Jam shows currently playing track (display-only).

**Independent Test**: Launch app and confirm 7 panel tiles visible in grid; leave idle for 60 s and confirm Photos panel
has advanced to a different photo.

### Implementation

- [x] T026 [US3] Implement `TVSlideshowPanelView` in `Sonas/Platform/TV/TVSlideshowPanelView.swift` using
      `TimelineView(.periodic(from: .now, by: 20))` to auto-advance `selectedIndex` over `PhotoViewModel.photos`;
      displays current photo full-bleed within the panel tile; uses `PhotoViewModel` injected from `TVShell`
- [x] T027 [US3] Implement `TVSpotifyJamPanel` as a private sub-view in `Sonas/Platform/TV/TVShell.swift` — shows track
      name, artist, and async-loaded album art from `TVSpotifyReadService`; shows a tasteful idle state ("Nothing
      playing") when `TVCurrentTrack` is nil; displayed as the 7th panel (Spotify Jam position)
- [x] T028 [US3] Update `TVShell`'s `LazyVGrid` in `Sonas/Platform/TV/TVShell.swift` to use the final 7-panel layout:
      Clock + Weather + Calendar (row 1), Tasks + Location + Jam (row 2), Photos spanning all 3 columns (row 3); replace
      the placeholder `PhotoGalleryView` tile with `TVSlideshowPanelView`
- [x] T029 [US3] Verify 10-foot UI legibility: build and run on tvOS Simulator at 1080p, screenshot `TVShell` at full
      resolution, confirm all panel titles and primary data values (temperature, next event) are readable; adjust font
      sizes if needed (tvOS `.title`, `.title2`, `.headline` scale up at TV safe area)
- [x] T030 [US3] Write `TVSlideshowUITests` in `TVSonasUITests/TVSlideshowUITests.swift` — launch with
      `USE_MOCK_PHOTOS=1`, assert Photos panel accessibility identifier is present; wait 25 s and assert `selectedIndex`
      has advanced (verify via accessibility value change or a visible photo-index label)

**Checkpoint**: All 7 panels visible, slideshow auto-advances, Spotify shows live track or idle state.

---

## Phase 6: User Story 4 — Top Shelf Integration (Priority: P4)

**Goal**: When `TVSonas` is in the top row of the Apple TV home screen, the Top Shelf displays a recent family photo and
the next calendar event.

**Independent Test**: Install `TVSonas` on Apple TV Simulator, add it to the top row, highlight its icon, and confirm
the Top Shelf shows a photo image and event title/time.

### Implementation

- [x] T031 [US4] Create `TVTopShelfSnapshot` struct (`photoFileURL: URL?`, `nextEventTitle: String?`,
      `nextEventStart: Date?`, `updatedAt: Date`; conforming to `Codable`, `Sendable`) in a new file
      `TVTopShelfExtension/TVTopShelfSnapshot.swift`; make the file a member of both `TVSonas` and `TVTopShelfExtension`
      targets in `project.yml`
- [x] T032 [US4] Implement `TopShelfContentProvider: TVTopShelfContentProvider` in
      `TVTopShelfExtension/TopShelfContentProvider.swift` — reads `TVTopShelfSnapshot` from
      `UserDefaults(suiteName: "group.com.sonas.topshelf")`; returns `TVTopShelfInsetContent` with a wide image from
      `snapshot.photoFileURL` and a `TVContentItem` with `nextEventTitle` and `nextEventStart`; returns an empty shelf
      if the snapshot is nil or stale (older than 6 h)
- [x] T033 [US4] Create the `TVTopShelfExtension` entry point in `TVTopShelfExtension/TVSonasTopShelfExtension.swift`
      conforming to `TVTopShelfExtensionContext` and declaring `TopShelfContentProvider` as the provider
- [x] T034 [US4] Add `writeTopShelfSnapshot()` method to `TVShell` in `Sonas/Platform/TV/TVShell.swift` — copies the
      most recent photo asset to the AppGroup container directory and writes a JSON-encoded `TVTopShelfSnapshot` to
      `UserDefaults(suiteName: "group.com.sonas.topshelf")`; call this method after each successful data refresh cycle
      (after WeatherViewModel + EventsViewModel both complete their initial load)

**Checkpoint**: Run on tvOS Simulator, add to top row, highlight — Top Shelf shows family photo and event.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Stability verification, offline/stale states, and performance baselines required by the Constitution.

- [x] T035 [P] Verify all six `USE_MOCK_*=1` environment variables correctly disable live network calls on tvOS (run
      `TVSonas` scheme with all mocks enabled, use Instruments Network profiler to confirm zero outbound requests); fix
      any missing mock paths
- [x] T036 [P] Verify offline stale-data behaviour: launch with live services, then disable network in Simulator
      (Settings → Developer → Network Link Conditioner → 100% Loss), wait 1 refresh cycle, confirm all panels show stale
      badge (`PanelView.staleDataBadge`) rather than error state; fix any panel that shows a blank or crash
- [x] T037 Run Instruments Allocations + Leaks template on tvOS Simulator for 30 minutes with all mocks enabled; record
      heap baseline in `specs/004-tvos-support/plan.md` under Performance Baselines; flag any monotonic heap growth for
      investigation (SC-004 gate — full 8 h run required before shipping)
- [x] T038 [P] Run `xcodebuild test -scheme SonasTests` and confirm `TVCalendarServiceTests` (4) and
      `TVSpotifyReadServiceTests` (3) all pass; zero test failures permitted
- [x] T039 [P] Run `xcodebuild test -scheme TVSonas` (UI tests) and confirm `TVDashboardUITests`, `TVNavigationUITests`,
      and `TVSlideshowUITests` all pass; fix any failures

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — no dependency on US2/US3/US4
- **US2 (Phase 4)**: Depends on Phase 3 (needs TVShell panels to navigate)
- **US3 (Phase 5)**: Depends on Phase 3 (extends TVShell panels); US2 not strictly required but recommended
- **US4 (Phase 6)**: Depends on Phase 3 (needs data refresh cycle to write snapshot); US2/US3 independent
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P1)**: After Phase 2 — no story dependencies
- **US2 (P2)**: After US1 — reuses `TVShell` built in US1
- **US3 (P3)**: After US1 — extends `TVShell`; after US2 recommended (navigation needs all panels)
- **US4 (P4)**: After US1 — uses the refresh cycle; fully independent of US2/US3

### Within Each User Story

- Contract tests MUST be written and confirmed FAILING before implementation (Constitution §II)
- Models before services
- Services before ViewModels
- ViewModels before panel views
- Panel views before UI tests

### Parallel Opportunities

- T006, T007, T008, T009 can all run in parallel (different files)
- T010, T011 (contract tests) can run in parallel
- T012, T013, T015 can run in parallel (different files)
- T021, T022, T023, T024 (detail views) can run in parallel
- T035, T036, T038, T039 (polish validation) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Write contract tests + mock in parallel (RED phase):
Task T010: "Write TVCalendarServiceTests in SonasTests/TVCalendarServiceTests.swift"
Task T011: "Write TVSpotifyReadServiceTests in SonasTests/TVSpotifyReadServiceTests.swift"
Task T011a: "Create TVSpotifyReadServiceMock in Sonas/Shared/Mocks/TVSpotifyReadServiceMock.swift"

# Implement device-auth building blocks in parallel:
Task T012: "Implement TVDeviceAuthFlow in Sonas/Platform/TV/TVDeviceAuthFlow.swift"
Task T012a: "Write TVDeviceAuthFlowTests in SonasTests/TVDeviceAuthFlowTests.swift"
Task T013: "Implement TVDeviceAuthView in Sonas/Platform/TV/TVDeviceAuthView.swift"
Task T015: "Implement TVSpotifyReadService in Sonas/Platform/TV/TVSpotifyReadService.swift"
```

## Parallel Example: User Story 2

```bash
# Implement detail views in parallel (all different sub-views in TVPanelDetailView.swift):
Task T021: "Full-screen weather detail sub-view"
Task T022: "Full-screen calendar detail sub-view"
Task T023: "Full-screen location detail sub-view"
Task T024: "Full-screen photo detail sub-view"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (targets build cleanly)
2. Complete Phase 2: Foundational (platform guards pass)
3. Write contract tests (T010, T011) — confirm FAIL
4. Implement services (T012–T015) — confirm contract tests PASS
5. Wire TVShell (T016–T017) — all panels show live data
6. **STOP and VALIDATE**: Launch on tvOS Simulator, confirm all panels show non-fixture data
7. Demo US1 independently before adding navigation

### Incremental Delivery

1. Setup + Foundational → project builds for tvOS
2. US1 → live data on dashboard → Demo (MVP!)
3. US2 → remote navigation → Demo
4. US3 → full panel coverage + slideshow → Demo
5. US4 → Top Shelf → Demo (requires home-screen placement)
6. Polish → performance verified, ready to ship

### Parallel Team Strategy

With multiple developers after Phase 2:

- Developer A: US1 (services + TVShell wiring)
- Developer B: US4 (Top Shelf extension — fully independent)
- After US1: Developer A continues US2, Developer B continues with Polish

---

## Notes

- [P] tasks = different files, no shared state dependencies
- [Story] label maps task to user story for traceability
- Constitution §II: all contract tests MUST fail before implementation begins
- Commit after each task or logical group
- Stop at each Phase checkpoint to validate independently
- `xcodegen generate` required after any `project.yml` changes (T001–T003, T031)
- Performance baselines (T037) must be recorded before the feature is considered done (SC-004)
