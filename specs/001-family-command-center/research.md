# Research: Sonas — iOS Family Command Center

**Branch**: `001-family-command-center` | **Date**: 2026-04-07

---

## Decision 1: Family Member Location Mechanism

**Decision**: CloudKit private-container location relay — each family member's Sonas instance
reports their own device location; all instances read all members' locations from a shared
CloudKit private database.

**Rationale**: Apple does not expose a public API for reading Find My / Family Sharing location
data from third-party apps. `CLLocationManager` provides only the current device's own location.
Any approach that reads Find My data from outside Apple's own apps requires private APIs, which
cause App Store rejection. CloudKit is Apple's own infrastructure (satisfies the "no custom
backend" and "no personal data on our servers" constraints), is free at family scale, and
supports real-time subscriptions via `CKQuerySubscription`. All data stays in Apple's ecosystem.

**Implementation notes**:
- Each device writes a `CKRecord` of type `FamilyLocation` to the app's CloudKit private
  container every time location changes significantly (≥50m) or every 60 seconds, whichever
  comes first — matching the spec's 60-second freshness requirement (FR-017).
- Other devices receive push-based updates via `CKQuerySubscription` on the same container;
  no polling required when foregrounded.
- Location permission: `NSLocationWhenInUseUsageDescription` for active use;
  `NSLocationAlwaysAndWhenInUseUsageDescription` for background updates.
- Privacy: `FamilyLocation` records are in the app's private CloudKit container (not the public
  database). Only devices signed into the same iCloud account (or family-shared container) can
  read them. CloudKit encryption at rest is enabled by default.
- Family group boundary: all family members must have Sonas installed and have granted location
  permission. A family member who uninstalls the app stops publishing their location.
- This supersedes the spec's assumption that "Apple Family Sharing / Find My" would be
  accessible — the end-user experience is identical, but the mechanism is CloudKit rather than
  a non-existent Find My API.

**Alternatives considered**:
- Find My public API — does not exist for third-party apps; rejected.
- Life360 / third-party location service — violates Apple-ecosystem constraint; rejected.
- iMessage/Messages location sharing — no developer API; rejected.
- Server-side relay (custom backend) — violates no-backend constraint; rejected.

---

## Decision 2: Weather Data Provider + AQI Gap

**Decision**: WeatherKit for all weather attributes except AQI; Open-Meteo Air Quality API
for AQI (free, no API key, GDPR-compliant).

**Rationale**: WeatherKit (Apple's native weather service, iOS 16+) covers temperature, sky
condition, humidity, wind speed/direction, atmospheric pressure, sunrise/sunset, moon phase,
and 7-day forecast — all required attributes except AQI. WeatherKit does not provide an Air
Quality Index. Open-Meteo's Air Quality API provides European AQI and US AQI at no cost and
with no API key for reasonable request volumes. It requires only a lat/lon query and returns
JSON — consistent with the no-backend, on-device data-fetch model.

**WeatherKit attributes mapped to spec requirements**:
- `CurrentWeather.temperature` → temperature
- `CurrentWeather.condition` → sky description
- `CurrentWeather.humidity` → humidity
- `CurrentWeather.wind` (speed + direction) → wind
- `CurrentWeather.pressure` → atmospheric pressure
- `DayWeather.sun.sunrise` / `.sunset` → sunrise/sunset
- `DayWeather.moon.phase` → moon phase
- `DailyForecast<DayWeather>` (7 entries) → weekly forecast
- AQI → **Open-Meteo** `air-quality` endpoint (`/v1/air-quality?latitude=…&longitude=…&current=european_aqi`)

**Implementation notes**:
- `WeatherService` fetches WeatherKit and Open-Meteo concurrently via `async let`.
- Home location is a `CLLocationCoordinate2D` stored in `AppConfiguration` (UserDefaults).
- WeatherKit entitlement required in Xcode + Apple Developer portal.
- Open-Meteo: no API key; rate limit 10,000 req/day per IP — well within single-household use.
- Cache: `WeatherSnapshot` persisted to SwiftData; shown immediately on launch; refreshed in
  background (foreground: 15-min timer; background: BGAppRefreshTask).

**Alternatives considered**:
- OpenWeatherMap (AQI) — requires API key and account; Open-Meteo is simpler with no key.
- AirNow (US-only AQI) — geographic limitation; rejected.
- WeatherKit AQI (future) — may be added by Apple; code structured to drop Open-Meteo call
  when WeatherKit gains AQI coverage.

---

## Decision 3: Google Calendar OAuth on iOS

**Decision**: GoogleSignIn-iOS SDK (`GoogleSignIn` 7.x) for OAuth 2.0; Google Calendar REST
API v3 for event fetching; access token stored in iOS Keychain via SDK's built-in storage.

**Rationale**: GoogleSignIn-iOS is the official Google SDK for iOS OAuth flows. It handles
the ASWebAuthenticationSession presentation, token refresh, and Keychain storage. The
alternative (GTMAppAuth) is lower-level and requires more boilerplate. REST API v3 is the
stable, documented Google Calendar API; the iOS `EventKit` framework cannot access Google
Calendar accounts added to Settings → Calendar because Google uses CalDAV, which EventKit
does not expose programmatically for third-party read on iOS 17+.

**Implementation notes**:
- OAuth scope: `https://www.googleapis.com/auth/calendar.readonly`
- `CalendarService` uses `EventKit` for iCloud calendars (no OAuth needed — system access)
  and a separate `GoogleCalendarClient` for Google accounts.
- A family member connects their Google account once via the in-app settings panel; the token
  is refreshed silently by the GoogleSignIn SDK.
- Multiple Google accounts per device are out of scope for v1; one Google account per device.
- Contract test stubs Google Calendar REST responses via URLProtocol; no network hit in CI.
- Keychain item is deleted when the user disconnects their Google account in settings.

**Alternatives considered**:
- EventKit CalDAV for Google Calendar — iOS does not expose CalDAV accounts from Settings to
  third-party apps via EventKit in iOS 17+; rejected.
- Raw OAuth 2.0 without SDK — unnecessary complexity; GoogleSignIn SDK is maintained by Google.

---

## Decision 4: Spotify Jam Session

**Decision**: Spotify iOS SDK (`SpotifyiOS`) for authentication and Group Session (Jam)
initiation; CoreImage `CIFilter.qrCodeGenerator` to render the Jam invite URL as a QR code
on-screen. Jam creation requires the Spotify app to be installed on the initiating device.

**Rationale**: The Spotify Web API does not expose a public endpoint for creating Jam sessions
as of the plan date. The Spotify iOS SDK's `SPTSessionManager` and App Remote (`SPTAppRemote`)
allow Sonas to communicate with the locally installed Spotify app and initiate a Group Session
(Jam). The SDK returns a session join URL/URI that Sonas encodes as a QR code using CoreImage
(no third-party QR library needed).

**Implementation notes**:
- Prerequisite: Spotify app installed on the initiating device.
- Auth flow: `SPTConfiguration` → `SPTSessionManager.initiateSession` → OAuth via
  ASWebAuthenticationSession (Spotify app or web fallback).
- Scopes required: `user-read-playback-state`, `user-modify-playback-state`,
  `streaming`, `app-remote-control`.
- Jam (Group Session): initiated via `SPTAppRemote` command; SDK returns a join URL.
- QR generation: `CIFilter(name: "CIQRCodeGenerator")` with the join URL string; rendered
  to `UIImage` / SwiftUI `Image` at 200×200pt.
- If Spotify is not installed: `JamPanelView` shows a "Install Spotify to use Jam" prompt
  and deep-link to App Store.
- If no Spotify account connected: OAuth prompt is presented within Sonas.
- Jam ending: `SPTAppRemote` stop-group-session command; QR removed from view.
- Contract test: stubs `SPTSessionManager` responses via protocol injection.

**Alternatives considered**:
- Spotify Web API Jam endpoint — not yet public; monitored for future adoption.
- Manual copy-paste of Jam link — poor UX; rejected for v1.
- Third-party QR library (QRCode, EFQRCode) — CoreImage handles all requirements without
  adding a dependency.

---

## Decision 5: PhotoKit iCloud Shared Album Access

**Decision**: `PHAssetCollection` with `PHAssetCollectionType.album` and
`PHAssetCollectionSubtype.albumCloudShared` to enumerate iCloud Shared Albums; `PHImageManager`
for thumbnail and full-size image loading with `PHImageRequestOptions.deliveryMode = .opportunistic`.

**Rationale**: PhotoKit is the native Apple framework for photo library access on all Apple
platforms. `albumCloudShared` subtype enumerates iCloud Shared Albums without any additional
auth or OAuth — access is governed by the device's iCloud account (satisfying FR-018/FR-019).
`PHImageManager` handles caching and progressive loading natively.

**Implementation notes**:
- Permission: `NSPhotoLibraryUsageDescription` in Info.plist; request `.readWrite` access
  (`.addOnly` is insufficient to read photos).
- Album selection: first launch prompts user to select a shared album from the picker; stored
  as `PHAssetCollection.localIdentifier` in `AppConfiguration`.
- Fetch: `PHAsset.fetchAssets(in: album, options: PHFetchOptions())` sorted by
  `creationDate` descending; limit to 20 most recent.
- Thumbnail: `PHImageManager.requestImage(for:targetSize:contentMode:options:)` at 400×400pt.
- Full-screen tap: `PHImageManager.requestImage` at screen resolution.
- `PHPhotoLibraryChangeObserver` handles real-time album changes (deleted photos) without crash.
- Multi-platform: PhotoKit available on iOS, iPadOS, macOS (14+). watchOS and tvOS use a
  cached subset pushed via WatchConnectivity / CloudKit asset.

**Alternatives considered**:
- Google Photos API — requires Google account; rejected (iCloud Shared Album selected in Q4).
- CloudKit asset storage for photos — redundant when PhotoKit already handles iCloud sync.

---

## Decision 6: Todoist REST API Integration

**Decision**: Todoist REST API v2 (`https://api.todoist.com/rest/v2/`) authenticated via
personal API token (OAuth 2.0 flow available but adds complexity for a single-account household
app); token stored in iOS Keychain.

**Rationale**: Todoist REST v2 is the current stable API. A personal API token is the simplest
authentication method and appropriate for a household app where one family member owns the
Todoist account. OAuth 2.0 is available but requires redirect URI configuration and adds an
extra setup step for minimal benefit in the single-household use case.

**Key endpoints**:
- `GET /projects` — list all projects (filtered to user-selected family projects)
- `GET /tasks?project_id={id}` — fetch open tasks per project
- `POST /tasks/{id}/close` — mark task complete

**Implementation notes**:
- Rate limit: 1,000 requests per 15 minutes per token — well within household use.
- Pagination: tasks endpoint returns up to 100 items; for projects >100 tasks, use
  cursor-based pagination (`?cursor=`) and render paginated in `TasksPanelView`.
- Foreground refresh: `Timer.scheduledTimer(interval: 300)` (5 minutes).
- Background refresh: `BGAppRefreshTask` (iOS may schedule at ≥15-min intervals).
- Optimistic UI: task marked complete immediately in SwiftData cache; API call in background;
  rollback on error with user-visible toast.
- Contract test: `URLProtocol` stub returning fixture JSON for `/projects` and `/tasks`.

**Alternatives considered**:
- Todoist Sync API v9 — more powerful (real-time sync) but significantly more complex;
  deferred to post-v1.
- Webhooks — requires a server to receive them; violates no-backend constraint; rejected.

---

## Decision 7: Background Refresh Strategy

**Decision**: Two-tier refresh — foreground `Timer` every 5 minutes (Todoist, weather, AQI)
+ `BGAppRefreshTask` registered for best-effort background refresh.

**Rationale**: iOS enforces a minimum background app refresh interval of approximately 15
minutes and may not honour shorter intervals. The spec requires Todoist to refresh "at least
every 5 minutes" (FR-009) — this is achievable only when the app is in the foreground. In
background, `BGAppRefreshTask` is the correct mechanism; the system schedules it adaptively.

**Implementation notes**:
- `BGTaskScheduler.register(forTaskWithIdentifier: "com.sonas.refresh")` in `AppDelegate`.
- On task execution: fetch Todoist tasks, weather snapshot, AQI; update SwiftData cache.
- Schedule next `BGAppRefreshTask` at the end of each task execution.
- CloudKit location updates use `CKQuerySubscription` (push-based; no polling overhead).
- Calendar events: refreshed on foreground; EventKit change notifications for iCloud;
  Google Calendar polled every 5 minutes in foreground.

---

## Decision 8: SwiftUI Multi-Platform Layout Strategy

**Decision**: Single SwiftUI codebase using `horizontalSizeClass` / `verticalSizeClass`
environment values and `AdaptiveLayout` container for iPhone/iPad/Mac; separate minimal
target views for watchOS and tvOS.

**Rationale**: SwiftUI's `horizontalSizeClass` (`.compact` vs `.regular`) handles
iPhone-to-iPad-to-Mac layout transitions without `#if os()` directives in view code.
watchOS and tvOS have sufficiently different interaction models to warrant separate entry
views (`WatchDashboardView`, `TVDashboardView`) that share the same service layer.

**Layout breakpoints**:
- `.compact` horizontal: iPhone portrait → single-column scroll
- `.regular` horizontal, `.compact` vertical: iPhone landscape → two-column
- `.regular` horizontal, `.regular` vertical: iPad / Mac → three-column grid

**Panel grid on iPad/Mac**:
```
┌─────────────────┬────────────────┬───────────────┐
│  Clock + Date   │   Location     │   Events      │
├─────────────────┼────────────────┼───────────────┤
│  Weather        │   Photos       │   Tasks       │
├─────────────────┴────────────────┼───────────────┤
│  Spotify Jam                     │               │
└──────────────────────────────────┴───────────────┘
```

**watchOS**: `WatchDashboardView` uses `TimelineView` for clock + `.containerBackground`
for complication. Shows time, ≤2 family locations (first-name only), next event title.

**tvOS**: `TVDashboardView` uses `LazyVGrid` in full-screen with focus engine. No interactive
task completion or Jam initiation (spec assumption: tvOS is passive display).

---

## Decision 9: On-Device Caching with SwiftData

**Decision**: SwiftData (iOS 17+) as the local cache layer for all panel data; one `@Model`
per panel type; all models include a `lastUpdated: Date` field surfaced in the UI.

**Rationale**: SwiftData is Apple's modern replacement for CoreData, available on iOS 17+
(aligned with the iOS 17 minimum for Swift Testing). It provides automatic persistence,
CloudKit sync (not used here — data is transient panel cache), and `@Query` integration with
SwiftUI. No external database library is needed.

**Cache models**: `CachedWeatherSnapshot`, `CachedLocationSnapshot`, `CachedCalendarEvent`,
`CachedTask`, `CachedPhoto` (metadata only; full images in `NSCache`), `CachedJamSession`.

**Eviction policy**: Weather/AQI: discard if >1 hour old. Calendar events: discard if
past end time. Tasks: discard if >24 hours old (force-refresh on next foreground). Location:
discard if >5 minutes old (show "last seen" label instead). Photos: metadata cached; images
loaded fresh via PhotoKit on each session.
