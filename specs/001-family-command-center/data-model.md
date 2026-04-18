# Data Model: Sonas — iOS Family Command Center

**Branch**: `001-family-command-center` | **Date**: 2026-04-07

All models are value types (structs) used by the view layer. Persistence is
handled by the SwiftData `@Model` cache counterparts (prefixed `Cached`). No
model is sent to a custom server.

---

## Domain Models (View Layer)

### FamilyMember

Represents a person in the Apple Family Sharing group who has Sonas installed.

```swift
struct FamilyMember: Identifiable, Equatable {
    let id: String                     // CloudKit record name (stable per device/iCloud account)
    let displayName: String            // From Apple ID / CloudKit user record
    let avatarURL: URL?                // Apple ID avatar, optional
    let locationSnapshot: LocationSnapshot?  // nil if location sharing disabled or stale
}
```

Constraints:

- `id` is unique per family member; stable across app restarts.
- `displayName` is non-empty.
- `locationSnapshot` is nil if the member's Sonas app is not installed, location
  permission is denied, or the last update is older than 5 minutes.

---

### LocationSnapshot

The most recent known position of a family member.

```swift
struct LocationSnapshot: Equatable {
    let coordinate: CLLocationCoordinate2D   // Raw GPS (not shown to user)
    let placeName: String                    // Human-readable reverse-geocoded label
                                             // e.g. "At home", "Near school", "Dublin Airport"
    let recordedAt: Date                     // When the member's device recorded this position
    let isStale: Bool                        // true if recordedAt is >5 minutes ago
}
```

Constraints:

- `placeName` is derived by reverse geocoding on the reporting device before
  writing to CloudKit; raw coordinates are never displayed in the UI.
- `isStale` is computed at read time, not stored.

---

### CalendarEvent

A single event aggregated from iCloud or Google Calendar.

```swift
struct CalendarEvent: Identifiable, Equatable {
    let id: String                   // EKEvent.eventIdentifier or Google event.id
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let attendeeNames: [String]      // Display names only; empty if no attendees
    let calendarColour: Color        // From EKCalendar.cgColor or Google calendar colour
    let source: CalendarSource       // .iCloud | .google
}

enum CalendarSource { case iCloud, google }
```

Constraints:

- `title` is non-empty; truncated to 80 characters for display.
- Events outside the 48-hour window are excluded before populating the model.
- `source` is not displayed to the user but available for debugging.
- Events sorted ascending by `startDate`.

---

### WeatherSnapshot

Current atmospheric conditions for the configured home location.

```swift
struct WeatherSnapshot: Equatable {
    let temperature: Measurement<UnitTemperature>
    let feelsLike: Measurement<UnitTemperature>
    let conditionDescription: String          // e.g. "Partly Cloudy"
    let conditionSymbol: String               // SF Symbols name from WeatherKit condition
    let humidity: Double                      // 0.0–1.0
    let windSpeed: Measurement<UnitSpeed>
    let windDirection: Measurement<UnitAngle> // degrees
    let windGust: Measurement<UnitSpeed>?
    let pressure: Measurement<UnitPressure>
    let pressureTrend: PressureTrend          // .rising | .falling | .steady
    let sunrise: Date
    let sunset: Date
    let moonPhase: MoonPhase
    let airQualityIndex: Int?                 // nil if AQI fetch failed; 0–500 US AQI scale
    let airQualityCategory: AQICategory?
    let recordedAt: Date
}

enum PressureTrend { case rising, falling, steady }

enum MoonPhase: String {
    case new, waxingCrescent, firstQuarter, waxingGibbous
    case full, waningGibbous, lastQuarter, waningCrescent
    var displayName: String { rawValue.camelCaseToSentence() }
    var symbolName: String   // SF Symbols moon phase symbol
}

enum AQICategory: String {
    case good, moderate, unhealthyForSensitiveGroups, unhealthy, veryUnhealthy, hazardous
}
```

---

### DayForecast

One day's entry in the 7-day forecast.

```swift
struct DayForecast: Identifiable, Equatable {
    let id: Date                              // The calendar date (midnight)
    let highTemperature: Measurement<UnitTemperature>
    let lowTemperature: Measurement<UnitTemperature>
    let conditionSymbol: String               // SF Symbols name
    let conditionDescription: String
    let precipitationChance: Double           // 0.0–1.0
}
```

---

### Task

A Todoist task in a shared family project.

```swift
struct Task: Identifiable, Equatable {
    let id: String                  // Todoist task ID
    let projectId: String
    let projectName: String         // Denormalised for display grouping
    let content: String             // Task title
    let description: String?        // Optional Todoist task description
    let due: TaskDue?
    let assigneeName: String?
    let priority: TaskPriority      // .p1 (urgent) … .p4 (none)
    var isCompleting: Bool          // Optimistic UI: true while close API call in-flight
}

struct TaskDue: Equatable {
    let date: Date?
    let isRecurring: Bool
}

enum TaskPriority: Int { case p1 = 4, p2 = 3, p3 = 2, p4 = 1 }
```

Constraints:

- `content` is non-empty; truncated to 120 characters for display.
- Tasks are grouped by `projectName` in `TasksPanelView`.
- Maximum 100 tasks per project; excess paginated (not silently dropped).

---

### Photo

A photo from the designated iCloud Shared Album.

```swift
struct Photo: Identifiable, Equatable {
    let id: String                  // PHAsset.localIdentifier
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    // Images are not stored in the model; loaded on demand via PHImageManager
}
```

Constraints:

- At most 20 most-recent photos fetched per session.
- Full-resolution images loaded only when the user taps a photo (full-screen
  mode).
- Deleted photos are detected via `PHPhotoLibraryChangeObserver`; removed from
  list gracefully.

---

### JamSession

An active Spotify Jam session.

```swift
struct JamSession: Equatable {
    let joinURL: URL                // Spotify Jam invite URL (encoded as QR)
    let startedAt: Date
    let startedByName: String       // Display name of the family member who started it
    var status: JamStatus
}

enum JamStatus { case active, ending, ended }
```

---

### AppConfiguration

Household-level settings; persisted in `UserDefaults` (non-sensitive) and iOS
Keychain (API tokens).

```swift
struct AppConfiguration {
    var homeLocation: CLLocationCoordinate2D  // For weather; stored in UserDefaults
    var homeLocationName: String              // Human-readable label, e.g. "Home"
    var selectedPhotoAlbumID: String?         // PHAssetCollection.localIdentifier
    var selectedTodoistProjectIDs: [String]   // Up to 3 project IDs
    var temperatureUnit: UnitTemperature      // .celsius | .fahrenheit
    var autoJamEnabled: Bool                  // Show Jam panel by default
    // Tokens stored in Keychain (not in this struct):
    // - Google OAuth access + refresh token
    // - Todoist API token
    // - Spotify access token
}
```

---

## SwiftData Cache Models

Each cache model mirrors its domain counterpart with a `lastUpdated` timestamp.
Used only for offline / initial-load display; never shown without a staleness
indicator if too old.

```swift
@Model class CachedWeatherSnapshot { /* mirrors WeatherSnapshot + lastUpdated */ }
@Model class CachedLocationSnapshot { let memberID: String; /* mirrors LocationSnapshot + lastUpdated */ }
@Model class CachedCalendarEvent { /* mirrors CalendarEvent + lastUpdated */ }
@Model class CachedTask { /* mirrors Task + lastUpdated */ }
@Model class CachedJamSession { /* mirrors JamSession + lastUpdated */ }
// Photos: only PHAsset localIdentifiers are cached; image data lives in PHImageManager cache
```

---

## State Transitions

### JamSession

```
[none] → active       (user taps "Start Jam"; Spotify SDK creates session)
active → ending       (user taps "End Jam"; API call in-flight)
ending → ended        (API confirms; QR removed from view)
active → ended        (Spotify session expires externally)
```

### Task Completion (Optimistic)

```
open → completing     (user taps checkbox; isCompleting = true)
completing → closed   (API 204 response; task removed from list)
completing → open     (API error; isCompleting = false; error toast shown)
```

### LocationSnapshot Freshness

```
fresh     (recordedAt within 5 min)   → shown as normal location label
stale     (5–30 min)                  → shown with "Last seen [N] min ago"
very stale (>30 min)                  → shown as "Location unavailable"
```
