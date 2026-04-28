# Research: Sonas tvOS Full Support

**Branch**: `004-tvos-support` | **Date**: 2026-04-28

## Decision 1 — Calendar on tvOS: Google REST Only (no EventKit)

**Decision**: `TVCalendarService` wraps only `GoogleCalendarClient` (Google Calendar REST v3). `EventKit` is excluded
from the tvOS build via `#if !os(tvOS)` guard in `CalendarService.swift`.

**Rationale**: `EventKit.framework` is not available on tvOS. Attempting to import it causes a build failure. The
existing `GoogleCalendarClient` in `CalendarService.swift` is a standalone `final class` (no `EventKit` dependency) and
can be moved to `Sonas/Shared/` or imported via the shared source tree without modification. Local device calendars are
not accessible on Apple TV regardless of approach.

**Alternatives considered**:

- Forking `CalendarService` entirely for tvOS: rejected — duplicates the Google REST client and creates a maintenance
  burden.
- Returning only EventKit events on tvOS (skipping Google): rejected — EventKit is unavailable; this is not an option.

## Decision 2 — Google Calendar Auth on tvOS: OAuth 2.0 Device Authorization Grant

**Decision**: Implement the OAuth 2.0 Device Authorization Grant flow manually in `TVDeviceAuthFlow.swift`. Endpoints:
`POST https://oauth2.googleapis.com/device/code` (get device_code + user_code), then poll
`POST https://oauth2.googleapis.com/token` until the user completes authorization on another device.

**Rationale**: tvOS does not support ASWebAuthenticationSession or Safari-based redirects. GoogleSignIn-iOS SDK uses
browser-based OAuth and does not provide a device-flow path. The Device Authorization Grant (RFC 8628) is the
well-established standard for TV/limited-input devices and is explicitly supported by Google's OAuth 2.0 server. The
flow displays a `user_code` and URL (`accounts.google.com/device`) on the TV screen; the user enters the code on any
browser. Token is stored in `AppStorage` / Keychain alongside the existing Google token used on iOS.

**Alternatives considered**:

- Credential sharing via iCloud Keychain from iOS (Option B): rejected by user during clarification in favour of device
  activation flow (Option A). Sharing credentials across bundle IDs also requires CloudKit entitlement configuration
  that is not yet set up.
- Skipping Google Calendar on tvOS (show disabled state): viable fallback if device-flow implementation is deferred, but
  reduces feature value significantly.

## Decision 3 — Spotify on tvOS: Web API REST Polling (display-only)

**Decision**: New `TVSpotifyReadService` polls `GET https://api.spotify.com/v1/me/player/currently-playing` every 30
seconds using an access token obtained via the Spotify Accounts Service device-flow or pre-authenticated token. The
panel is display-only (track name, artist, album art). No playback control.

**Rationale**: `SpotifyiOS` SDK is restricted to iOS (and excluded from the tvOS target via `project.yml` dependency
filter). The Spotify Web API has a `currently-playing` endpoint that requires only a valid access token and returns JSON
containing track name, artist, and album art URL — sufficient for the display-only requirement. Polling at 30 s matches
Spotify's recommended client polling interval and stays well within the 5-min refresh budget (SC-003).

**Spotify auth on tvOS**: Spotify does not officially support the OAuth 2.0 Device Authorization Grant. The practical
approach is: if the user has authenticated on the iOS app, the access token is refreshed and stored; the TV reads the
same cached token via shared `AppStorage` key. If no token exists, the Jam panel shows a graceful unauthenticated state
(FR-012). Spotify authentication setup on tvOS itself is out of scope for this feature.

**Alternatives considered**:

- Casting or AirPlay from iOS to show Spotify state: rejected — not a native data integration.
- Polling more frequently (10 s): rejected — increases battery/CPU load with minimal UX benefit.

## Decision 4 — Location on tvOS: CloudKit Read-Only

**Decision**: Reuse `LocationService` on tvOS but skip `startPublishing()` via `#if !os(tvOS)` guard. The TV reads
family member locations from CloudKit (same `AsyncStream<[FamilyMember]>`) but does not publish its own location.

**Rationale**: CloudKit is fully available on tvOS. Apple TVs have no meaningful physical location to share (they are
fixed in the home). The existing `AsyncStream`-based subscription to CloudKit location records works identically on
tvOS. Guarding `startPublishing()` requires a one-line platform conditional and no further service changes.

**Alternatives considered**:

- Creating a separate `TVLocationService`: rejected — unnecessary duplication; a single guard is sufficient.

## Decision 5 — Photos on tvOS: PhotoKit (available, reuse unchanged)

**Decision**: `PhotoService` (PhotoKit) is available on tvOS 10+ and is reused without modification. `PhotoViewModel`
and `TVSlideshowPanelView` consume it directly.

**Rationale**: Apple added PhotoKit to tvOS at tvOS 10.0. The `Photos.framework` is available and the shared album fetch
API (`PHAssetCollection`, `PHFetchOptions`) functions the same on tvOS as on iOS. Permission prompts on tvOS use the
same `PHPhotoLibrary.requestAuthorization` API.

**Note**: On tvOS the `selectSharedAlbum()` method (which presents a photo picker UI) is not callable — the album name
must be pre-configured. The tvOS app will use the `selectedAlbumName` stored in `AppConfiguration.shared` (set via
iOS/macOS). If no album is selected, the Photos panel shows the same "select an album" prompt already present in
`PhotoGalleryView`.

## Decision 6 — WeatherKit on tvOS: Available, Reuse Unchanged

**Decision**: `WeatherService` (WeatherKit) is reused unchanged. The `WeatherKit.framework` entitlement is added to the
`TVSonas` target in `project.yml`.

**Rationale**: WeatherKit has been available on tvOS since tvOS 16.0, which is below the tvOS 18 deployment target of
this project. The API is identical across platforms. The entitlement `com.apple.developer.weatherkit` must be added to
the TVSonas target's entitlements file (analogous to the iOS target).

## Decision 7 — Top Shelf Extension: TVServices Framework

**Decision**: New `TVTopShelfExtension` target using the `TVServices.framework` `TVTopShelfContentProvider` protocol.
Provides `TVTopShelfInsetContent` with a `TVTopShelfSectionedContent` containing one item: a recent photo URL (wide
image) and a `TVContentItem` with the next event title and start time as metadata.

**Rationale**: `TVTopShelfContentProvider` is the standard Apple API for supplying Top Shelf content. It runs in a
separate extension process and is invoked by the system when the user highlights the app icon. The extension reads from
a shared `AppGroup` `UserDefaults` container (keyed to the next event and a photo asset URL) that the main app populates
after each refresh. This shared-data pattern avoids the extension needing its own network requests.

**Alternatives considered**:

- Extension makes its own CloudKit/Google Calendar requests: rejected — extensions have limited execution budget and the
  shared UserDefaults pattern is the Apple-recommended approach for Top Shelf content.

## Decision 8 — Dashboard Layout: 3×3 Grid Expanding to Cover 7 Panels

**Decision**: The `TVShell` grid uses a `LazyVGrid` with 3 flexible columns. 7 panels (Clock, Weather, Calendar, Tasks,
Location, Photos, Spotify Jam) fill the grid; the Clock panel is retained from the existing stub and becomes the first
cell. The Photos panel spans the full width of one row using `GridItem(.flexible(), span: 3)` to give the slideshow
prominence.

**Rationale**: The existing `TVDashboardView` already uses 3 columns successfully for 3 panels. Extending to 7 panels
with a 3-column layout gives a balanced 2-row + 1-wide layout (3 + 3 + 1 wide) that fills a 16:9 TV screen at
comfortable scale.

## Performance Baselines

| Metric                       | Target           | Method                                               |
| ---------------------------- | ---------------- | ---------------------------------------------------- |
| Dashboard live data load     | ≤ 30 s           | Stopwatch: launch → all panels show non-fixture data |
| Panel expand/collapse        | ≤ 5 s round-trip | Stopwatch: remote click → detail shown               |
| Data refresh staleness       | ≤ 5 min          | Timer-based verification in XCTest                   |
| Continuous display stability | 8 h              | Instruments Allocations + Leaks on device            |
| UI interaction response      | ≤ 100 ms         | Instruments Animation Hitches template               |
