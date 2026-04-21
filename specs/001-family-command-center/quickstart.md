# Quickstart: Sonas — iOS Family Command Center

## Contents

<!--
Table of contents updated via:
uvx --from md-toc md_toc --in-place github -- quickstart.md
-->
<!--TOC-->

- [Quickstart: Sonas — iOS Family Command Center](#quickstart-sonas--ios-family-command-center)
  - [Contents](#contents)
  - [Initial setup with mock data](#initial-setup-with-mock-data)
    - [Prerequisites](#prerequisites)
    - [Clone and install requirements](#clone-and-install-requirements)
    - [Configure project.yml](#configure-projectyml)
    - [Configure signing and mock data](#configure-signing-and-mock-data)
    - [Run on simulator](#run-on-simulator)
    - [First launch checklist (mock data)](#first-launch-checklist-mock-data)
  - [Full setup with external service credentials](#full-setup-with-external-service-credentials)
    - [Configure signing](#configure-signing)
    - [Google Calendar](#google-calendar)
    - [Spotify](#spotify)
    - [Todoist](#todoist)
    - [Run on simulator again](#run-on-simulator-again)
    - [CloudKit schema setup (first run)](#cloudkit-schema-setup-first-run)
    - [Launch checklist (real credentials)](#launch-checklist-real-credentials)
  - [Run linters and tests](#run-linters-and-tests)
    - [Linters](#linters)
    - [Tests](#tests)
    - [Testing on iPad / Mac](#testing-on-ipad--mac)
  - [Project structure](#project-structure)
  - [Troubleshooting](#troubleshooting)
    - [Common problems and fixes](#common-problems-and-fixes)
    - [Where to get help](#where-to-get-help)

<!--TOC-->

## Initial setup with mock data

### Prerequisites

| Tool                      | Version                                       | Install                      |
| ------------------------- | --------------------------------------------- | ---------------------------- |
| macOS                     | 15 (Sequoia) or later                         | Mac App Store                |
| Xcode                     | 16+                                           | Mac App Store                |
| Swift                     | 5.10+                                         | Included with Xcode          |
| iOS Simulator             | iOS 18                                        | Xcode → Settings → Platforms |
| Apple Developer account   | Active (free tier works for simulator)        | developer.apple.com          |
| WeatherKit entitlement    | Required for device/TestFlight                | Apple Developer portal       |
| iCloud account            | Required for CloudKit location relay + photos | System Preferences           |
| Spotify developer account | Required for Jam feature                      | developer.spotify.com        |
| Google Cloud project      | Required for Google Calendar OAuth            | console.cloud.google.com     |
| Todoist account           | Required for tasks feature                    | todoist.com                  |
| Mise                      | Any                                           | mise.jdx.dev                 |

- Once installed, open Xcode once so it can finish setting up its command-line tools. A dialog will appear — click
  **Install**.
- Verify everything is ready by opening **Terminal** and running:
  ```bash
  xcode-select -p
  ```
  You should see something like `/Applications/Xcode.app/Contents/Developer`. If you see an error, run:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  ```

### Clone and install requirements

```bash
git clone https://github.com/proinsias/sonas.git
cd sonas

mise install
prek install --allow-missing-config --overwrite --prepare-hooks

# xcodegen is the tool that turns `project.yml` into the Xcode project file.
# Verify it installed:
xcodegen --version
# Should print something like: XcodeGen Version: 2.45.3
```

### Configure project.yml

`project.yml` is gitignored. Copy the template:

```bash
cp project.yml.template project.yml
```

Open `project.yml` in a text editor and replace every `YOUR_*` placeholder. For example:

| Placeholder              | Where to find the value                                                             |
| ------------------------ | ----------------------------------------------------------------------------------- |
| `YOUR_TEAM_ID`           | Xcode → Preferences → Accounts → your Apple ID → Team ID (10-character string)      |
| `com.yourteam`           | Choose a reverse-DNS prefix unique to you, e.g. `com.smithfamily`                   |
| `YOUR_SPOTIFY_CLIENT_ID` | [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) — see Step 5 |
| `YOUR_GOOGLE_CLIENT_ID`  | [Google Cloud Console](https://console.cloud.google.com) — see Step 6               |

Then generate the Xcode project:

```bash
xcodegen generate
```

This creates `Sonas.xcodeproj` and generates `Sonas/Info.plist` (and the Watch/TV equivalents) from your `project.yml`.
Re-run this command any time you add new Swift files or change `project.yml`.

Now open the project in Xcode:

```bash
open Sonas.xcodeproj
```

Xcode will open. The first time it will resolve Swift package dependencies (GoogleSignIn and SpotifyiOS) — this takes
1–3 minutes. You will see a spinner in the top bar. **Wait for it to finish before doing anything else.**

### Configure signing and mock data

1. In Xcode, select the `Sonas` target → Signing & Capabilities.
2. Set Team to your Apple Developer team.
3. Bundle ID: use the prefix you set in `project.yml` (e.g. `com.yourteam.sonas`).

Set these environment variables in the Xcode scheme (Product → Scheme → Edit Scheme → Run → Arguments → Environment
Variables) to develop offline without any credentials:

| Variable            | Value | Effect                                                |
| ------------------- | ----- | ----------------------------------------------------- |
| `USE_MOCK_LOCATION` | `1`   | Use `LocationServiceMock` with fixture family members |
| `USE_MOCK_WEATHER`  | `1`   | Use `WeatherServiceMock` with fixture snapshot        |
| `USE_MOCK_CALENDAR` | `1`   | Use fixture events; skip EventKit permission          |
| `USE_MOCK_TASKS`    | `1`   | Use fixture Todoist tasks; skip network               |
| `USE_MOCK_PHOTOS`   | `1`   | Use bundled test images; skip photo permission        |
| `USE_MOCK_JAM`      | `1`   | Use `JamServiceMock`; skip Spotify SDK                |

Setting all six mock flags enables a fully offline development session with no real credentials.

### Run on simulator

```bash
# Build and run on iPhone 16 Pro simulator (iOS 18)
xcodebuild \
    -scheme Sonas \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -configuration Debug \
    build
# Or press ⌘R in Xcode with the iPhone 16 Pro simulator selected
```

### First launch checklist (mock data)

- [ ] The clock panel shows the current time and it ticks every second.
- [ ] The Family panel shows three mock members: Alice (Dublin), Bob (Ranelagh), Carol (Location unavailable — this is
      intentional in the mock).
- [ ] The Events panel shows three upcoming mock events.
- [ ] The Weather panel shows temperature, humidity, wind, pressure, AQI, sunrise/sunset, moon phase, and a 7-day
      forecast strip.
- [ ] The Tasks panel shows tasks grouped under "Home" and "Admin" projects.
- [ ] The Photos panel shows a rotating placeholder gallery.
- [ ] The Jam panel shows a "Start Jam" button. Tap it — a QR code should appear.
- [ ] Tapping the gear icon (⚙) opens a Settings sheet.

If any panel shows an error instead of mock data, double-check that the environment variables have been set correctly.

## Full setup with external service credentials

### Configure signing

1. In Xcode, select the `Sonas` target → Signing & Capabilities.
1. Enable **WeatherKit** capability (requires Apple Developer portal approval — can take minutes to hours; simulator
   fallback available via `WeatherServiceMock`). Go to [developer.apple.com](https://developer.apple.com) →
   Certificates, IDs & Profiles → Identifiers → your app's Bundle ID → enable **WeatherKit**.
1. Enable **CloudKit** → container `iCloud.com.yourteam.sonas` (auto-derived from your bundle ID at runtime). Works
   automatically once all family members have the app installed and have granted Location permission. No external
   account needed beyond iCloud.
1. Enable **Background Modes** → Background fetch, Remote notifications.
1. Enable **Push Notifications** (required by CloudKit subscriptions)
1. Repeat these steps for the **SonasTests**, **SonasUITests**, **WatchSonas**, and **TVSonas** targets, using the same
   Team and a matching bundle ID suffix.
1. In `project.yml`, uncomment the corresponding capability and entitlement lines.

### Google Calendar

1. Go to [Google Cloud Console](https://console.cloud.google.com).
2. Create a project → Enable "Google Calendar API".
3. Create OAuth 2.0 credentials (iOS app type).
4. Note your **Client ID**.
5. Download `GoogleService-Info.plist` and drag it into the `Sonas/` folder in Xcode.
6. In `project.yml`, replace `YOUR_GOOGLE_CLIENT_ID` in the URL scheme entry with your client ID, then re-run
   `xcodegen generate`.

Google Calendar OAuth is handled by the GoogleSignIn-iOS SDK at runtime. Users sign in from within the app.

### Spotify

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Create an app → note **Client ID**.
3. Add redirect URI: `sonas://spotify-callback`.
4. In `project.yml`, set `SPTClientID` to your client ID, then re-run `xcodegen generate`.

The Spotify iOS SDK requires the Spotify app to be installed on the device. The Jam panel shows a "Connect Spotify"
prompt if the SDK is unavailable.

### Todoist

No build-time configuration. Users enter their personal API token at runtime in Settings → Connect Todoist. The token
can be found at [todoist.com/app/settings/integrations](https://todoist.com/app/settings/integrations). The token is
stored in the device Keychain, not in the app bundle.

### Run on simulator again

Repeat the previous `xcodebuild` command.

### CloudKit schema setup (first run)

On the very first launch against a new CloudKit container, the app creates the `FamilyLocation` record type
automatically (development containers only). Verify it exists in the
[CloudKit Dashboard](https://icloud.developer.apple.com/dashboard):

```text
FamilyLocation
  ├── displayName    (String)
  ├── latitude       (Double)
  ├── longitude      (Double)
  ├── placeName      (String)
  └── recordedAt     (Date/Time)
```

Before TestFlight or App Store submission, export the schema from the development container and promote it to production
via the CloudKit Dashboard.

### Launch checklist (real credentials)

Once the app works with mocks, remove the environment variables one at a time to connect real services. Each service has
a clear "connect" UI in the Settings sheet.

- [ ] App opens and shows all panels in loading state within 500ms.
- [ ] Clock panel shows current time updating every second.
- [ ] Weather panel loads within 2s for configured home location.
- [ ] Location panel prompts "Enable location in Settings" if permission not granted.
- [ ] Calendar panel shows iCloud events (EventKit permission requested on first launch).
- [ ] Tasks panel shows "Connect Todoist" if not yet configured.
- [ ] Photo gallery panel shows "Select a shared album" if not yet configured.
- [ ] Jam panel shows "Connect Spotify" if Spotify not authenticated.
- [ ] Airplane mode: all panels show cached data with "Last updated" labels.

## Run linters and tests

### Linters

Prek (An optimized version of pre-commit) runs automatically on `git commit` once installed. To run all hooks manually
across every file:

```bash
mise run lint
```

GitHub Actions runs the same linting suite on every push and pull request via the `lint.yml` workflow.

### Tests

The test suite follows a mandatory 3-tier strategy using **Swift Testing** (unit and contract tests) and **XCTest**
(integration and UI tests). Contract tests stub the network layer via `URLProtocol` — no live credentials are needed.

```bash
# Tier 1: Unit + Contract tests (no device required)
mise run tests-unit

# Tier 2: Integration tests (require iCloud sign-in in simulator + test CloudKit container)
mise run tests-integration

# Tier 3: UI tests
mise run tests-ui
```

GitHub Actions runs the full 3-tier test suite on every push and pull request via the `tests.yml` workflow.

### Testing on iPad / Mac

- Select an iPad simulator (e.g., iPad Pro 13-inch) → the dashboard switches to the 3-column grid layout automatically
  via `horizontalSizeClass == .regular`.
- For Mac (designed for iPad): Product → Destination → My Mac (Designed for iPad). Mouse/keyboard navigation should
  reach all controls.

## Project structure

Here is a map of the key folders so you know where to find things:

```text
Sonas/
├── App/
│   ├── SonasApp.swift          ← App entry point and background task setup
│   └── AppConfiguration.swift  ← All user settings (home location, tokens)
│
├── Features/                   ← One folder per dashboard panel
│   ├── Dashboard/              ← Root view + view model
│   ├── Clock/                  ← Live clock (TimelineView)
│   ├── Location/               ← Family member locations (CloudKit)
│   ├── Weather/                ← WeatherKit + AQI
│   ├── Calendar/               ← EventKit + Google Calendar
│   ├── Tasks/                  ← Todoist REST API
│   ├── Photos/                 ← iCloud Shared Album (PhotoKit)
│   ├── SpotifyJam/             ← Spotify Jam QR code
│   └── Settings/               ← Settings sheet
│
├── Shared/
│   ├── Components/             ← PanelView, ErrorStateView, LoadingStateView
│   ├── DesignSystem/           ← Colors, Typography, Icons
│   ├── Cache/                  ← SwiftData on-device cache
│   ├── Logging/                ← SonasLogger (OSLog wrapper)
│   ├── Mocks/                  ← Fake implementations (used in tests + mock mode)
│   ├── Models/                 ← Data structs (never depend on UI)
│   └── Extensions/             ← View+Accessibility helpers
│
└── Platform/
    ├── Watch/                  ← Apple Watch compact view
    └── TV/                     ← Apple TV full-screen view

SonasTests/
├── Contract/                   ← API contract tests (URLProtocol stubs)
├── Integration/                ← Multi-layer tests (service + view model)
├── Performance/                ← XCTest measure{} baselines
└── Unit/                       ← Single-class unit tests

SonasUITests/                   ← Full end-to-end UI tests
```

## Troubleshooting

### Common problems and fixes

<!-- editorconfig-checker-disable -->

| Problem                                                          | Fix                                                                                                                                                                        |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `xcodegen: command not found`                                    | Run `brew install xcodegen`, then close and reopen Terminal                                                                                                                |
| Packages don't resolve ("Failed to fetch")                       | In Xcode: File → Packages → Reset Package Caches                                                                                                                           |
| "Signing certificate … not found"                                | Follow Step 7 again; make sure your Apple ID is signed in                                                                                                                  |
| WeatherKit build error                                           | Keep `USE_MOCK_WEATHER=1` until you have a paid developer account                                                                                                          |
| WeatherKit returns no data in simulator                          | WeatherKit approval can take time after first enabling it. Use `USE_MOCK_WEATHER=1` while waiting.                                                                         |
| CloudKit container not found                                     | Ensure the container name in the Apple Developer portal exactly matches `iCloud.<your-bundle-id>`. The app derives this automatically from `Bundle.main.bundleIdentifier`. |
| CloudKit "No schema" error on first real-device run              | Normal — CloudKit auto-creates the schema on first launch in development. Check CloudKit Dashboard to confirm the `FamilyLocation` record type appeared                    |
| `xcodegen generate` adds duplicate files                         | This can happen if you moved a file. Run `git status` to find the duplicate, then delete the orphan from disk                                                              |
| Build fails after adding a new `.swift` file                     | Re-run `xcodegen generate` — new files are not auto-discovered                                                                                                             |
| "Entitlement com.apple.developer.weatherkit not found" on device | Enable WeatherKit in the Apple Developer portal for your Bundle ID                                                                                                         |
| "Failed to register bundle identifier"                           | The bundle ID is taken. Add initials or a unique suffix.                                                                                                                   |
| Google Sign-In fails                                             | Confirm the URL scheme in `project.yml` matches the full client ID from Google Cloud Console, and that the redirect URI is registered.                                     |

<!-- editorconfig-checker-enable -->

### Where to get help

- **Spec and architecture**: `specs/001-family-command-center/` — start with `spec.md` for requirements and `plan.md`
  for the technical design.
- **Task list**: `specs/001-family-command-center/tasks.md` — each task has a file path and acceptance criteria.
- **Apple documentation**: [developer.apple.com/documentation](https://developer.apple.com/documentation)
- **SwiftUI tutorials**: [developer.apple.com/tutorials/swiftui](https://developer.apple.com/tutorials/swiftui)
