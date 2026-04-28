# Feature Specification: tvOS Full Support

**Feature Branch**: `004-tvos-support`  
**Created**: 2026-04-28  
**Status**: Draft  
**Input**: User description: "Sonas should fully support tvOS capabilities."

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Live Family Dashboard on the TV (Priority: P1)

A family member turns on their Apple TV and opens Sonas. The TV screen shows a full-screen family command-centre with
live data: the current time and date, real weather conditions, upcoming calendar events pulled from the family calendar,
family member locations, a photo slideshow from the shared album, and active Spotify Jam status. All panels update
automatically without any interaction, giving the household a living ambient display of family life.

**Why this priority**: The TV is a shared, always-visible screen in the home. Replacing the current hardcoded fixture
data with live data is the core gap between the current stub and a fully functioning tvOS app. Every other tvOS
capability builds on this real-data foundation.

**Independent Test**: Can be fully tested by launching the TVSonas app on Apple TV, granting necessary permissions, and
confirming all dashboard panels display live data that matches current conditions (weather, calendar events, family
locations, photos, Spotify).

**Acceptance Scenarios**:

1. **Given** the user launches Sonas on Apple TV, **When** the dashboard loads, **Then** all panels display live data
   drawn from real family services — not static fixtures or placeholder values.
2. **Given** the dashboard is open, **When** a calendar event starts within the next hour, **Then** the events panel
   updates to highlight the imminent event without any user interaction.
3. **Given** the family shared photo album has been updated since the last launch, **When** the photos panel is
   displayed, **Then** it shows the newly added photos.
4. **Given** a family member's location changes, **When** the location panel is displayed, **Then** it reflects the
   updated position within the same interval used on iOS.
5. **Given** Sonas has been open on the TV for an extended period, **When** data refresh intervals elapse, **Then** all
   panels update silently in the background without visual disruption.

---

### User Story 2 - Remote-Controlled Navigation (Priority: P2)

A family member sitting on the couch uses the Apple TV remote to navigate Sonas. They can move focus between panels on
the dashboard, select a panel to expand it to full-screen detail, and press Back to return to the overview. Focus moves
naturally between panels following tvOS focus engine conventions, and the selected item is always clearly highlighted.

**Why this priority**: tvOS apps must be navigable entirely by remote. Without proper focus engine support and panel
navigation, the app cannot be used at all in the lean-back context of a living room TV.

**Independent Test**: Can be fully tested by connecting an Apple TV remote (physical or Simulator) and confirming that
arrow-key navigation moves focus between panels, selecting a panel expands it, and the Back button collapses it back to
the dashboard grid.

**Acceptance Scenarios**:

1. **Given** the dashboard is displayed, **When** the user presses the directional pad on the remote, **Then** focus
   moves to the adjacent panel in the corresponding direction, and the focused panel is visually highlighted.
2. **Given** focus is on a panel, **When** the user presses Select (click), **Then** the panel expands to a full-screen
   detail view appropriate for that panel type.
3. **Given** a full-screen panel detail is shown, **When** the user presses Back on the remote, **Then** the dashboard
   grid returns with focus restored to the previously selected panel.
4. **Given** the user navigates to the Photos panel detail, **When** it expands, **Then** it shows a full-screen photo
   with navigation arrows to browse through recent family photos.
5. **Given** the user navigates to the Location panel detail, **When** it expands, **Then** it shows a full-screen map
   with family member pins.

---

### User Story 3 - Full Panel Coverage Matching iOS (Priority: P3)

The tvOS dashboard displays the same set of family information panels available on iOS — location map, weather, upcoming
calendar events, family tasks, photo slideshow, and Spotify Jam — laid out in a way that is optimal for a large
television screen rather than scaled up from a phone layout.

**Why this priority**: The current tvOS stub only shows Clock, Weather, and Events panels. Extending coverage to all
panels brings tvOS to feature parity with the iOS app's information density and gives the TV screen its full value as a
shared family display.

**Independent Test**: Can be tested by launching the TVSonas app and confirming panels for Location, Weather, Calendar,
Tasks, Photos (auto-advancing slideshow), and Spotify Jam are all visible on the dashboard grid, each showing accurate
data.

**Acceptance Scenarios**:

1. **Given** the dashboard is displayed, **When** the user views it, **Then** panels for Location (family member map),
   Weather, Calendar events, Tasks, Photos (slideshow), and Spotify Jam are all present.
2. **Given** a family member is actively listening on Spotify Jam, **When** the Jam panel is shown, **Then** it displays
   the track name, artist, and album art scaled appropriately for the TV screen.
3. **Given** no Spotify Jam is active, **When** the Jam panel is shown, **Then** it displays a tasteful idle state
   rather than an error.
4. **Given** the screen is a 1080p or 4K TV, **When** the dashboard is displayed, **Then** all text is legible from a
   normal viewing distance (3+ metres) with fonts scaled to tvOS guidelines.

---

### User Story 4 - Top Shelf Integration (Priority: P4)

When Sonas is placed in a prominent position on the Apple TV home screen, the Top Shelf area displays a curated summary
of the family's day: a recent family photo and the next calendar event. Families browsing the home screen see
at-a-glance family information without launching the app.

**Why this priority**: Top Shelf is a tvOS-exclusive ambient touchpoint that requires no user action. It increases the
app's value on the Apple TV home screen and is the natural tvOS complement to the macOS menu bar popover.

**Independent Test**: Can be tested by adding TVSonas to the top row of the Apple TV home screen and confirming the Top
Shelf area shows a recent family photo and the next upcoming event name and time.

**Acceptance Scenarios**:

1. **Given** Sonas is in the top row of the Apple TV home screen, **When** the user highlights the Sonas icon, **Then**
   the Top Shelf displays a recent family photo as the wide background image.
2. **Given** the Top Shelf is active, **When** the user highlights the Sonas icon, **Then** the next upcoming calendar
   event's title and start time are shown as an overlay or inset element.
3. **Given** no upcoming events exist, **When** the Top Shelf is displayed, **Then** the family photo fills the shelf
   without an event overlay; no error state or empty label appears.

---

### Edge Cases

- What happens when the Apple TV has no internet connection? All panels should show a last-known data state with a
  visible "offline" indicator rather than error screens.
- What happens when the family calendar has no upcoming events? The events panel shows a friendly empty state ("Nothing
  coming up — enjoy the day!") rather than a blank panel.
- What happens when the shared photo album has no photos yet? The photos panel shows an empty-state illustration.
- What happens when a service (e.g., Spotify) is not signed in? The corresponding panel shows a sign-in prompt or
  graceful disabled state rather than crashing.
- What happens when the TV is left on overnight? The app should not accumulate memory over extended display periods;
  panels must remain stable across many refresh cycles.
- What happens when focus reaches the edge of the dashboard grid? Focus does not wrap unexpectedly; it stops at the
  boundary.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The TVSonas dashboard MUST display live data from real family services (WeatherKit, Google Calendar REST
  [tvOS] / EventKit [iOS/macOS], PhotoKit, CoreLocation, Spotify) rather than hardcoded fixture values.
- **FR-002**: All panels available on the iOS dashboard (Location, Weather, Calendar, Tasks, Photos, Spotify Jam) MUST
  be present on the tvOS dashboard.
- **FR-003**: The tvOS dashboard MUST be fully navigable using only the Apple TV remote (directional pad, Select, Back)
  with no touch interaction required.
- **FR-004**: Each dashboard panel MUST be focusable via the tvOS focus engine, with a visually distinct focus highlight
  that conforms to tvOS system conventions.
- **FR-005**: Selecting a focused panel MUST expand it to a full-screen detail view; pressing Back MUST return to the
  dashboard with focus restored.
- **FR-006**: The dashboard layout MUST use a grid optimised for large screens — font sizes, spacing, and image scale
  MUST conform to Apple's 10-foot UI guidelines (legible from 3+ metres).
- **FR-007**: All panels MUST refresh automatically at regular intervals without requiring user interaction.
- **FR-008**: When the device is offline, panels MUST show last-known data with an offline indicator rather than blank
  or error states.
- **FR-009**: The app MUST implement a tvOS Top Shelf extension that displays a recent family photo and the next
  upcoming calendar event when Sonas is in the top row of the Apple TV home screen.
- **FR-010**: The photos panel on the dashboard MUST auto-advance through recent family photos on a timer (cycling every
  10–30 seconds) while the dashboard is idle, acting as an ambient slideshow.
- **FR-010b**: The photos panel detail view MUST support remote-navigated browsing through recent family photos (next /
  previous navigation via remote).
- **FR-011**: The location panel detail view MUST show a full-screen map with family member location pins, always
  visible without any unlock step (family-trust model; no privacy gate on the TV).
- **FR-012**: Service panels for integrations that require sign-in MUST display a user-friendly prompt or graceful
  disabled state when the user is not authenticated. For Google Calendar specifically, the sign-in flow MUST use the
  device activation method: display a short code and a URL on the TV screen that the user enters on any other device to
  complete authorisation.
- **FR-013**: The app MUST remain stable and not accumulate significant memory when displayed continuously for extended
  periods (ambient/always-on use case).

### Key Entities

- **Dashboard Panel**: A self-contained information tile showing one family data domain; has a compact grid view and an
  expanded full-screen detail view.
- **Top Shelf Content**: A snapshot of a recent photo and the next event, provided to the tvOS system for display on the
  home screen shelf without launching the app.
- **Service Connection**: A link to a live data provider (weather, calendar, location, photos, Spotify) that a panel
  draws from; can be in states: connected, offline (using cached data), or unauthenticated.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: All six family information panels display live, accurate data within 30 seconds of launching the app on
  Apple TV.
- **SC-002**: A user can navigate from the dashboard to a full-screen panel detail and back using only the Apple TV
  remote in under 5 seconds.
- **SC-003**: Dashboard panels refresh automatically so that data is never more than 5 minutes stale during an active
  session.
- **SC-004**: The app remains responsive and visually stable after 8+ hours of continuous display without a restart.
- **SC-005**: All text on the dashboard is legible at a 3-metre viewing distance on a standard 55-inch television
  (verified by on-device review at intended viewing distance).
- **SC-006**: The Top Shelf displays a family photo and next event within 5 seconds of Sonas being highlighted on the
  Apple TV home screen.
- **SC-007**: No panel crashes or shows an unhandled error state when a connected service is unavailable or the user is
  not signed in to that service.

## Assumptions

- The tvOS app shares the same Sonas/Shared and Sonas/Features source tree as the iOS and macOS targets; platform guards
  (`#if os(tvOS)`) will be used where tvOS requires different behaviour.
- WeatherKit and PhotoKit are available on tvOS and work with the same permission model as iOS; entitlements added for
  tvOS follow the same pattern as iOS. EventKit is NOT available on tvOS — calendar data is sourced from Google Calendar
  REST via `TVCalendarService` instead. PhotoKit's album picker UI (`selectSharedAlbum()`) is unavailable on tvOS; the
  shared album name is read from `AppConfiguration.shared` (set via iOS/macOS).
- Google Calendar authentication (GoogleSignIn) on tvOS uses the **device activation flow**: the user is shown a short
  code and a URL on the TV screen; they visit that URL on any other device (phone, laptop) and enter the code to
  authorise the TV. This is the standard approach for TV platforms where browser-based OAuth is unavailable.
- Spotify Jam on tvOS is display-only (showing currently playing track) since direct playback control via Spotify SDK
  may not be supported on tvOS.
- CloudKit-based location sharing operates the same way on tvOS as on iOS; no separate tvOS entitlement is needed beyond
  what is already configured.
- The Top Shelf extension is a separate TVTopShelfExtension target, not part of the main app bundle.
- The existing `TVDashboardView` and its three panels serve as the starting point; they will be refactored rather than
  replaced wholesale.
- tvOS 18.0 is the minimum deployment target (matching the current project configuration).
- The app will not support text input on tvOS (e.g., search boxes) beyond what the system keyboard can provide via
  remote; features requiring substantial text entry are out of scope.

## Clarifications

### Session 2026-04-28

- Q: Which authentication strategy should Google Calendar use on tvOS? → A: Device activation flow — user is shown a
  code and URL on the TV screen and authorises on any other device.
- Q: Does the Photos panel on the dashboard auto-advance or show a static photo? → A: Auto-advances through recent
  photos on a timer (slideshow) while the dashboard is idle.
- Q: Should location data on the TV require an action to reveal, or be always visible? → A: Always visible — family
  locations shown to anyone viewing the TV, same as iOS (no privacy gate on the TV).
