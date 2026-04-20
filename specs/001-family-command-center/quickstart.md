# Quickstart: Sonas — iOS Family Command Center

---

## Prerequisites

| Tool                      | Version                                       | Install                      |
| ------------------------- | --------------------------------------------- | ---------------------------- |
| Xcode                     | 16+                                           | Mac App Store                |
| iOS Simulator             | iOS 18                                        | Xcode → Settings → Platforms |
| Apple Developer account   | Active (free tier works for simulator)        | developer.apple.com          |
| WeatherKit entitlement    | Required for device/TestFlight                | Apple Developer portal       |
| iCloud account            | Required for CloudKit location relay + photos | System Preferences           |
| Spotify developer account | Required for Jam feature                      | developer.spotify.com        |
| Google Cloud project      | Required for Google Calendar OAuth            | console.cloud.google.com     |
| Todoist account           | Required for tasks feature                    | todoist.com                  |

---

## 1. Clone

```bash
git clone https://github.com/proinsias/sonas.git
cd sonas
```

---

## 2. Configure project.yml

`project.yml` is gitignored. Copy the template and fill in your values before generating the Xcode project:

```bash
cp project.yml.template project.yml
# Edit project.yml — replace YOUR_TEAM_ID, com.yourteam, YOUR_SPOTIFY_CLIENT_ID, YOUR_GOOGLE_CLIENT_ID
xcodegen generate
open Sonas.xcodeproj
```

---

## 3. Configure signing

1. In Xcode, select the `Sonas` target → Signing & Capabilities.
2. Set Team to your Apple Developer team.
3. Bundle ID: use the prefix you set in `project.yml` (e.g. `com.yourteam.sonas`).
4. Enable **WeatherKit** capability (requires Apple Developer portal approval — can take minutes to hours; simulator
   fallback available via `WeatherServiceMock`).
5. Enable **CloudKit** → container `iCloud.com.yourteam.sonas` (auto-derived from your bundle ID at runtime).
6. Enable **Background Modes** → Background fetch, Remote notifications.

---

## 4. Configure external service credentials

### Google Calendar

1. Go to [Google Cloud Console](https://console.cloud.google.com).
2. Create a project → Enable "Google Calendar API".
3. Create OAuth 2.0 credentials (iOS app type).
4. Note your **Client ID**.
5. In `project.yml`, replace `YOUR_GOOGLE_CLIENT_ID` in the URL scheme entry with your client ID, then re-run
   `xcodegen generate`.

### Spotify

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Create an app → note **Client ID**.
3. Add redirect URI: `sonas://spotify-callback`.
4. In `project.yml`, set `SPTClientID` to your client ID, then re-run `xcodegen generate`.

### Todoist

- No build-time configuration. Users enter their personal API token at runtime in Settings → Connect Todoist.
- For contract tests: set `TODOIST_TEST_TOKEN` environment variable in the test scheme.

---

## 5. Run on simulator

```bash
# Build and run on iPhone 16 Pro simulator (iOS 18)
xcodebuild -scheme Sonas -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug build
# Or press ⌘R in Xcode with the iPhone 16 Pro simulator selected
```

**Feature flags for development** (set in scheme environment variables): | Variable | Value | Effect | |---|---|---| |
`USE_MOCK_LOCATION` | `1` | Use `LocationServiceMock` with fixture family members | | `USE_MOCK_WEATHER` | `1` | Use
`WeatherServiceMock` with fixture snapshot | | `USE_MOCK_CALENDAR` | `1` | Use fixture events; skip EventKit permission
| | `USE_MOCK_TASKS` | `1` | Use fixture Todoist tasks; skip network | | `USE_MOCK_PHOTOS` | `1` | Use bundled test
images; skip photo permission | | `USE_MOCK_JAM` | `1` | Use `JamServiceMock`; skip Spotify SDK |

Setting all six mock flags enables a fully offline development session with no real credentials.

---

## 6. Run tests

```bash
# All unit + contract tests (no device required)
xcodebuild test -scheme SonasTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Integration tests (require iCloud sign-in in simulator + test CloudKit container)
xcodebuild test -scheme SonasIntegrationTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# UI tests
xcodebuild test -scheme SonasUITests -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

Coverage gate: `xcodebuild test ... -enableCodeCoverage YES` — CI fails if `Sonas/` coverage drops below 80%.

---

## 7. First launch checklist (on device or simulator with real credentials)

- [ ] App opens and shows all panels in loading state within 500ms.
- [ ] Clock panel shows current time updating every second.
- [ ] Weather panel loads within 2s for configured home location.
- [ ] Location panel prompts "Enable location in Settings" if permission not granted.
- [ ] Calendar panel shows iCloud events (EventKit permission requested on first launch).
- [ ] Tasks panel shows "Connect Todoist" if not yet configured.
- [ ] Photo gallery panel shows "Select a shared album" if not yet configured.
- [ ] Jam panel shows "Connect Spotify" if Spotify not authenticated.
- [ ] Airplane mode: all panels show cached data with "Last updated" labels.

---

## 8. Testing on iPad / Mac

- Select an iPad simulator (e.g., iPad Pro 13-inch) → the dashboard switches to the 3-column grid layout automatically
  via `horizontalSizeClass == .regular`.
- For Mac (designed for iPad): Product → Destination → My Mac (Designed for iPad). Mouse/keyboard navigation should
  reach all controls.

---

## 9. CloudKit schema setup (first run)

CloudKit schema is created automatically on first app launch (development containers only). For production, export the
schema via CloudKit Dashboard and promote to production before TestFlight submission.

Record type to verify in CloudKit Dashboard after first run:

```
FamilyLocation
  ├── displayName    (String)
  ├── latitude       (Double)
  ├── longitude      (Double)
  ├── placeName      (String)
  └── recordedAt     (Date/Time)
```
