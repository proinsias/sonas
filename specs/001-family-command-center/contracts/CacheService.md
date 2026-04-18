# Contract: CacheService

**Purpose**: SwiftData-backed on-device cache for all panel data; surfaced with
staleness timestamps; cleared per eviction policy defined in research.md.

```swift
protocol CacheServiceProtocol {
    // MARK: – Weather
    func saveWeather(_ snapshot: WeatherSnapshot, forecast: [DayForecast]) throws
    func loadWeather() throws -> (snapshot: WeatherSnapshot, forecast: [DayForecast])?

    // MARK: – Location
    func saveLocations(_ members: [FamilyMember]) throws
    func loadLocations() throws -> [FamilyMember]

    // MARK: – Calendar
    func saveEvents(_ events: [CalendarEvent]) throws
    func loadEvents() throws -> [CalendarEvent]

    // MARK: – Tasks
    func saveTasks(_ tasks: [Task]) throws
    func loadTasks() throws -> [Task]

    // MARK: – Jam
    func saveJamSession(_ session: JamSession?) throws
    func loadJamSession() throws -> JamSession?

    // MARK: – Eviction
    /// Remove cached entries older than their per-type TTL.
    /// Called on app foreground and before each panel data fetch.
    func evictStaleEntries() throws
}
```

**TTL policy** (from research.md):

| Data type        | TTL                    | Behaviour when stale                        |
| ---------------- | ---------------------- | ------------------------------------------- |
| WeatherSnapshot  | 1 hour                 | Show with "Last updated" label              |
| LocationSnapshot | 5 minutes              | Show "Last seen N min ago" or "unavailable" |
| CalendarEvent    | Until event end time   | Past events evicted automatically           |
| Task             | 24 hours               | Force-refresh on next foreground            |
| JamSession       | Until status == .ended | Cleared immediately on `endJam()`           |

**Implementation notes**:

- `ModelContainer` initialised in `SonasApp` and injected via SwiftUI
  environment.
- All `@Model` classes stored in the same `ModelContainer`.
- `evictStaleEntries()` is synchronous; called on `ScenePhase.active`
  transition.
- Cache failures are non-fatal: logged at DEBUG level; UI falls back to empty
  state.

**Contract test**:

```swift
// Given: in-memory ModelContainer
// When: saveWeather(_:forecast:) called, then loadWeather() called
// Then: returned snapshot equals saved snapshot; forecast count matches

// Given: CachedWeatherSnapshot with lastUpdated 2 hours ago
// When: evictStaleEntries() called
// Then: loadWeather() returns nil
```
