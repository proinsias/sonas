# Sonas

**Sonas** (SUN-əs, from the Irish for _happiness_) is an iOS Family Command Center — a single always-on dashboard that
shows the whole family at a glance: where everyone is, what's coming up, what the weather looks like, shared photos, the
household task list, and a Spotify Jam QR code for shared listening.

---

## Contents

- [Features](#features)
- [Platform Support](#platform-support)
- [App Versions](#app-versions)
  - [Mockup — zero-API prototype](#mockup--zero-api-prototype)
  - [Full App — live integrations](#full-app--live-integrations)
- [Developer Guide](#developer-guide)
  - [Prerequisites](#prerequisites)
  - [Running the Mockup](#running-the-mockup)
  - [Building the Full App](#building-the-full-app)
  - [Configuration and Credentials](#configuration-and-credentials)
  - [Mock Feature Flags](#mock-feature-flags)
  - [Testing](#testing)
  - [Linting](#linting)

---

## Features

<!-- editorconfig-checker-disable -->

| Panel                | What it shows                                                                                                                   |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Date & Time**      | Live clock updating every second; full date in prose form                                                                       |
| **Family Locations** | Real-time positions for every family member with reverse-geocoded labels (e.g. "At home", "Near school")                        |
| **Upcoming Events**  | Next events from iCloud and Google Calendar, within a 48-hour window                                                            |
| **Weather**          | Current conditions, "feels like", humidity, wind, pressure, air quality index, sunrise/sunset, moon phase, and a 7-day forecast |
| **Family Tasks**     | Open Todoist tasks grouped by project; tap to mark complete (syncs back to Todoist)                                             |
| **Family Photos**    | Auto-rotating carousel of your iCloud Shared Album (5-second cadence, tap to browse)                                            |
| **Spotify Jam**      | QR code for starting a shared Spotify Jam session; tap to end                                                                   |

<!-- editorconfig-checker enable -->

The layout adapts automatically: a single column on iPhone, three columns on iPad and Mac.

---

## Platform Support

| Platform | Status                        | Minimum OS  |
| -------- | ----------------------------- | ----------- |
| iOS      | Primary target                | iOS 18+     |
| iPadOS   | Adaptive layout, same binary  | iPadOS 18+  |
| macOS    | Catalyst / native SwiftUI     | macOS 15+   |
| watchOS  | Planned — compact glance view | watchOS 11+ |
| tvOS     | Planned — large-screen layout | tvOS 18+    |

All platforms share a single Swift codebase. Layout differences are handled via SwiftUI's `horizontalSizeClass` — there
are no `#if os()` conditionals in view code.

---

## Service integrations

The production implementation, following the spec and plan in `specs/001-family-command-center/`. All panels fetch live
data through protocol-based service layers, with SwiftData caching so the dashboard renders immediately from cache while
fresh data loads in the background.

<!-- editorconfig-checker disable -->

| Service         | Technology                                      | Notes                                                                                                                              |
| --------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Family location | CloudKit private container                      | Each device publishes its own GPS; all devices subscribe via `CKQuerySubscription`. Apple's Find My API is not publicly available. |
| Weather         | Apple WeatherKit + Open-Meteo                   | WeatherKit for all conditions; Open-Meteo Air Quality API fills the AQI gap (free, no API key)                                     |
| Calendar        | EventKit (iCloud) + Google Calendar REST API v3 | iCloud via system EventKit; Google via GoogleSignIn-iOS OAuth 2.0                                                                  |
| Tasks           | Todoist REST API v2                             | Personal API token entered by user at runtime; optimistic completion with rollback                                                 |
| Photos          | PhotoKit — iCloud Shared Album                  | `PHAssetCollectionSubtype.albumCloudShared`; family selects album once in Settings                                                 |
| Spotify Jam     | Spotify iOS SDK (`SPTAppRemote`)                | QR code generated via CoreImage; requires Spotify app installed                                                                    |
| Cache           | SwiftData (on-device only)                      | TTL per data type: weather 1 hr, location 5 min, tasks 24 hr                                                                       |

<!-- editorconfig-checker-enable -->

There is no custom backend. All data is fetched on-device directly from Apple frameworks or third-party REST APIs.

---

## Developer Guide

### Prerequisites

| Tool                    | Version   | Notes                                   |
| ----------------------- | --------- | --------------------------------------- |
| Xcode                   | 16+       | 15+ works for the mockup only           |
| Swift                   | 5.10+     | Included with Xcode                     |
| iOS Simulator           | iOS 17+   | 18+ for full app; 17+ for mockup        |
| Apple Developer account | Free tier | Required for simulator; paid for device |
| Homebrew                | Any       | Required for pre-commit and SwiftLint   |

Install pre-commit and the Git hook:

```bash
brew install pre-commit
pre-commit install
```

---

### Running the Mockup

The mockup requires no credentials, no accounts, and no build configuration.

```bash
git clone https://github.com/proinsias/sonas.git
cd sonas
git checkout mockup/ios-dashboard
open Package.swift # Xcode opens the Swift package
```

In Xcode:

1. Select the **Sonas** scheme.
2. Choose an **iPhone 16 Pro** (or any iOS 17+) simulator.
3. Press **⌘R**.

The dashboard appears in under 30 seconds with all panels populated from static data.

---

### Building the Full App

```bash
cp project.yml.template project.yml   # then edit project.yml — replace all YOUR_* placeholders
xcodegen generate
open Sonas.xcodeproj
```

See [SETUP.md](SETUP.md) for full credential and capability setup instructions.

**Signing**: In Xcode → Targets → Sonas → Signing & Capabilities, select your development team. Use the bundle
identifier prefix you set in `project.yml` (e.g. `com.yourteam.sonas`).

**Required capabilities** (add in Signing & Capabilities, requires paid Apple Developer account):

- WeatherKit
- CloudKit (container auto-derived from bundle ID: `iCloud.<your-bundle-id>`)
- Push Notifications (required by CloudKit subscriptions)
- Background Modes → Background fetch, Remote notifications

Build and run on a simulator or device:

```bash
xcodebuild \
    -scheme Sonas \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -configuration Debug \
    build
```

---

### Configuration and Credentials

All build-time credentials are set in `project.yml` (copied from `project.yml.template`). Runtime credentials are
entered by each user in the app's Settings panel.

**Spotify** — set `SPTClientID` in `project.yml`, then run `xcodegen generate`:

```yaml
SPTClientID: 'YOUR_SPOTIFY_CLIENT_ID'
```

Register `sonas://spotify-callback` as a redirect URI in the
[Spotify Developer Dashboard](https://developer.spotify.com/dashboard).

**Google Calendar** — replace `YOUR_GOOGLE_CLIENT_ID` in the URL scheme entry in `project.yml`, then run
`xcodegen generate`:

```yaml
- 'com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID'
```

Create OAuth 2.0 credentials in the [Google Cloud Console](https://console.cloud.google.com/) with scope
`https://www.googleapis.com/auth/calendar.readonly`.

**Todoist** — no build-time setup. The user pastes their personal API token in Settings → Tasks.

**WeatherKit** — enable the WeatherKit capability in your Apple Developer portal (sandbox approval can take minutes to
hours on first use).

See [SETUP.md](SETUP.md) for step-by-step instructions including CloudKit container setup and per-family data isolation.

---

### Mock Feature Flags

Set these environment variables in the Xcode scheme (Product → Scheme → Edit Scheme → Run → Arguments → Environment
Variables) to develop offline without any credentials:

| Flag                  | Effect                                             |
| --------------------- | -------------------------------------------------- |
| `USE_MOCK_LOCATION=1` | Static family members; no CoreLocation or CloudKit |
| `USE_MOCK_WEATHER=1`  | Static weather snapshot; no WeatherKit entitlement |
| `USE_MOCK_CALENDAR=1` | Fixture events; no EventKit permission prompt      |
| `USE_MOCK_TASKS=1`    | Fixture task list; no Todoist network calls        |
| `USE_MOCK_PHOTOS=1`   | Bundled test images; no photo library permission   |
| `USE_MOCK_JAM=1`      | Mock Jam service; no Spotify SDK or app required   |

Setting all six flags enables fully offline development with no accounts, no permissions, and no network access.

---

### Testing

The test suite uses **Swift Testing** (unit and contract tests) and **XCTest** (UI tests). Contract tests stub the
network layer via `URLProtocol` — no live credentials are needed.

**Run unit and contract tests:**

```bash
xcodebuild test \
    -scheme SonasTests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**Run UI tests:**

```bash
xcodebuild test \
    -scheme SonasUITests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**Run with coverage:**

```bash
xcodebuild test \
    -scheme SonasTests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -enableCodeCoverage YES
```

The constitution mandates ≥ 80% line coverage on all source in `Sonas/`. Contract tests exist for every service protocol
(LocationService, WeatherService, CalendarService, TaskService, PhotoService, JamService, CacheService).

**Todoist contract tests** require a test token:

```bash
TODOIST_TEST_TOKEN=your_token xcodebuild test -scheme SonasTests ...
```

---

### Linting

Pre-commit runs automatically on `git commit` once installed. To run all hooks manually across every file:

```bash
pre-commit run --all-files
```

SwiftLint is excluded from the Linux pre-commit run (it requires macOS) and runs separately:

```bash
swiftlint lint --strict       # check
swiftlint lint --fix --format # auto-fix
```

GitHub Actions runs both on every push and pull request — see `.github/workflows/lint.yml`.
