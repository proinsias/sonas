# Sonas

**Sonas** (SUN-əs, from the Irish for _happiness_) is a Family Command Center — a single always-on dashboard that shows
the whole family at a glance: where everyone is, what's coming up, what the weather looks like, shared photos, the
household task list, and a Spotify Jam QR code for shared listening.

## Contents

<!--
Table of contents updated via:
uvx --from md-toc md_toc --in-place github -- README.md
-->
<!--TOC-->

- [Sonas](#sonas)
  - [Contents](#contents)
  - [Features](#features)
  - [Platform Support](#platform-support)
  - [Service integrations](#service-integrations)
  - [Developer Guides](#developer-guides)
  - [Per-family data isolation](#per-family-data-isolation)
  - [What to build next](#what-to-build-next)

<!--TOC-->

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

The layout adapts automatically: a single column on iPhone, three columns on iPad and Mac. iPad support includes sidebar
navigation, keyboard shortcuts, pointer interaction, and multi-window multitasking.

## Platform Support

| Platform | Minimum OS  |
| -------- | ----------- |
| iOS      | iOS 17+     |
| iPadOS   | iPadOS 17+  |
| macOS    | macOS 15+   |
| watchOS  | watchOS 11+ |
| tvOS     | tvOS 18+    |

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

## Developer Guides

See the [Quickstart](specs/001-family-command-center/quickstart.md) guide for how to build and modify this application.

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
services under the user's own account. No other fork or family can read or write to your CloudKit container.

## Use of speckit

This application was developed using Claude and GitHub's [spec-kit](https://github.com/github/spec-kit). Useful commands
are:

- `/speckit-constitution`: Create or update project governing principles and development guidelines.
- `/speckit-specify`: Define what you want to build (requirements and user stories).
- `/speckit-clarify`: Clarify underspecified areas.
- `/speckit-plan`: Create technical implementation plans with your chosen tech stack.
- `/speckit-tasks`: Generate actionable task lists for implementation.
- `/speckit-analyze`: Cross-artifact consistency & coverage analysis.
- `/speckit-implement`: Execute all tasks to build the feature according to the plan.

## What to build next

The following tasks are still open (not yet implemented).

### iOS Support

See `specs/001-family-command-center/tasks.md` for full details.

- **T086** — Run the quickstart checklist.
- **T091** — Memory profiling with Instruments. Once you have a real device, profile the app with Leaks + Allocations
  while all six panels are active. Target: ≤150 MB peak RSS.

### tvOS Support

See `specs/004-tvos-support/tasks.md` for full details.

**Phase 5: US3 Full Panel Coverage**

- T029 — 10-foot UI legibility verification (pending — requires tvOS Simulator visual inspection)

**Phase 7: Polish**

- T035–T039 — Verify USE*MOCK*\* variables, offline stale-data, Instruments profiling, unit/UI tests

### watchOS Support

- Add via speckit.
