# Feature Specification: Sonas — iOS Family Command Center

User description: "Build an iOS application called Sonas to act as a Family Command Center, showing the date & time,
everyone's location, upcoming events, shared photos, todoist lists, the weather (today/this week, sunrise/set, moon
phase, wind, humidity, pressure, air quality), spotify jam QR, and other family matters. Ensure that the application can
later be ported to iPadOS, macOS, WatchOS, and tvOS."

## Clarifications

### Session 2026-04-07

- Q: How does Sonas obtain family member location data — via Apple Family Sharing / Find My, or independent GPS
  tracking? → A: Apple Family Sharing / Find My (Option A); Sonas reads existing Apple-managed location data, no
  proprietary GPS tracking.
- Q: How is the Sonas family group formed and managed — mirrored from Apple Family Sharing, Sonas-managed, or hybrid? →
  A: Mirror Apple Family Sharing (Option A); whoever belongs to the Apple Family Sharing group is automatically a Sonas
  family member; no in-app invite, admin role, or membership management needed.
- Q: What is the privacy/compliance posture for minors who use the app? → A: Apple Family Sharing delegates compliance
  (Option B); app targets a "9+" App Store age rating; all sensitive data for minors (location, photos) flows
  exclusively through Apple's consented infrastructure; Sonas MUST NOT independently store personal data about any
  family member.
- Q: Which shared photo service provides the gallery? → A: iCloud Shared Album (Option A); a single designated iCloud
  Shared Album that all family members contribute to, accessible natively across all Apple platforms without a
  third-party account.
- Q: Which calendar services does Sonas display? → A: iCloud + Google Calendar (Option B); events from all iCloud
  calendars accessible on the device (including the iCloud Family Shared Calendar) plus any connected Google Calendar
  accounts; Outlook and other providers are out of scope for v1.

## User Scenarios & Testing _(mandatory)_

### User Story 1 — At-a-Glance Family Dashboard (Priority: P1)

A family member opens Sonas and immediately sees a unified dashboard showing the current date and time, the real-time
location of every family member, and the day's upcoming events — all without navigating away from a single screen. This
is the core value of the Command Center: one glance tells you where everyone is and what's coming next.

**Why this priority**: Location awareness and calendar awareness are the two most critical coordination needs in a busy
family. If only one feature shipped, this would be the MVP.

**Independent Test**: Open the app with at least two family members connected and one calendar event within the next 24
hours. The dashboard MUST display each member's location label and the event title, time, and organiser without any
additional taps.

**Acceptance Scenarios**:

1. **Given** the app is launched, **When** the home screen loads, **Then** the current date and local time are visible
   in a prominent position and update in real time.
2. **Given** all family members have location sharing enabled, **When** the dashboard is displayed, **Then** each
   member's name and a human-readable location label (e.g., "At home", "Near school") are shown simultaneously.
3. **Given** there are upcoming calendar events within the next 48 hours, **When** the dashboard loads, **Then** the
   next three events are listed with their title, date/time, and attendees.
4. **Given** a family member's location cannot be retrieved, **When** the dashboard loads, **Then** that member is shown
   with a "Location unavailable" indicator and the rest of the dashboard renders normally.
5. **Given** there are no upcoming calendar events, **When** the dashboard loads, **Then** the events panel shows a
   friendly "Nothing scheduled" message.

---

### User Story 2 — Comprehensive Weather Display (Priority: P2)

A family member checks today's weather and the week ahead from the dashboard without leaving the app. The weather panel
shows conditions relevant to planning: current temperature, description, sunrise and sunset times, moon phase, wind
speed and direction, humidity, atmospheric pressure, and air quality index. A weekly forecast strip lets the family
decide whether the weekend picnic is still on.

**Why this priority**: Weather drives daily family decisions (clothing, transport, outdoor plans). It is a core
information widget that must work independently of all other panels.

**Independent Test**: Open the weather panel with a valid location. All eight weather attributes
(temperature/description, sunrise/sunset, moon phase, wind, humidity, pressure, air quality, weekly forecast) MUST be
visible and populated with current data without any additional taps.

**Acceptance Scenarios**:

1. **Given** the app has the family's home location configured, **When** the weather panel is displayed, **Then**
   today's temperature, sky description, humidity, wind speed/direction, atmospheric pressure, and air quality index are
   all shown.
2. **Given** valid weather data is available, **When** the weather panel loads, **Then** today's sunrise time and sunset
   time are displayed.
3. **Given** valid weather data is available, **When** the weather panel loads, **Then** the current moon phase (name
   and icon) is displayed.
4. **Given** valid weather data is available, **When** the weather panel loads, **Then** a 7-day forecast strip shows
   each day's high/low temperature and a weather icon.
5. **Given** weather data cannot be fetched (e.g., no connectivity), **When** the weather panel loads, **Then** the last
   successfully retrieved data is shown with a "Last updated [time]" label and a retry control is visible.

---

### User Story 3 — Family Tasks via Todoist (Priority: P3)

A family member views the household's shared Todoist lists directly in Sonas so that chores, errands, and
responsibilities are always visible in the Command Center without switching apps. Tasks can be marked complete from
within Sonas.

**Why this priority**: Task visibility is important but relies on an external service account already being set up. It
is independently useful once the dashboard shell exists.

**Independent Test**: Connect a Todoist account with at least one shared project containing open tasks. The tasks panel
MUST display those tasks and allow one to be checked off, with the change reflected in Todoist within 30 seconds.

**Acceptance Scenarios**:

1. **Given** a Todoist account is connected and has shared projects, **When** the tasks panel loads, **Then** all open
   tasks across the designated family projects are listed grouped by project name.
2. **Given** tasks are displayed, **When** a family member taps the completion checkbox on a task, **Then** the task is
   marked complete and removed from the list within 30 seconds.
3. **Given** new tasks are added in Todoist by any family member, **When** the tasks panel next refreshes (within 5
   minutes or on manual pull-to-refresh), **Then** the new tasks appear in the list.
4. **Given** the Todoist connection fails, **When** the tasks panel loads, **Then** a clear connection-error message is
   displayed with an option to reconnect.

---

### User Story 4 — Shared Family Photos (Priority: P4)

Recent shared family photos are displayed in a rotating gallery panel on the dashboard, giving the Command Center a
warm, personal feel and surfacing memories automatically.

**Why this priority**: Photos add emotional value and personalisation but do not affect the core coordination utility of
the app.

**Independent Test**: Connect a shared photo album containing at least five images. The gallery panel MUST display the
photos in a rotating carousel that advances automatically every 10–30 seconds without user interaction.

**Acceptance Scenarios**:

1. **Given** a shared photo source is configured with accessible photos, **When** the dashboard loads, **Then** a
   gallery panel displays at least the 20 most recent photos in a carousel.
2. **Given** the gallery is rotating, **When** a family member taps on a photo, **Then** it expands to full-screen view
   and the family member can swipe through adjacent photos.
3. **Given** no shared photos are available, **When** the gallery panel loads, **Then** a prompt is shown encouraging
   the family to add photos to the shared album.

---

### User Story 5 — Spotify Jam QR Code (Priority: P5)

A family member can start a shared Spotify Jam session and display its QR code on the Sonas dashboard so other family
members can scan it with their devices and join the session instantly.

**Why this priority**: Entertainment integration is a nice-to-have that enhances the "family gathering" experience but
is the least critical coordination feature.

**Independent Test**: With a Spotify account connected, tap "Start Jam". A scannable QR code MUST appear on screen that,
when scanned by another device, successfully opens the Spotify Jam session.

**Acceptance Scenarios**:

1. **Given** a Spotify account is connected, **When** a family member taps "Start Jam", **Then** a Jam session is
   created and its QR code is displayed prominently on the dashboard.
2. **Given** the Jam QR code is displayed, **When** a second device scans it, **Then** that device joins the Spotify Jam
   session.
3. **Given** an active Jam session exists, **When** a family member taps "End Jam", **Then** the QR code is removed from
   the dashboard.
4. **Given** no Spotify account is connected, **When** the Jam panel is tapped, **Then** the family member is prompted
   to connect their Spotify account.

---

### User Story 6 — Multi-Platform Accessibility (Priority: P6)

The Sonas experience is available across all Apple platforms so family members can access the Command Center on whatever
device is most convenient — a wall-mounted iPad, a Mac in the kitchen, an Apple Watch on the wrist, or an Apple TV in
the living room.

**Why this priority**: Platform reach multiplies the value of every other feature but requires the core iOS experience
to be complete first.

**Independent Test**: Install the app on an iPad and verify that the full dashboard renders correctly at the larger
screen size with an adapted layout that makes use of the additional space.

**Acceptance Scenarios**:

1. **Given** the app is installed on an iPad, **When** launched, **Then** the dashboard adapts to the larger screen,
   displaying all panels in a multi-column layout without horizontal scrolling.
2. **Given** the app is installed on a Mac, **When** launched, **Then** the dashboard is usable with a mouse and
   keyboard, and all tappable controls are reachable via click.
3. **Given** the app is installed on an Apple Watch, **When** raised or tapped, **Then** a compact glanceable view shows
   the current time, at most two family member locations, and the next upcoming event.
4. **Given** the app is installed on an Apple TV, **When** launched, **Then** the dashboard displays all panels in a
   lean-back layout suitable for a television, navigable with the remote.

---

### Edge Cases

- What happens when the device has no internet connection at launch? The app MUST display the most recently cached data
  for every panel and clearly indicate the offline state.
- What happens when a family member revokes location permission? That member is shown as "Location unavailable" without
  crashing or blocking other panels.
- What happens when there are more than 10 family members? The location panel MUST scroll or paginate rather than
  truncate silently.
- What happens when Todoist, Spotify, or the weather provider returns an error mid-session? The affected panel shows an
  error state; all other panels continue to function independently.
- What happens when a photo in the gallery is deleted from the shared source while the app is open? The gallery skips
  the deleted photo on next rotation without crashing.
- What happens when the device's clock or timezone changes (e.g., during travel)? All time-dependent displays (clock,
  sunrise/set, events) update automatically to the new timezone within 60 seconds.
- What happens when a Todoist project has more than 100 open tasks? The panel MUST paginate or group tasks and not
  render an unbounded list.
- What happens when a connected Google Calendar account's OAuth token expires or is revoked? The events panel MUST
  display iCloud calendar events normally, show a per-account reconnection prompt for the affected Google account, and
  not block the rest of the dashboard.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The app MUST display the current local date and time, updating every second, on the primary dashboard
  screen.
- **FR-002**: The app MUST display each family member's location by reading data from Apple Family Sharing / Find My;
  Sonas MUST NOT perform independent GPS tracking. Location is shown as a human-readable place label rather than raw
  coordinates.
- **FR-003**: The app MUST display upcoming calendar events for at least the next 48 hours, including event title,
  date/time, and attendees, aggregated from two sources: (a) all iCloud calendars the device user has access to
  (including the iCloud Family Shared Calendar), and (b) any Google Calendar accounts explicitly connected by a family
  member within Sonas. Outlook and other calendar providers are out of scope for v1.
- **FR-004**: The app MUST display current weather for the family's configured home location, including: temperature,
  sky description, humidity, wind speed and direction, atmospheric pressure, and air quality index.
- **FR-005**: The app MUST display today's sunrise and sunset times for the configured location.
- **FR-006**: The app MUST display the current moon phase with a descriptive name and a visual indicator.
- **FR-007**: The app MUST display a 7-day weather forecast, showing each day's high/low temperature and a
  representative weather condition icon.
- **FR-008**: The app MUST display open tasks from designated shared Todoist projects and allow family members to mark
  tasks as complete from within the app.
- **FR-009**: The app MUST automatically refresh Todoist tasks at least every 5 minutes when the app is in the
  foreground (via a Timer), and support manual refresh via pull-to-refresh. When the app is in the background, refresh
  is best-effort via `BGAppRefreshTask`; iOS may schedule this at intervals of 15 minutes or longer and this is outside
  the app's control.
- **FR-010**: The app MUST display a rotating gallery of the most recent photos from a single designated iCloud Shared
  Album, advancing automatically between images every 10–30 seconds.
- **FR-011**: The app MUST allow a family member to initiate a Spotify Jam session and display the resulting joinable QR
  code on the dashboard.
- **FR-012**: The app MUST allow a family member to end an active Spotify Jam session, removing the QR code from the
  dashboard.
- **FR-013**: The app MUST degrade gracefully when any individual data source (location, calendar, weather, Todoist,
  photos, Spotify) is unavailable, showing an error state only in the affected panel while all other panels remain
  functional.
- **FR-014**: The app MUST cache the most recently fetched data for all panels and display it when the device is
  offline, accompanied by a visible "last updated" timestamp.
- **FR-015**: The app MUST be structured so that its user interface and layout system can be adapted for iPadOS, macOS,
  watchOS, and tvOS without rewriting core business logic or data retrieval behaviour.
- **FR-016**: Location sharing consent is governed by Apple Family Sharing; Sonas MUST surface a clear prompt directing
  family members to enable location sharing via Apple's native settings if their location is not available. Sonas MUST
  NOT implement a parallel consent mechanism.
- **FR-017**: A family member's location visibility in Sonas MUST update within 60 seconds of that member changing their
  Apple Family Sharing location-sharing preference.
- **FR-018**: Sonas MUST NOT persistently store any personal data about family members on its own servers or in
  third-party analytics services. All data displayed in the app (location, calendar events, photos, tasks) MUST be
  fetched at runtime from their respective source systems and held only transiently in the device's local cache.
- **FR-019**: The app MUST target a "9+" App Store age rating. No age-verification gate or separate parental-consent
  screen is required within Sonas itself, as consent for minor family members is governed by Apple Family Sharing.

### Key Entities

- **Family Member**: Any person who belongs to the Apple Family Sharing group associated with the device running Sonas.
  Membership is read directly from Apple Family Sharing; Sonas does not maintain its own member list, invite flow, or
  admin roles. Each member has a display name and avatar inherited from their Apple ID.
- **Location Snapshot**: The most recent known position of a family member, represented as a human-readable place label
  and a timestamp indicating data freshness.
- **Calendar Event**: A scheduled event with a title, start/end date-time, optional location, and a list of attendees.
  Events are aggregated from iCloud calendars (accessed natively on the device) and Google Calendar accounts (connected
  via OAuth within Sonas). Each event carries a source label (iCloud or Google) to aid debugging but this label is not
  surfaced to the user.
- **Weather Snapshot**: A point-in-time capture of atmospheric conditions for a configured location, including all
  displayed attributes (temperature, humidity, wind, pressure, AQI, moon phase, sunrise/sunset).
- **Weekly Forecast**: An ordered collection of up to 7 daily forecast summaries, each containing predicted high/low
  temperature and a condition label.
- **Task**: A Todoist task belonging to a shared family project, with a title, optional due date, assignee, and
  completion status.
- **Photo**: A shared image sourced from a single designated iCloud Shared Album, with a capture date and optional
  caption. All family members contribute to and view the same album; Sonas displays photos read-only and does not
  support uploading or deleting photos from within the app.
- **Jam Session**: An active Spotify Jam, represented by a unique joinable QR code and a status (active/ended).
- **App Configuration**: Household-level settings including home location for weather, connected external accounts
  (calendar, Todoist, Spotify, photos), and per-member preferences.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: A family member can open the app and see current location, time, and the next event for every family
  member within 2 seconds of the dashboard appearing on screen. (Aligns with constitution §IV ≤ 2 s initial load
  requirement; cached data renders in ≤ 500 ms.)
- **SC-002**: All eight weather attributes (temperature, description, humidity, wind, pressure, air quality,
  sunrise/set, moon phase) are visible simultaneously on the dashboard without any scroll or tap, on a standard phone
  screen.
- **SC-003**: A task marked complete in Sonas is reflected as complete in Todoist within 30 seconds under normal
  connectivity conditions.
- **SC-004**: The shared photo gallery advances through at least 20 images automatically, cycling continuously, without
  requiring any user interaction.
- **SC-005**: A family member can generate and display a Spotify Jam QR code within 5 taps from the dashboard.
- **SC-006**: When any single data source is unavailable, the remaining panels continue to display data normally; no
  panel failure causes another panel to crash or disappear.
- **SC-007**: The app remains fully usable with cached data when offline; the staleness of cached data is communicated
  to the user for every panel.
- **SC-008**: The same core experience (dashboard, weather, tasks, photos, Jam) is available on iPad in a layout that
  takes advantage of the larger screen without horizontal scrolling or empty space exceeding 30% of the viewport.
- **SC-009**: A family member whose Apple Family Sharing location-sharing preference changes will see that change
  reflected in Sonas within 60 seconds. (Consent is governed entirely by Apple Family Sharing; Sonas MUST NOT implement
  a parallel in-app consent mechanism — FR-016.)
- **SC-010**: 90% of first-time users can identify the location of all family members and the next upcoming event within
  30 seconds of opening the app for the first time, without any tutorial or onboarding assistance.

## Quality & Engineering Standards

### Mandatory Testing Strategy

Every user-facing feature and functional requirement MUST be verified using a three-tier testing strategy:

1. **Unit Tests**: Verify individual business logic, service components, and data mapping in isolation.
2. **Integration Tests**: Verify the interaction between services, view models, and mock data sources. Every service
   MUST have a corresponding integration test.
3. **UI Tests**: Verify critical user journeys, layout adaptations across platforms, and accessibility compliance. Every
   user story MUST have at least one corresponding UI test.

### CI/CD Integration

All tests and linting rules are enforced via GitHub Workflows. Development tools are managed via `mise` to ensure
environment parity between local development and CI.

## Assumptions

- Family members all use Apple devices and have Apple ID accounts; non-Apple devices are out of scope for v1.
- Calendar events are sourced from iCloud (natively on-device) and Google Calendar (via OAuth); creating or editing
  events is out of scope for v1. Outlook, Exchange, and other calendar providers are explicitly out of scope for v1.
- The configured "home location" for weather is a single fixed address; per-member or GPS-following weather is out of
  scope for v1.
- Todoist integration requires each family member who wishes to see tasks to have or share access to a Todoist account;
  the app does not host its own task storage.
- The shared photo source is a single designated iCloud Shared Album; multi-album selection and third-party photo
  services (Google Photos, etc.) are out of scope for v1.
- Sonas displays photos read-only; adding or deleting photos is done outside the app via the iOS Photos app or any other
  iCloud-capable device.
- Spotify Jam requires at least one family member to have an active Spotify account; the QR code is generated by Spotify
  and displayed by Sonas (Sonas does not host the session).
- The app targets the current major iOS version and one version back; older iOS versions are out of scope.
- Location data is sourced exclusively from Apple Family Sharing / Find My; all family members must be part of the same
  Apple Family Sharing group to appear on the location panel.
- Family group membership is determined entirely by Apple Family Sharing; Sonas has no in-app invite system, admin role,
  or membership management. Adding or removing a family member in Apple Family Sharing is reflected in Sonas
  automatically.
- Sonas targets a "9+" App Store age rating. Privacy compliance for minor family members is delegated to Apple Family
  Sharing; Sonas stores no personal data about any family member independently (no backend database of users, locations,
  or events).
- COPPA and GDPR-Kids obligations are not directly borne by Sonas because all sensitive data flows through Apple's own
  consented infrastructure. The app must not add any analytics, advertising SDKs, or third-party data collection that
  would alter this posture.
- All family members physically share a household or close family unit; the app is not designed for general social
  networks.
- Network connectivity is expected for initial data fetch; the offline/cache mode is a degraded-but-functional fallback,
  not a primary use case.
- The watchOS companion delivers a read-only glanceable view; task completion and Jam initiation on watchOS are out of
  scope for v1.
- The tvOS version is a passive display mode (always-on dashboard); interactive features such as task completion and Jam
  initiation are out of scope for the tvOS v1 target.
