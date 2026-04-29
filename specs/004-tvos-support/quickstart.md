# Quickstart: Sonas tvOS Full Support

**Branch**: `004-tvos-support`

## Prerequisites

- Xcode 16+ with tvOS 18 Simulator installed
- `xcodegen generate` run after pulling the branch (adds `TVTopShelfExtension` and `TVSonasUITests` targets)
- An Apple Developer account with WeatherKit entitlement enabled for the TVSonas bundle ID (same steps as iOS)
- (Optional) A shared iCloud Photo album populated with at least one photo for Photos panel testing

## Run the tvOS App (Simulator)

```bash
# 1. Regenerate the project after branch checkout
xcodegen generate

# 2. Open in Xcode
open Sonas.xcodeproj

# 3. Select the TVSonas scheme and an Apple TV simulator
# Scheme: TVSonas
# Destination: Apple TV 4K (3rd generation) Simulator

# Or build from the command line:
xcodebuild build \
  -scheme TVSonas \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

## Run with Mock Data

Set environment variables in the `TVSonas` scheme (Edit Scheme → Run → Arguments):

| Variable            | Value | Effect                          |
| ------------------- | ----- | ------------------------------- |
| `USE_MOCK_WEATHER`  | `1`   | Fixture weather data            |
| `USE_MOCK_CALENDAR` | `1`   | Fixture calendar events         |
| `USE_MOCK_PHOTOS`   | `1`   | Fixture photos                  |
| `USE_MOCK_LOCATION` | `1`   | Fixture family member locations |
| `USE_MOCK_JAM`      | `1`   | Fixture Spotify track           |

All mocks enabled = fully offline, no credentials required.

## Run Unit + Contract Tests

```bash
xcodebuild test \
  -scheme SonasTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:SonasTests/TVCalendarServiceTests \
  -only-testing:SonasTests/TVSpotifyReadServiceTests
```

Note: Contract tests run under the iOS simulator (SonasTests target) since the service protocols are shared and the mock
implementations are platform-agnostic.

## Run UI Tests

```bash
xcodebuild test \
  -scheme TVSonas \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  -derivedDataPath .build/DerivedData/ui-tvos
```

## Test Top Shelf (Simulator)

1. Build and install the `TVSonas` scheme (includes the `TVTopShelfExtension` target).
2. In the simulator, navigate to the home screen.
3. Move the `Sonas` icon to the top row using the simulated remote.
4. Highlight the icon — the Top Shelf area should populate with a photo and next event.

To verify shared-container data: attach LLDB to `TVSonasTopShelfExtension` process and inspect
`UserDefaults(suiteName: "group.com.sonas.topshelf")`.

## Test Google Calendar Device Flow

1. Launch with `USE_MOCK_CALENDAR=0`.
2. Navigate to the Calendar panel.
3. The panel will show the device auth code and URL if not yet authenticated.
4. On a browser, visit the URL shown and enter the code.
5. The panel should automatically update to show live calendar events.

## Performance Verification (SC-004 — 8-hour stability)

```bash
# Run on a physical Apple TV connected via Instruments
instruments -t "Allocations" \
  -D .build/instruments/tvos-8h \
  -l 28800 \  # 28800 seconds = 8 hours
  TVSonas.app
```

Review the Allocations trace for monotonically growing heap: any upward trend indicates a memory leak that must be fixed
before the feature ships.
