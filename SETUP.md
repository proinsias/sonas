# Sonas — Setup Guide

This guide covers everything a new developer or family needs to go from a fresh clone to a fully running app. Each
family runs their own independent copy of Sonas backed by their own CloudKit container — no data is shared between
forks.

---

## Prerequisites

| What                            | Where                   | Free?                                      |
| ------------------------------- | ----------------------- | ------------------------------------------ |
| Mac running macOS 15 (Sequoia)+ | Your computer           | —                                          |
| Xcode 16+                       | Mac App Store           | ✅                                         |
| Apple ID                        | appleid.apple.com       | ✅                                         |
| Apple Developer account (paid)  | developer.apple.com     | ❌ Required for device/WeatherKit/CloudKit |
| Homebrew                        | brew.sh                 | ✅                                         |
| xcodegen                        | `brew install xcodegen` | ✅                                         |
| iCloud account                  | System Preferences      | ✅                                         |

> **Simulator-only / mock mode**: A free Apple ID is enough to run the app in the simulator with mock data. A paid Apple
> Developer account is required for WeatherKit, CloudKit (real location sync), and device installation.

---

## Step 1 — Clone the repo

```bash
git clone https://github.com/proinsias/sonas.git
cd sonas
git checkout main
```

---

## Step 2 — Configure project.yml

`project.yml` is gitignored so each developer maintains their own local copy. Start from the template:

```bash
cp project.yml.template project.yml
```

Open `project.yml` in a text editor and replace every `YOUR_*` placeholder:

| Placeholder              | Where to find the value                                                             |
| ------------------------ | ----------------------------------------------------------------------------------- |
| `YOUR_TEAM_ID`           | Xcode → Preferences → Accounts → your Apple ID → Team ID (10-character string)      |
| `com.yourteam`           | Choose a reverse-DNS prefix unique to you, e.g. `com.smithfamily`                   |
| `YOUR_SPOTIFY_CLIENT_ID` | [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) — see Step 5 |
| `YOUR_GOOGLE_CLIENT_ID`  | [Google Cloud Console](https://console.cloud.google.com) — see Step 6               |

---

## Step 3 — Generate the Xcode project

```bash
xcodegen generate
```

This creates `Sonas.xcodeproj` and generates `Sonas/Info.plist` (and the Watch/TV equivalents) from your `project.yml`.
Re-run this command any time you add new Swift files or change `project.yml`.

```bash
open Sonas.xcodeproj
```

---

## Step 4 — Run with mock data (no credentials needed)

Before setting up any external services, verify the app builds and runs:

1. In Xcode, select the **Sonas** scheme and an iPhone 16 Pro simulator.
2. Open **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**.
3. Add all six mock flags:

| Variable            | Value |
| ------------------- | ----- |
| `USE_MOCK_LOCATION` | `1`   |
| `USE_MOCK_WEATHER`  | `1`   |
| `USE_MOCK_CALENDAR` | `1`   |
| `USE_MOCK_TASKS`    | `1`   |
| `USE_MOCK_PHOTOS`   | `1`   |
| `USE_MOCK_JAM`      | `1`   |

4. Press **⌘R**. The dashboard appears with fixture data — no accounts or network access required.

---

## Step 5 — Enable Apple capabilities (paid account required)

In the [Apple Developer portal](https://developer.apple.com/account):

1. Create an App ID matching your bundle identifier (e.g. `com.smithfamily.sonas`).
2. Enable **WeatherKit** on that App ID (approval can take minutes to hours on first use).
3. Enable **CloudKit** and create a container named `iCloud.<your-bundle-id>` (e.g. `iCloud.com.smithfamily.sonas`). The
   app derives the container name from the bundle ID automatically.
4. Enable **Push Notifications** (required for CloudKit subscriptions).

In Xcode → Sonas target → Signing & Capabilities, uncomment (or re-enable) WeatherKit and CloudKit. In `project.yml`,
uncomment the corresponding capability and entitlement lines.

> **Data isolation**: Your CloudKit container is private to your Apple Developer account. No other fork or family can
> read or write to it. Each family's Sonas install uses its own container, identified by its bundle ID.

---

## Step 6 — Spotify (optional — Jam feature)

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Create an app. Note the **Client ID**.
3. Add redirect URI: `sonas://spotify-callback`.
4. In `project.yml`, set:
   ```yaml
   SPTClientID: 'your-spotify-client-id'
   ```
5. Run `xcodegen generate` to regenerate `Info.plist`.

The Spotify iOS SDK requires the Spotify app to be installed on the device. The Jam panel shows a "Connect Spotify"
prompt if the SDK is unavailable.

---

## Step 7 — Google Calendar (optional)

1. Go to the [Google Cloud Console](https://console.cloud.google.com).
2. Create a project → enable **Google Calendar API**.
3. Create OAuth 2.0 credentials, type **iOS**, with bundle ID matching yours.
4. Note the **Client ID** (format: `<numbers>.apps.googleusercontent.com`).
5. In `project.yml`, replace `YOUR_GOOGLE_CLIENT_ID` in the URL scheme:
   ```yaml
   - 'com.googleusercontent.apps.<your-client-id>'
   ```
6. Run `xcodegen generate`.

Google Calendar OAuth is handled by the GoogleSignIn-iOS SDK at runtime. Users sign in from within the app.

---

## Step 8 — Todoist (optional — Task panel)

No build-time configuration required. Each family member enters their personal Todoist API token in **Settings → Connect
Todoist**. The token is stored in the device Keychain, not in the app bundle.

---

## Step 9 — CloudKit schema (first launch)

On the very first launch against a new CloudKit container, the app creates the `FamilyLocation` record type
automatically (development containers only). Verify it exists in the
[CloudKit Dashboard](https://icloud.developer.apple.com/dashboard):

```
FamilyLocation
  ├── displayName    (String)
  ├── latitude       (Double)
  ├── longitude      (Double)
  ├── placeName      (String)
  └── recordedAt     (Date/Time)
```

Before TestFlight or App Store submission, export the schema from the development container and promote it to production
via the CloudKit Dashboard.

---

## Per-family data isolation

<!-- editorconfig-checker-disable -->

| Layer                  | Isolation mechanism                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------ |
| CloudKit location data | Each family uses its own container (`iCloud.<bundle-id>`), tied to their Apple Developer account |
| Google Calendar tokens | OAuth tokens are stored per-user in Keychain; each device holds only its own token               |
| Todoist API tokens     | Stored in device Keychain; entered at runtime per user                                           |
| Photos                 | User selects their own iCloud Shared Album from within Settings                                  |
| Spotify tokens         | Managed by Spotify SDK per user                                                                  |

<!-- editorconfig-checker-enable -->

There is no shared backend. All data lives either on Apple's infrastructure (CloudKit, iCloud) or in third-party
services under the user's own account.

---

## Troubleshooting

**"Failed to register bundle identifier"** — The bundle ID is taken. Add initials or a unique suffix.

**WeatherKit returns no data in simulator** — WeatherKit works in the simulator but approval can take time after first
enabling it. Use `USE_MOCK_WEATHER=1` while waiting.

**CloudKit container not found** — Ensure the container name in the Apple Developer portal exactly matches
`iCloud.<your-bundle-id>`. The app derives this automatically from `Bundle.main.bundleIdentifier`.

**Google Sign-In fails** — Confirm the URL scheme in `project.yml` matches the full client ID from Google Cloud Console,
and that the redirect URI is registered.
