# Tasks: macOS Native Support

**Input**: Design documents from `specs/003-macos-native-support/` **Prerequisites**: plan.md ✅, spec.md ✅,
research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Contract tests for `MacNotificationService` and UI tests for all 5 user stories are included per the
implementation plan (Constitution §II: Test-First).

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task serves (US1–US5)
- Exact file paths included in every description

---

## Phase 1: Setup (Scaffold)

**Purpose**: Build compiles green for `MacSonas` target; all test files exist and fail.

- [x] T001 Create `MacSonas/` directory with placeholder `Assets.xcassets` (all required macOS icon sizes, placeholder
      image) parallel to `WatchSonas/` and `TVSonas/`
- [x] T002 Create `MacSonas/Info.plist` with `CFBundleDisplayName`, `NSLocationWhenInUseUsageDescription`,
      `NSPhotoLibraryUsageDescription`, `GIDClientID`, `LSApplicationCategoryType`, `LSUIElement: false`
- [x] T003 [P] Update `project.yml` — add `MacSonas` target (platform: macOS, deploymentTarget: 15.0, sources:
      `Sonas/Platform/macOS` + `Sonas/Features` + `Sonas/Shared`, dependencies: GoogleSignIn only, info path:
      `MacSonas/Info.plist`) per `plan.md` XcodeGen definition
- [x] T004 [P] Update `project.yml` — set `SUPPORTS_MACCATALYST: NO` in `targets.Sonas.settings.base` (removes Catalyst
      build from iOS target per FR-001 clarification)
- [x] T005 Create stub files in `Sonas/Platform/macOS/`: `MacSonasApp.swift`, `MacShell.swift`, `MacSidebarView.swift`,
      `MacMenuBarPopoverView.swift`, `MacSonasCommands.swift`, `MacNotificationService.swift`, `MenuBarState.swift` —
      each with a minimal compilable stub (`struct Placeholder {}` or equivalent `@main` stub)
- [x] T006 Run `xcodegen generate`, open Xcode, confirm `MacSonas` scheme builds without errors and `Sonas` (iOS) scheme
      still builds without errors
- [x] T007 [P] Create `SonasTests/MacNotificationServiceTests.swift` with 5 failing contract test stubs (one per test in
      `contracts/MacNotificationService.md`): `test_register_requestsAuthorisation`,
      `test_register_registersCategories`, `test_scheduleLocationArrival_createsRequest`,
      `test_didReceiveLocationAction_navigatesToLocation`, `test_didReceiveCalendarAction_navigatesToCalendar` — all
      must fail at this point
- [x] T008 [P] Create `MacSonasUITests/` directory and target in `project.yml` with skeleton test files:
      `MacDashboardUITests.swift`, `MacMenuBarUITests.swift`, `MacKeyboardShortcutUITests.swift`,
      `MacNotificationUITests.swift`, `MacMultiWindowUITests.swift` — one failing test placeholder per file

**Checkpoint**: `MacSonas` builds green; all test files exist; `MacNotificationServiceTests` has 5 failing stubs.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core app lifecycle and shared notification names — must complete before any user story.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

- [x] T009 Add `.sonasWindowOpenRequested` `Notification.Name` extension to
      `Sonas/Shared/Extensions/Notification+Sonas.swift` (used by `MacNotificationService` delegate to trigger window
      open + navigation)
- [x] T010 Implement `MacSonasApp.swift` (`Sonas/Platform/macOS/MacSonasApp.swift`) as the `@main` entry point with: a
      `WindowGroup(id: "main")` containing a placeholder `Text("Loading…")`, `.commands {}` stub, and a `MenuBarExtra`
      stub — app must launch to menu bar + window on macOS

**Checkpoint**: `MacSonas` app launches on macOS, shows a window and a menu bar icon (stub content). Foundation ready —
user story implementation can begin.

---

## Phase 3: User Story 1 - Desktop Family Dashboard (Priority: P1) 🎯 MVP

**Goal**: Native macOS window with sidebar, all sections navigable, window state restored across launches.

**Independent Test**: Launch `MacSonas`, sign in, verify all 7 sidebar sections are present and navigable; resize window
and confirm panels reflow; quit and relaunch and confirm section + size are restored.

- [x] T011 [US1] Implement `MacSidebarView.swift` (`Sonas/Platform/macOS/MacSidebarView.swift`):
      `List(selection: $selection)` over `AppSection.allCases` (excluding `.settings`), `.listStyle(.sidebar)`,
      `.navigationTitle("Sonas")`, Settings button in `.safeAreaInset(edge: .bottom)` using `.sheet` (same pattern as
      `SidebarView` in `Sonas/Platform/iPad/SidebarView.swift`)
- [x] T012 [US1] Implement `MacShell.swift` (`Sonas/Platform/macOS/MacShell.swift`): `NavigationSplitView` with
      `MacSidebarView` (sidebar column) and `detailView(for:)` (detail column); create all ViewModels as `@State` via
      `.makeDefault()` factories; add `@SceneStorage("mac.selectedSection") var selectedSection: AppSection?`; set
      `.dashboard` default on `.onAppear` if nil; listen for `.sonasNavigationRequested` via `.onReceive`
- [x] T013 [US1] Wire all `AppSection` cases in `MacShell.detailView(for:)` to their feature panel views (same mapping
      as `IPadShell.detailView(for:)` in `Sonas/Platform/iPad/IPadShell.swift`) in `Sonas/Platform/macOS/MacShell.swift`
- [x] T014 [US1] Add macOS toolbar to `MacShell` (`Sonas/Platform/macOS/MacShell.swift`): `.toolbar` modifier with a
      Refresh `ToolbarItem` that posts `.sonasRefreshRequested`; set `.navigationTitle` per selected section
- [x] T015 [US1] Update `MacSonasApp.swift` (`Sonas/Platform/macOS/MacSonasApp.swift`) `WindowGroup` body to use
      `MacShell()`; add `.defaultSize(width: 1200, height: 800)`
- [x] T016 [US1] Write `MacDashboardUITests.swift` (`MacSonasUITests/MacDashboardUITests.swift`): implement acceptance
      tests for US1 scenarios 1–4 (sidebar present with all 7 sections, window resize reflows panels, section selection
      updates detail, window state restored after relaunch) — all must pass

**Checkpoint**: US1 fully functional. Sidebar navigates all sections. Window restores state across relaunches.

---

## Phase 4: User Story 2 - Menu Bar Quick-Glance (Priority: P2)

**Goal**: Persistent menu bar icon; clicking opens a popover with family locations, next event, and weather.

**Independent Test**: With no main window open, click the menu bar icon — popover shows family location names, next
event, and current weather within 300ms; "Open Sonas" button brings the main window to front.

- [x] T017 [US2] Implement `MenuBarState.swift` (`Sonas/Platform/macOS/MenuBarState.swift`):
      `@Observable final class MenuBarState` with fields `familyLocations: [FamilyMember]`, `nextEvent: CalendarEvent?`,
      `weatherSummary: WeatherSnapshot?`, `lastUpdated: Date?`, `isOffline: Bool`; add `refresh()` async method that
      reads from `CacheService.shared` (`.loadLocations()`, `.loadEvents()`, `.loadWeather()`); compute `nextEvent` as
      first event with `startDate > Date.now` within 24 hours
- [x] T018 [US2] Implement `MacMenuBarPopoverView.swift` (`Sonas/Platform/macOS/MacMenuBarPopoverView.swift`): compact
      SwiftUI view showing family location names (section header + list), next event (title + time), and weather summary
      (condition + temperature); "Open Sonas" button calls `openWindow(id: "main")` via `@Environment(\.openWindow)`;
      read data from `@Environment(MenuBarState.self)` (or pass as parameter); show "No data yet" placeholder in each
      section if data is nil; frame width fixed at 280pt
- [x] T019 [US2] Wire `MenuBarExtra` in `MacSonasApp.swift` (`Sonas/Platform/macOS/MacSonasApp.swift`):
      `MenuBarExtra("Sonas", systemImage: "house.fill") { MacMenuBarPopoverView() } .menuBarExtraStyle(.window)`; inject
      `MenuBarState` into the environment; call `menuBarState.refresh()` on popover open via `.task` in
      `MacMenuBarPopoverView`
- [x] T020 [US2] Create `MenuBarState` instance in `MacSonasApp` and inject via `.environment(menuBarState)` on both
      `WindowGroup` and `MenuBarExtra` scenes in `Sonas/Platform/macOS/MacSonasApp.swift` so main window and popover
      share the same state object
- [x] T021 [US2] Write `MacMenuBarUITests.swift` (`MacSonasUITests/MacMenuBarUITests.swift`): acceptance tests for US2
      scenarios 1–4 (menu bar icon visible, popover opens with correct sections, "Open Sonas" opens window, app stays
      alive after closing window) — all must pass; measure popover open time against SC-002 (≤300ms)

**Checkpoint**: US2 fully functional. Menu bar always visible. Popover shows cached family status ≤300ms.

---

## Phase 5: User Story 3 - Native macOS Menus and Keyboard Shortcuts (Priority: P3)

**Goal**: Full macOS menu bar (File/View/Window/Help) and all keyboard shortcuts functional.

**Independent Test**: With Sonas as the active application, verify all menus appear in the menu bar; press Cmd+1 through
Cmd+7 and verify section changes; press Cmd+R and verify refresh fires; press Cmd+W and verify window closes while app
stays running.

- [x] T022 [US3] Implement `MacSonasCommands.swift` (`Sonas/Platform/macOS/MacSonasCommands.swift`):
      `CommandGroup(replacing: .newItem)` with "New Window" button calling
      `NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)` or
      `@Environment(\.openWindow) approach;     `CommandGroup(replacing:
      .appSettings)`with "Settings…" (Cmd+,) posting`.sonasSettingsRequested`;     `CommandGroup(after:
      .pasteboard)`with "Refresh All" (Cmd+R) posting`.sonasRefreshRequested`
- [x] T023 [US3] Add `CommandMenu("View")` to `MacSonasCommands` (`Sonas/Platform/macOS/MacSonasCommands.swift`): one
      `Button` per `AppSection` (excluding `.settings`) that posts `.sonasNavigationRequested` with the section; each
      button uses `section.keyboardShortcut` (Cmd+1–7 already defined on `AppSection`)
- [x] T024 [US3] Wire `.commands { MacSonasCommands() }` on the `WindowGroup` scene in `MacSonasApp.swift`
      (`Sonas/Platform/macOS/MacSonasApp.swift`), replacing the stub
- [x] T025 [US3] Write `MacKeyboardShortcutUITests.swift` (`MacSonasUITests/MacKeyboardShortcutUITests.swift`):
      acceptance tests for US3 scenarios 1–4 (all menus present, Cmd+R fires refresh, Cmd+1–7 change section, Cmd+W
      closes window without quitting app) — all must pass; SC-004 verified

**Checkpoint**: US3 fully functional. All macOS menus present. All keyboard shortcuts fire correct actions.

---

## Phase 6: User Story 4 - macOS System Notifications (Priority: P4)

**Goal**: Location arrival and calendar event notifications with actionable buttons that deep-link to sections.

**Independent Test**: Trigger a simulated location arrival — a macOS notification appears with "Show on Map" button;
clicking it opens Sonas and navigates to Location; same for a calendar reminder with "Open Calendar".

- [x] T026 [US4] Implement `MacNotificationService.swift` (`Sonas/Platform/macOS/MacNotificationService.swift`):
      `protocol MacNotificationServiceProtocol` with `register()`, `scheduleLocationArrival(memberName:placeName:)`,
      `scheduleCalendarReminder(eventTitle:startDate:)`;
      `final class MacNotificationService: MacNotificationServiceProtocol` backed by
      `UNUserNotificationCenter.current()`; register two `UNNotificationCategory` instances (IDs:
      `com.sonas.location.arrival`, `com.sonas.calendar.upcoming`) each with one `UNNotificationAction` (`show-map` /
      `open-calendar`); request `.alert` + `.sound` authorisation
- [x] T027 [US4] Implement `UNUserNotificationCenterDelegate` conformance in `MacNotificationService`
      (`Sonas/Platform/macOS/MacNotificationService.swift`): on `didReceive(_:withCompletionHandler:)` extract `section`
      from `userInfo`, map to `AppSection`, post `.sonasNavigationRequested` with that section, call
      `NSApplication.shared.activate(ignoringOtherApps: true)`, call `openWindow(id: "main")` via stored closure
- [x] T028 [US4] Call `Task { await MacNotificationService.shared.register() }` in `MacSonasApp.init()`
      (`Sonas/Platform/macOS/MacSonasApp.swift`); set
      `UNUserNotificationCenter.current().delegate = MacNotificationService.shared` at the same time
- [x] T029 [US4] Extend `LocationViewModel` with `#if os(macOS)` block
      (`Sonas/Features/Location/LocationViewModel.swift`): detect when a family member's location changes to a new named
      place and call `MacNotificationService.shared.scheduleLocationArrival(memberName:placeName:)`
- [x] T030 [US4] Extend `EventsViewModel` (or `DashboardViewModel`) with `#if os(macOS)` block: after loading events,
      schedule a 15-minute-before reminder for each upcoming event via
      `MacNotificationService.shared.scheduleCalendarReminder(eventTitle:startDate:)`
- [x] T031 [US4] Complete all 5 failing stubs in `SonasTests/MacNotificationServiceTests.swift` so they pass: inject a
      mock `UNUserNotificationCenter` and verify registration, scheduling, and delegate behaviour per the 5 contract
      tests in `contracts/MacNotificationService.md`
- [x] T032 [US4] Write `MacNotificationUITests.swift` (`MacSonasUITests/MacNotificationUITests.swift`): acceptance tests
      for US4 scenarios 1–4 (location notification appears with action, calendar notification appears with action,
      action navigates to correct section, notifications grouped in Notification Centre) — all must pass; SC-003
      verified

**Checkpoint**: US4 fully functional. All 5 contract tests pass. Notifications fire with action buttons that deep-link
to the correct sections.

---

## Phase 7: User Story 5 - Multi-Window Workspace (Priority: P5)

**Goal**: Multiple independent Sonas windows, each with its own section selection and state restoration.

**Independent Test**: Open two windows via File > New Window; navigate each to a different section; verify both update
independently on refresh; drag one window to a different Space and confirm independence.

- [x] T033 [US5] Add `.windowResizability(.contentSize)` and `defaultSize(width: 1200, height: 800)` to the
      `WindowGroup` in `MacSonasApp.swift` (`Sonas/Platform/macOS/MacSonasApp.swift`) if not already present; confirm
      multiple windows can be opened via File > New Window
- [x] T034 [US5] Verify `@SceneStorage("mac.selectedSection")` is independent per window: open two windows, navigate
      each to a different section, confirm selections do not bleed between windows; document finding in a comment in
      `MacShell.swift` (`Sonas/Platform/macOS/MacShell.swift`)
- [x] T035 [US5] Write `MacMultiWindowUITests.swift` (`MacSonasUITests/MacMultiWindowUITests.swift`): acceptance tests
      for US5 scenarios 1–4 (second window opens independently, both windows update on refresh, window moves to
      different Space, Stage Manager restoration) — all must pass; SC-005 (≤500ms new window) verified

**Checkpoint**: US5 fully functional. Multiple independent windows supported with per-window section state.

---

## Phase 8: Offline Graceful Degradation (FR-017 / SC-008)

**Purpose**: All sections show cached data with "last updated" indicator when the device is offline.

- [x] T036 Implement network reachability check in `MenuBarState.swift` (`Sonas/Platform/macOS/MenuBarState.swift`): use
      `NWPathMonitor` (Network framework) to set `isOffline: Bool`; on network loss, retain existing cached data rather
      than clearing it; update `lastUpdated` only on successful refreshes
- [x] T037 Add offline banner to `MacShell` detail area (`Sonas/Platform/macOS/MacShell.swift`): when
      `menuBarState.isOffline` is true, show a `.safeAreaInset(edge: .top)` banner with "Offline — last updated
      [relative time]" across all sections
- [x] T038 Show "Last updated [relative time]" footer in `MacMenuBarPopoverView`
      (`Sonas/Platform/macOS/MacMenuBarPopoverView.swift`) when `menuBarState.isOffline` is true, below the weather
      section
- [x] T039 Manual validation: disable Wi-Fi, launch `MacSonas`, verify all sections display cached data within 1s
      (SC-008) and the offline banner / "last updated" indicator appears; document result

**Checkpoint**: All sections gracefully degrade to cached data when offline, with visible "last updated" indicator.

---

## Phase 9: Polish & App Store Prep

**Purpose**: Final quality gates before App Store submission.

- [x] T040 [P] Replace placeholder app icon in `MacSonas/Assets.xcassets` with final production macOS app icon (provide
      all required sizes: 16, 32, 64, 128, 256, 512, 1024pt)
- [x] T041 [P] Verify SC-006: run a full clean build of `MacSonas` scheme and confirm zero Catalyst-era warnings in the
      Xcode build log; confirm `SUPPORTS_MACCATALYST: NO` is effective on the `Sonas` iOS scheme
- [x] T042 [P] Run Instruments Allocations on `MacSonas`: open and close 5 windows; verify no per-window retain cycles
      or growing heap; document baseline memory reading in this task's completion note
- [x] T043 Add `MacSonas` scheme to GitHub Actions CI (`.github/workflows/ci.yml` or equivalent): build + test step
      targeting `platform=macOS`
- [x] T044 Prepare Mac App Store submission in App Store Connect: create new macOS app record (separate from iOS
      `Sonas`), upload first build, fill in privacy nutrition labels (location, photos, calendar), set category to
      Lifestyle

**Checkpoint**: All polish gates passed. App ready for Mac App Store submission.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundation)**: Depends on Phase 1 ⚠️ Blocks all user stories
- **Phase 3 (US1)**: Depends on Phase 2
- **Phase 4 (US2)**: Depends on Phase 2 (independent of US1)
- **Phase 5 (US3)**: Depends on Phase 2 (independent of US1/US2)
- **Phase 6 (US4)**: Depends on Phase 3 (needs MacShell for notification deep-link) and Phase 2
- **Phase 7 (US5)**: Depends on Phase 3 (needs MacShell + WindowGroup wired)
- **Phase 8 (Offline)**: Depends on Phase 4 (MenuBarState needed for offline indicator)
- **Phase 9 (Polish)**: Depends on all prior phases

### User Story Dependencies

| Story    | Depends On                   | Can Start After                 |
| -------- | ---------------------------- | ------------------------------- |
| US1 (P1) | Foundation                   | Phase 2                         |
| US2 (P2) | Foundation                   | Phase 2 (parallel with US1)     |
| US3 (P3) | Foundation                   | Phase 2 (parallel with US1/US2) |
| US4 (P4) | US1 (MacShell for deep-link) | Phase 3                         |
| US5 (P5) | US1 (WindowGroup wired)      | Phase 3                         |

### Within Each Phase

- Test stubs: written first (must fail before implementation)
- Models/state before views
- Views before app wiring
- App wiring before acceptance test completion

---

## Parallel Opportunities

### Phase 1

```
T001 (create MacSonas/ dir)  →  T005 (create stubs)  →  T006 (xcodegen)
T003 (project.yml MacSonas)  ↗
T004 (project.yml Catalyst)  ↗
T007 (test stubs)            ← parallel with T003/T004
T008 (UITest target)         ← parallel with T007
```

### After Phase 2 (Foundation complete)

```
Developer A → Phase 3 (US1: window + shell)
Developer B → Phase 4 (US2: menu bar)
Developer C → Phase 5 (US3: menus/shortcuts)
```

### Phase 9 (Polish)

```
T040, T041, T042 all parallel (different concerns, no file conflicts)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001–T008)
2. Phase 2: Foundation (T009–T010)
3. Phase 3: US1 Desktop Dashboard (T011–T016)
4. **STOP and VALIDATE**: All 7 sections navigable, window state restores → ship MVP

### Incremental Delivery

- MVP: Phase 1–3 → Native window with full dashboard (replaces Catalyst)
- +US2: Phase 4 → Add menu bar extra (ambient family status)
- +US3: Phase 5 → Add macOS menus + all keyboard shortcuts
- +US4: Phase 6 → Add Notification Centre integration
- +US5: Phase 7 → Add multi-window support
- +Offline: Phase 8 → Graceful offline degradation
- Finish: Phase 9 → Polish + App Store submission

### Parallel Team Strategy

With two developers after Phase 2:

- Dev A: Phase 3 (US1 window)
- Dev B: Phase 4 (US2 menu bar) + Phase 5 (US3 shortcuts) in sequence
- Both merge → Dev A: Phase 6 (US4 notifications), Dev B: Phase 7 (US5 multi-window)

---

## Notes

- `[P]` = different files, no shared dependencies — safe to run in parallel
- `[US#]` = maps task to specific user story for traceability
- Contract tests in T031 must fail before T026/T027 are implemented (Constitution §II)
- UI test acceptance criteria in T016/T021/T025/T032/T035 must pass before each phase's checkpoint
- `xcodegen generate` must be re-run after any `project.yml` change (T003, T004, T008)
- Each `#if os(macOS)` block in shared files (T029, T030) must not affect iOS compilation
