# Contract: CalendarService

**Purpose**: Aggregate upcoming calendar events from iCloud (EventKit) and Google Calendar (REST API v3) for the next 48
hours, deduplicated and sorted by start time.

```swift
protocol CalendarServiceProtocol {
    /// Fetch all events starting within the next `hours` hours from both iCloud and Google.
    /// Events are deduplicated by title + startDate if the same event appears in both sources.
    /// - Parameter hours: look-ahead window; default 48
    func fetchUpcomingEvents(hours: Int) async throws -> [CalendarEvent]

    /// Connect a Google Calendar account via OAuth (GIDSignIn.signIn).
    /// Reads GIDClientID from Info.plist and presents the sign-in UI.
    func connectGoogleAccount() async throws

    /// Revoke Google token and remove from Keychain (GIDSignIn.signOut).
    func disconnectGoogleAccount() async

    /// True when a valid Google OAuth token is stored (hasPreviousSignIn or active user).
    var isGoogleConnected: Bool { get }

    /// True when the last Google token refresh returned a 401 or auth error.
    var needsGoogleReconnect: Bool { get }
}
```

**iCloud (EventKit)**:

- `EKEventStore.requestFullAccessToEvents()` (iOS 17+)
- `EKEventStore.events(matching: EKEventStore.predicateForEvents(withStart:end:calendars:))`
- All accessible EKCalendar instances included (no filter by calendar name in v1)

**Google Calendar REST v3**:

```
GET https://www.googleapis.com/calendar/v3/calendars/primary/events
    ?timeMin={now_iso8601}
    &timeMax={now+48h_iso8601}
    &singleEvents=true
    &orderBy=startTime
    &maxResults=50
Authorization: Bearer {access_token}
```

**Response mapping**: | Google field | `CalendarEvent` field | |---|---| | `id` | `id` | | `summary` | `title` | |
`start.dateTime` or `start.date` | `startDate`, `isAllDay` | | `end.dateTime` or `end.date` | `endDate` | |
`attendees[].displayName` | `attendeeNames` | | `colorId` (mapped to hex) | `calendarColour` |

**Error cases**:

- `CalendarServiceError.eventKitPermissionDenied` — EventKit permission denied
- `CalendarServiceError.googleAuthFailed(Error)` — OAuth sign-in or HTTP 401 from REST; sets
  `needsGoogleReconnect = true`
- `CalendarServiceError.fetchFailed(Error)` — network or decoding error
- `CalendarServiceError.missingConfiguration(String)` — `GIDClientID` absent from Info.plist

**Contract test fixtures** (`GoogleCalendarContractTests.swift`):

```swift
// Given: URLProtocol stub returning Google Calendar events JSON fixture
// When: fetchUpcomingEvents(hours: 48) called
// Then: returned events include both EventKit mock events and Google-sourced events
//       events sorted ascending by startDate
//       duplicate title+startDate events appear only once
```
