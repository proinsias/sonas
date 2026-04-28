# Data Model: Sonas — macOS Native Support

**Branch**: `003-macos-native-support` | **Date**: 2026-04-28

All existing data models (`FamilyMember`, `CalendarEvent`, `WeatherSnapshot`, `TodoTask`, `JamSession`) are unchanged
and reused directly on macOS via the shared `CacheService`. This document covers only the new macOS-specific state
types.

---

## MenuBarState

**Purpose**: Observable in-memory model driving the menu bar popover (FR-003). Populated from the same `CacheService`
reads used by the main window; no new network calls.

| Field             | Type               | Description                                    |
| ----------------- | ------------------ | ---------------------------------------------- |
| `familyLocations` | `[FamilyMember]`   | Latest family location snapshot from cache     |
| `nextEvent`       | `CalendarEvent?`   | Earliest upcoming event from cached events     |
| `weatherSummary`  | `WeatherSnapshot?` | Current weather from cache                     |
| `lastUpdated`     | `Date?`            | Timestamp of most recent successful cache load |
| `isOffline`       | `Bool`             | True when last refresh attempt had no network  |

**Lifecycle**: Created once in `MacSonasApp`; injected into `MacMenuBarPopoverView` via SwiftUI environment. Refreshed
whenever the popover opens (lazy read from `CacheService`) and whenever the main window refreshes (shared ViewModel
side-effect).

**Validation rules**:

- `nextEvent` is the first event with `startDate > now`; nil if none within the next 24 hours
- `lastUpdated` is nil only before the first successful load; drives the "last updated" offline indicator (FR-017)

---

## MacWindowState

**Purpose**: Per-window SwiftUI scene state driving sidebar selection and scroll position. Persisted automatically by
`@SceneStorage` across app restarts (D-002).

| Field             | Storage                                | Type          | Description                        |
| ----------------- | -------------------------------------- | ------------- | ---------------------------------- |
| `selectedSection` | `@SceneStorage("mac.selectedSection")` | `AppSection?` | Currently selected sidebar section |

**State transitions**:

- `nil` → `.dashboard` on first appearance (`.onAppear` guard in `MacShell`)
- Any section → any section on sidebar tap or keyboard shortcut (Cmd+1–7)
- Persisted on window close; restored on next launch if the window is re-opened

---

## MacNotificationCategory

**Purpose**: Type-safe enumeration of `UNNotificationCategory` identifiers registered at app launch by
`MacNotificationService`.

| Case                | Category ID                   | Action ID       | Action Title    | Navigation Target     |
| ------------------- | ----------------------------- | --------------- | --------------- | --------------------- |
| `.locationArrival`  | `com.sonas.location.arrival`  | `show-map`      | "Show on Map"   | `AppSection.location` |
| `.calendarUpcoming` | `com.sonas.calendar.upcoming` | `open-calendar` | "Open Calendar" | `AppSection.calendar` |

**Validation rules**:

- Category and action IDs are string constants; no runtime computation
- Each category has exactly one action; destructive flag is `false` for both
- `UNNotificationPresentationOptions` on macOS includes `.banner` and `.list` (Notification Centre)

---

## Notification Payload Schema

Used when scheduling a local notification via `MacNotificationService`.

**Location arrival notification**:

```
title:    "[Name] arrived at [Place]"
body:     ""
categoryIdentifier: "com.sonas.location.arrival"
userInfo: { "section": "location", "memberId": "<uuid>" }
```

**Calendar upcoming notification**:

```
title:    "[Event title]"
body:     "Starts at [time]"
categoryIdentifier: "com.sonas.calendar.upcoming"
userInfo: { "section": "calendar", "eventId": "<calendar-event-id>" }
```

The `section` key in `userInfo` is read by `MacNotificationService`'s delegate method to determine which `AppSection` to
post in `.sonasNavigationRequested`.
