# Development Guide: Getting Sonas Running in Xcode

**For**: Developers new to Xcode / iOS development  
**Branch**: `001-implement-family-command-center`  
**Last updated**: 2026-04-07

This guide walks you from a fresh clone to a fully running app in the iOS Simulator, with no real credentials required
for the first run.

---

## Before you start — what you need

<!-- editorconfig-checker-disable -->

| What                                                                         | Where to get it                | Free? |
| ---------------------------------------------------------------------------- | ------------------------------ | ----- |
| A Mac running macOS 15 (Sequoia) or later                                    | Your computer                  | —     |
| Xcode 16                                                                     | Mac App Store → search "Xcode" | ✅    |
| An Apple ID (does **not** need to be a paid developer account for simulator) | appleid.apple.com              | ✅    |
| Homebrew (command-line package manager)                                      | brew.sh                        | ✅    |

<!-- editorconfig-checker-enable -->

> **How long does Xcode take to install?** It is roughly 12 GB — allow 20–40 minutes on a fast connection.

---

## Step 1 — Install Xcode

1. Open the **Mac App Store**.
2. Search for **Xcode** and click **Get** → **Install**.
3. Once installed, open Xcode once so it can finish setting up its command-line tools. A dialog will appear — click
   **Install**.
4. Verify everything is ready by opening **Terminal** and running:
   ```
   xcode-select -p
   ```
   You should see something like `/Applications/Xcode.app/Contents/Developer`. If you see an error, run:
   ```
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

---

## Step 2 — Install Homebrew (if not already installed)

Open **Terminal** (press `⌘ Space`, type "Terminal", press Return) and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the on-screen prompts. When it finishes, close and reopen Terminal.

---

## Step 3 — Install xcodegen

xcodegen is the tool that turns `project.yml` into the Xcode project file.

```bash
brew install xcodegen
```

Verify it installed:

```bash
xcodegen --version
# Should print something like: XcodeGen Version: 2.45.3
```

---

## Step 4 — Get the code

In Terminal:

```bash
git clone https://github.com/proinsias/sonas.git
cd sonas
```

---

## Step 5 — Generate the Xcode project

The `.xcodeproj` is produced from `project.yml` — this is intentional so the project file doesn't clutter git diffs.

```bash
xcodegen generate --spec project.yml
```

You should see:

```
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at .../Sonas.xcodeproj
```

> **Do I need to run this again?** Yes, any time you add a new Swift file to the project or change `project.yml`. Just
> run `xcodegen generate` again from the repo root.

---

## Step 6 — Open the project in Xcode

```bash
open Sonas.xcodeproj
```

Xcode will open. The first time it will resolve Swift package dependencies (GoogleSignIn and SpotifyiOS) — this takes
1–3 minutes. You will see a spinner in the top bar. **Wait for it to finish before doing anything else.**

---

## Step 7 — Set your signing team

Before the app can build (even for the simulator) you need to tell Xcode which Apple ID to use.

1. In the Xcode navigator on the left, click the **Sonas** project (the blue icon at the very top).
2. In the main editor, click the **Sonas** target (under TARGETS).
3. Click the **Signing & Capabilities** tab.
4. Under **Team**, click the dropdown and select your Apple ID. If it's not listed, click **Add an Account…** and sign
   in with your Apple ID.
5. Xcode will automatically fill in a Bundle Identifier — change it to match the `bundleIdPrefix` you set in
   `project.yml` (e.g. `com.yourteam.sonas`).
6. Repeat steps 2–5 for the **SonasTests**, **SonasUITests**, **WatchSonas**, and **TVSonas** targets, using the same
   Team and a matching bundle ID suffix.

> **"Failed to register bundle identifier" error?** The bundle ID you chose is already taken by another app on Apple's
> servers. Add initials or a unique suffix to make it unique (e.g. `com.smithfamily.sonas`).

---

## Step 8 — Configure project.yml

`project.yml` is gitignored — each developer keeps their own local copy with their own credentials.

1. Copy the template:
   ```bash
   cp project.yml.template project.yml
   ```
2. Open `project.yml` in a text editor:
   ```bash
   open -e project.yml
   ```
3. Replace every `YOUR_*` placeholder:
   - `YOUR_TEAM_ID` — find it in Xcode: project → Signing & Capabilities → Team dropdown (the 10-character ID in
     parentheses)
   - `com.yourteam` — your reverse-DNS bundle ID prefix (e.g. `com.smithfamily`)
   - `YOUR_SPOTIFY_CLIENT_ID` — from developer.spotify.com/dashboard
   - `YOUR_GOOGLE_CLIENT_ID` — from console.cloud.google.com
4. Save the file and regenerate:
   ```bash
   xcodegen generate
   ```

---

## Step 9 — Run the app in the simulator (no real credentials needed)

The app supports "mock mode" — all six data sources return realistic fake data so you can develop without any real
accounts.

### 9a — Enable mock mode in the scheme

1. In Xcode, click the scheme selector at the top (next to the play/stop buttons). It shows something like **Sonas >
   iPhone 16 Pro**.
2. Click it and choose **Edit Scheme…**
3. On the left, select **Run**.
4. Click the **Arguments** tab.
5. Under **Environment Variables**, click **+** and add each of these (Name + Value):

   | Name                | Value |
   | ------------------- | ----- |
   | `USE_MOCK_LOCATION` | `1`   |
   | `USE_MOCK_WEATHER`  | `1`   |
   | `USE_MOCK_CALENDAR` | `1`   |
   | `USE_MOCK_TASKS`    | `1`   |
   | `USE_MOCK_PHOTOS`   | `1`   |
   | `USE_MOCK_JAM`      | `1`   |

6. Click **Close**.

### 9b — Choose a simulator

In the scheme selector, choose **iPhone 16 Pro** (or any iPhone 17+).

### 9c — Build and run

Press **⌘R** (or click the ▶ Play button).

The first build takes 2–5 minutes. Subsequent builds are much faster.

The app should launch in the iOS Simulator showing all panels with sample data.

---

## Step 10 — Verify the first-launch checklist

Once the app is running, check each item:

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

If any panel shows an error instead of mock data, double-check Step 9a — the environment variables may not have been set
correctly.

---

## Step 11 — Run the tests

```bash
xcodebuild test \
    -scheme SonasTests \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -enableCodeCoverage YES \
    2>&1 | tail -20
```

All unit and contract tests run without any real credentials or internet connection. A passing run looks like:

```
** TEST SUCCEEDED **
```

> **Seeing a build error about WeatherKit?** The `WeatherService` requires a paid Apple Developer account for real data.
> In tests and mock mode, `WeatherServiceMock` is used instead — no entitlement needed. The error only appears if you
> try to call the real `WeatherService` on a simulator without the entitlement.

---

## Step 12 — Understand the project structure

Here is a map of the key folders so you know where to find things:

```
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

---

## Step 13 — Connect real data sources (optional)

Once the app works with mocks, remove the environment variables one at a time to connect real services. Each service has
a clear "connect" UI in the Settings sheet.

### Weather (WeatherKit)

Requires a **paid** Apple Developer account ($99/year).

1. Go to [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles → Identifiers → your app's
   Bundle ID → enable **WeatherKit**.
2. This can take a few minutes to propagate. In the meantime, keep `USE_MOCK_WEATHER=1`.

### Location (CloudKit)

Works automatically once all family members have the app installed and have granted Location permission. No external
account needed beyond iCloud.

### Google Calendar

1. Go to [console.cloud.google.com](https://console.cloud.google.com).
2. Create a project → enable "Google Calendar API".
3. Create an **OAuth 2.0 Client ID** of type "iOS app".
4. Download `GoogleService-Info.plist` and drag it into the `Sonas/` folder in Xcode.
5. In `project.yml`, update the `com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID` URL scheme with your actual client
   ID, then re-run `xcodegen generate`.

### Todoist

No build-time setup needed. In the running app, open **Settings → Connect Todoist** and paste your personal API token
(found at [todoist.com/app/settings/integrations](https://todoist.com/app/settings/integrations)).

### Spotify

1. Create an app at [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard).
2. Copy your Client ID.
3. In `project.yml`, set `SPTClientID` in the `Sonas` target's `info.properties`.
4. Re-run `xcodegen generate`.

### iCloud Shared Album (Photos)

No extra configuration. On first launch (with `USE_MOCK_PHOTOS` removed), the app prompts you to select an album from
your iCloud library.

---

## Common problems and fixes

<!-- editorconfig-checker-disable -->

| Problem                                                          | Fix                                                                                                                                                     |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `xcodegen: command not found`                                    | Run `brew install xcodegen`, then close and reopen Terminal                                                                                             |
| Packages don't resolve ("Failed to fetch")                       | In Xcode: File → Packages → Reset Package Caches                                                                                                        |
| "Signing certificate … not found"                                | Follow Step 7 again; make sure your Apple ID is signed in                                                                                               |
| WeatherKit build error                                           | Keep `USE_MOCK_WEATHER=1` until you have a paid developer account                                                                                       |
| CloudKit "No schema" error on first real-device run              | Normal — CloudKit auto-creates the schema on first launch in development. Check CloudKit Dashboard to confirm the `FamilyLocation` record type appeared |
| `xcodegen generate` adds duplicate files                         | This can happen if you moved a file. Run `git status` to find the duplicate, then delete the orphan from disk                                           |
| Build fails after adding a new `.swift` file                     | Re-run `xcodegen generate` — new files are not auto-discovered                                                                                          |
| "Entitlement com.apple.developer.weatherkit not found" on device | Enable WeatherKit in the Apple Developer portal for your Bundle ID                                                                                      |

<!-- editorconfig-checker-enable -->

---

## What to build next

The following tasks are still open (not yet implemented):

- **T082** — Offline "Last updated" badge: when the network is unavailable, `PanelView` should overlay a stale-data
  badge with a retry button. The hook point in `PanelView.swift` is already documented with a comment.

- **T092** — Expand `SettingsView` with: Todoist token entry, Spotify connect/disconnect, photo album picker, and
  temperature unit toggle. The shell is at `Sonas/Features/Settings/SettingsView.swift` — look for the
  `// T092 sections` comment.

- **T091** — Memory profiling with Instruments. Once you have a real device, profile the app with Leaks + Allocations
  while all six panels are active. Target: ≤150 MB peak RSS.

- **T086–T088** — Run the quickstart checklist, SwiftLint, and code coverage gate. These are manual validation steps
  described in `specs/001-family-command-center/quickstart.md`.

---

## Where to get help

- **Spec and architecture**: `specs/001-family-command-center/` — start with `spec.md` for requirements and `plan.md`
  for the technical design.
- **Task list**: `specs/001-family-command-center/tasks.md` — each task has a file path and acceptance criteria.
- **Apple documentation**: [developer.apple.com/documentation](https://developer.apple.com/documentation)
- **SwiftUI tutorials**: [developer.apple.com/tutorials/swiftui](https://developer.apple.com/tutorials/swiftui)
