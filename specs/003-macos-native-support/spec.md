# Feature Specification: macOS Native Support

**Feature Branch**: `003-macos-native-support`  
**Created**: 2026-04-28  
**Status**: Draft  
**Input**: User description: "Sonas should fully support macOS capabilities, rather than just being an iOS application
viewed on a Mac."

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Desktop Family Dashboard (Priority: P1)

A family member opens Sonas on their Mac and is greeted by a native macOS experience: a sidebar for navigation, a
resizable multi-column dashboard, a native toolbar with standard macOS controls, and all family panels — location,
weather, calendar, tasks, photos, and music — filling the screen naturally at desktop scale.

**Why this priority**: The core value of Sonas is the family command-centre dashboard. A native macOS window experience
is the baseline all other macOS capabilities build on. Users switching from the iOS/Catalyst version should immediately
notice the difference in polish.

**Independent Test**: Can be fully tested by launching the MacSonas app target, signing in, and verifying the dashboard
renders with a native sidebar, resizable columns, and standard macOS window chrome (toolbar, title bar, red/amber/green
buttons).

**Acceptance Scenarios**:

1. **Given** the user launches Sonas on macOS, **When** the app opens, **Then** it displays a native macOS window with a
   sidebar listing all sections (Dashboard, Location, Calendar, Weather, Tasks, Photos, Music), a toolbar with a refresh
   button, and a main content area showing the family dashboard.
2. **Given** the user is on the Dashboard, **When** they resize the window wider, **Then** additional dashboard columns
   appear and panels reflow to fill the available width.
3. **Given** the user selects a section in the sidebar, **When** the selection changes, **Then** the main content area
   transitions immediately to that section's full-screen macOS layout.
4. **Given** the user closes and reopens the app, **When** it launches, **Then** prior state is restored: if a window
   was open when the app last quit, it reopens at the same size and section; if no window was open (menu-bar-only), the
   app returns to the menu bar without opening a window. On the very first launch, a window always opens.

---

### User Story 2 - Menu Bar Quick-Glance (Priority: P2)

A family member working at their Mac can glance at a compact status summary in the menu bar — seeing where family
members are, the next upcoming event, and current weather — without switching away from what they are doing. Clicking
the menu bar icon expands a popover with the most important at-a-glance details.

**Why this priority**: This is the flagship macOS-native capability that is simply not possible on iOS. It lets Sonas
become part of the Mac's ambient awareness layer, providing passive value all day even when the full app window is
hidden.

**Independent Test**: Can be tested by verifying a Sonas icon appears in the macOS menu bar, clicking it opens a popover
showing family location names, the next calendar event, and current weather, and that the popover dismisses on
click-outside.

**Acceptance Scenarios**:

1. **Given** Sonas is running on macOS, **When** the user looks at the menu bar, **Then** a Sonas status icon is visible
   and remains present for as long as the app is running.
2. **Given** the user clicks the menu bar icon, **When** the popover opens, **Then** it shows a compact list of family
   member location names, the next calendar event with time, and the current weather summary — all without opening the
   full app window.
3. **Given** the user clicks "Open Sonas" inside the popover, **When** the action is triggered, **Then** the main Sonas
   window comes to the front (or is created if not already open).
4. **Given** the user does not have the main window open, **When** the menu bar popover is dismissed, **Then** Sonas
   continues running in the background, the menu bar icon remains visible, and the Dock icon remains visible.

---

### User Story 3 - Native macOS Menus and Keyboard Shortcuts (Priority: P3)

A keyboard-focused Mac user can navigate Sonas entirely via standard macOS menus (File, View, Window, Help) and keyboard
shortcuts — refreshing data, switching sections, and triggering common actions — without needing to touch the trackpad.

**Why this priority**: Mac users expect every app to respect the global menu bar and standard keyboard shortcuts. This
transforms Sonas from a touch-adapted app into a first-class Mac citizen and enables power-user workflows.

**Independent Test**: Can be tested by verifying a complete menu bar appears with File, View, Window, and Help menus,
and that defined keyboard shortcuts (e.g., Cmd+R to refresh, Cmd+1–7 to switch sections) produce the expected actions.

**Acceptance Scenarios**:

1. **Given** Sonas is the active application, **When** the user inspects the menu bar, **Then** menus for File (New
   Window, Close Window, Quit), View (section navigation, Show/Hide Sidebar), Window (standard macOS entries), and Help
   are present.
2. **Given** the user presses Cmd+R, **When** the shortcut fires, **Then** the currently visible section refreshes its
   data.
3. **Given** the user presses Cmd+1 through Cmd+7, **When** each shortcut fires, **Then** the corresponding section
   (Dashboard, Location, Calendar, Weather, Tasks, Photos, Music) is selected in the sidebar.
4. **Given** the user presses Cmd+W, **When** the shortcut fires, **Then** the front window closes but the app remains
   running with the menu bar icon visible.

---

### User Story 4 - macOS System Notifications (Priority: P4)

A family member receives macOS Notification Centre alerts for time-sensitive family events — a family member arriving
home, an upcoming shared calendar event — with actionable buttons that let them respond without opening the app.

**Why this priority**: Persistent, actionable macOS notifications are a qualitatively different experience from iOS
banners. They support action buttons, appear in Notification Centre, and survive across app restarts.

**Independent Test**: Can be tested by triggering a simulated location arrival event and verifying a macOS notification
appears with correct text and at least one action button; clicking the button should navigate to the relevant section.

**Acceptance Scenarios**:

1. **Given** a family member's location changes to a known place (e.g., "Home"), **When** the update is received,
   **Then** a macOS notification appears reading "[Name] arrived at [Place]" with a "Show on Map" action button.
2. **Given** a shared calendar event is 15 minutes away, **When** the reminder fires, **Then** a macOS notification
   appears with the event title and time, and an "Open Calendar" action button.
3. **Given** the user clicks an action button in a notification, **When** the action is triggered, **Then** the Sonas
   main window opens and navigates directly to the relevant section.
4. **Given** the user has not dismissed notifications, **When** they open Notification Centre, **Then** prior Sonas
   notifications are grouped under the Sonas app name.

---

### User Story 5 - Multi-Window Workspace (Priority: P5)

A power user can open multiple Sonas sections as independent windows — for example, keeping the family location map
pinned on one Space while the Calendar occupies another — taking full advantage of macOS window management, Spaces, and
Stage Manager.

**Why this priority**: Multi-window support enables the ambient-display use case (a second monitor always showing the
family map) and is expected by macOS users who rely on Spaces and Stage Manager for task separation.

**Independent Test**: Can be tested by using File > New Window to open a second window, navigating it to a different
section, and confirming both windows show correct independent content simultaneously.

**Acceptance Scenarios**:

1. **Given** the user chooses File > New Window, **When** the new window opens, **Then** it shows the dashboard and
   operates independently from the first window.
2. **Given** two windows are open on different sections, **When** data refreshes, **Then** both windows update their
   content independently.
3. **Given** the user drags a Sonas window to a different Space, **When** they switch Spaces, **Then** the window is
   present on its assigned Space and the other window stays on its original Space.
4. **Given** Sonas windows are open in Stage Manager, **When** the user switches between window sets, **Then** Sonas
   windows restore to their prior size and selected section without re-fetching data.

---

### Edge Cases

- When Sonas is launched with no internet connection, all sections display the most recently cached data with a "last
  updated" timestamp; no section shows a blank state or indefinite spinner.
- How does the menu bar icon behave if the user's macOS settings hide third-party menu bar extras in the Control Centre
  overflow area?
- What happens when the SpotifyiOS SDK (iOS-only) is unavailable on macOS — does the Music section show read-only
  listening status or is it hidden entirely?
- How does Google Sign-In's OAuth redirect behave on macOS where there is no mobile deep-link handler — does it fall
  back gracefully to a system browser flow?
- What happens to background location updates on macOS, where macOS does not support the iOS "always" authorization
  model?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: Sonas MUST ship a dedicated native macOS application target built from the same shared codebase, available
  from the Mac App Store. The existing Mac Catalyst build MUST be removed; the native macOS app becomes the sole macOS
  distribution.
- **FR-002**: The macOS app MUST display a persistent menu bar status item (icon) at all times while the app is running.
- **FR-003**: Clicking the menu bar status item MUST open a compact popover showing: family member location names, the
  next shared calendar event with time, and current weather for the household location.
- **FR-004**: The macOS app MUST present a sidebar-based layout with a persistent sidebar listing all sections:
  Dashboard, Location, Calendar, Weather, Tasks, Photos, and Music.
- **FR-005**: The main window MUST use standard macOS window chrome: title bar, toolbar, and macOS window controls.
- **FR-006**: The app MUST provide a macOS menu bar with at minimum: File (New Window, Close Window, Quit), View
  (section navigation, Show/Hide Sidebar), Window (standard macOS entries), and Help menus.
- **FR-007**: The app MUST support keyboard shortcuts: Cmd+R (refresh current section), Cmd+1–Cmd+7 (switch sections),
  Cmd+W (close front window), Cmd+, (open Settings).
- **FR-008**: The app MUST support opening multiple independent windows, each showing a separately navigable section.
- **FR-009**: On first launch, the app MUST open a window. On subsequent launches, the app MUST restore prior state: if
  a window was open at last quit, it reopens at the same size, position, and section; if no window was open
  (menu-bar-only mode), the app launches silently to the menu bar.
- **FR-010**: The app MUST deliver macOS Notification Centre alerts for family location arrivals/departures and upcoming
  shared calendar events, with action buttons that navigate to the relevant section.
- **FR-011**: Clicking a notification or its action button MUST bring the main window to front and navigate to the
  relevant section.
- **FR-012**: The Music section on macOS MUST display the currently playing track and artist in read-only mode; playback
  control is not required on macOS.
- **FR-013**: Google Sign-In on macOS MUST use the system browser for authentication, not a mobile-style in-app pop-up.
- **FR-014**: The app MUST request only macOS-appropriate location permissions and display a clear explanation of why
  location access is needed.
- **FR-015**: All existing iPhone and iPad functionality MUST remain unaffected by this change.
- **FR-016**: The Dock icon MUST remain visible at all times while the app is running, whether or not any window is
  open.
- **FR-017**: When the device has no internet connection, all sections (including the menu bar popover) MUST display the
  most recently cached data rather than an empty state or loading spinner, accompanied by a visible "last updated
  [time]" indicator.

### Key Entities

- **MacSonas App**: A dedicated native macOS application built from the same shared family dashboard logic as the iPhone
  and iPad apps, with macOS-specific navigation and chrome layered on top — analogous to how the Apple Watch and Apple
  TV companion apps are structured.
- **Menu Bar Extra**: A persistent macOS status item providing always-on quick-glance family status even when no app
  window is open.
- **macOS Platform Layer**: The set of macOS-specific screens, menus, and entry-point code that wraps the shared family
  dashboard logic — parallel to the existing iPad, Apple TV, and Apple Watch platform layers.
- **Multi-Window Scene**: Each open Sonas window operates independently with its own selected section and scroll
  position, all restorable after the app restarts.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Every feature available in the iOS app (location, weather, calendar, tasks, photos, music status) is
  accessible from the macOS app within 2 navigational steps from the dashboard.
- **SC-002**: The menu bar popover opens within 300ms of clicking the menu bar icon, with no visible loading spinner
  (data served from cache).
- **SC-003**: Family location and calendar notifications appear on macOS within the same time window as on iOS, with no
  additional delay introduced by the macOS target.
- **SC-004**: All 7 keyboard section shortcuts (Cmd+1–Cmd+7) and Cmd+R correctly trigger the expected actions across all
  sections.
- **SC-005**: Opening a second window takes under 500ms and shows correct section content without triggering a network
  request.
- **SC-006**: The macOS app passes Mac App Store review with no Catalyst-era compatibility warnings in the Xcode build
  log.
- **SC-007**: Launch state is restored correctly in 100% of tested scenarios: first launch opens a window; subsequent
  launches restore the prior window/menu-bar state.
- **SC-008**: When launched offline, every section (including the menu bar popover) displays cached content within 1
  second with a visible "last updated" timestamp; no section shows a blank state.

## Assumptions

- macOS deployment target is macOS 15 (Sequoia), consistent with the existing macOS target already configured in the
  project.
- Mac Catalyst support is removed from the iOS target as part of this feature; there is no transition period or parallel
  distribution.
- The Spotify mobile SDK used by the iOS app does not support macOS; the Music section on macOS will show read-only
  now-playing information (track and artist) if available, or an "Open Spotify on your iPhone" prompt if not.
- Location, weather, calendar, photos, and family sync services all have macOS-native counterparts; no additional
  libraries are needed beyond those already used on iOS.
- Google Sign-In supports macOS through a standard browser-based OAuth flow; no additional authentication library is
  required.
- The macOS app will be distributed via the Mac App Store, consistent with the iOS distribution model.
- Background location updates on macOS use a "while the app is running" model rather than the iOS always-on background
  model; the menu bar extra keeps the app active so location refreshes throughout the day.
- All shared family dashboard logic (data models, service calls, business rules) will be reused as-is on macOS; only the
  macOS-specific navigation shell and menu bar extra are new.
- The macOS app functions as a standalone family hub — no paired iPhone is required — signed into the same shared family
  data container as the iOS app.
- VoiceOver and Full Keyboard Access compliance are out of scope for v1 and will be addressed in a dedicated
  accessibility spec.

## Clarifications

### Session 2026-04-28

- Q: Should this feature replace Mac Catalyst entirely, or coexist with it? → A: Remove Catalyst entirely; the native
  macOS app becomes the sole macOS distribution. Existing Catalyst users receive the native app on update.
- Q: What is the initial launch behaviour when a user opens MacSonas? → A: On first launch open a window; on subsequent
  launches restore prior state (window open or menu-bar-only).
- Q: When Sonas has no open windows and is running only as a menu bar extra, should the Dock icon be visible? → A: Dock
  icon always visible, whether or not a window is open.
- Q: Should offline graceful degradation be a formal requirement? → A: Yes — all sections including the menu bar popover
  must display cached data when offline, with a visible "last updated" indicator.
- Q: For the v1 macOS release, what is the accessibility requirement scope? → A: Deferred entirely to a future spec; not
  in scope for v1.
