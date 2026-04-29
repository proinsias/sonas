# Data Model: Sonas tvOS Full Support

**Branch**: `004-tvos-support` | **Date**: 2026-04-28

All existing shared models (`WeatherSnapshot`, `DayForecast`, `CalendarEvent`, `FamilyMember`, `Photo`, `Task`,
`JamSession`) are reused unchanged. This document describes only the new types introduced for tvOS.

---

## New Types

### `TVCurrentTrack`

Represents the track currently playing on Spotify, decoded from the Spotify Web API
`GET /v1/me/player/currently-playing` response.

| Field         | Type     | Source                     | Notes                    |
| ------------- | -------- | -------------------------- | ------------------------ |
| `id`          | `String` | `item.id`                  | Spotify track ID         |
| `title`       | `String` | `item.name`                | Track name               |
| `artistName`  | `String` | `item.artists[0].name`     | Primary artist           |
| `albumArtURL` | `URL?`   | `item.album.images[0].url` | Largest available image  |
| `isPlaying`   | `Bool`   | `is_playing`               | False when paused        |
| `fetchedAt`   | `Date`   | Client-stamped             | For stale-data detection |

**Conformances**: `Identifiable`, `Equatable`, `Sendable`

---

### `TVDeviceAuthState`

State machine for the OAuth 2.0 Device Authorization Grant flow.

- `.idle` — No auth in progress
- `.pendingUserAction(userCode:, verificationURL:, expiresAt:)` — Code shown on screen; waiting for user to authorize
- `.polling(deviceCode:, interval:)` — Periodically checking the token endpoint
- `.authorized(accessToken:, refreshToken:)` — Auth complete; tokens stored
- `.expired` — Device code expired before the user acted
- `.failed(Error)` — Non-recoverable error

**Conformances**: `Equatable`, `Sendable`

---

### `TVTopShelfSnapshot`

Written by the main app to a shared `AppGroup` `UserDefaults` container. Read by the `TVTopShelfExtension`.

| Field            | Type      | Notes                                                                |
| ---------------- | --------- | -------------------------------------------------------------------- |
| `photoFileURL`   | `URL?`    | Local file URL of the most recent photo (copied to shared container) |
| `nextEventTitle` | `String?` | Next calendar event title                                            |
| `nextEventStart` | `Date?`   | Next calendar event start time                                       |
| `updatedAt`      | `Date`    | Timestamp of last main-app write                                     |

**Storage**: `AppGroup` UserDefaults key `"com.sonas.topShelf"`, JSON-encoded.  
**Conformances**: `Codable`, `Sendable`

---

## Service Protocols (new, tvOS only)

### `TVCalendarServiceProtocol`

```swift
@MainActor
protocol TVCalendarServiceProtocol: AnyObject, Sendable {
    /// Fetch upcoming calendar events within the next N hours using Google Calendar REST only.
    func fetchUpcomingEvents(hours: Int) async throws -> [CalendarEvent]
    /// True when a valid Google OAuth token is stored for this device.
    var isGoogleConnected: Bool { get }
    /// True when the token has expired and the device-flow re-auth is needed.
    var needsReauth: Bool { get }
}
```

Implemented by `TVCalendarService` (production) and `CalendarServiceMock` (test — already exists and satisfies this
protocol after minor extension).

---

### `TVSpotifyReadServiceProtocol`

```swift
@MainActor
protocol TVSpotifyReadServiceProtocol: AnyObject, Sendable {
    /// Returns the currently playing track, or nil if nothing is playing or the user is unauthenticated.
    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack?
    /// True when a cached Spotify access token is available.
    var isAuthenticated: Bool { get }
}
```

Implemented by `TVSpotifyReadService` (production) and `TVSpotifyReadServiceMock` (test).

---

## State Transitions

### `TVDeviceAuthState` Flow

```
.idle
  └─▶ startFlow() called
        └─▶ .pendingUserAction(userCode, url, expiresAt)
              ├─▶ (user completes on another device) → .polling → .authorized
              ├─▶ (expiresAt elapsed, no action) → .expired
              └─▶ (network/server error) → .failed
```

### `ServiceConnection` States (existing `PanelState<T>` enum, unchanged)

```
.loading → .loaded(data) → .stale(data, lastUpdated)
                         ↘ .error(PanelError)
```

---

## Shared Container (AppGroup)

The `TVTopShelfExtension` and the main `TVSonas` app share data via an `AppGroup` container.

| Container ID               | Content                     | Written by                   | Read by               |
| -------------------------- | --------------------------- | ---------------------------- | --------------------- |
| `group.com.sonas.topshelf` | `TVTopShelfSnapshot` (JSON) | Main app, after each refresh | `TVTopShelfExtension` |

The main app copies the most recent photo asset to a shared-container file path so the extension can reference it
without a network request. The file is overwritten on each refresh.
