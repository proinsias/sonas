# Quickstart: MacSonas

## Prerequisites

- macOS 15 Sequoia (or later)
- Xcode 16 (or later)
- `mise` installed: `curl https://mise.jdx.dev/install.sh | sh`
- All project dependencies installed: `mise install`
- A valid `project.yml` (copy from `project.yml.template` and fill in YOUR\_\* values)

## Generate the Xcode project

```bash
xcodegen generate
```

This picks up the new `MacSonas` target and the updated `Sonas` iOS target (Catalyst removed).

## Build and run on macOS

In Xcode, select the **MacSonas** scheme and the **My Mac** destination, then press **Run** (Cmd+R).

Or from the command line:

```bash
xcodebuild -scheme MacSonas -destination 'platform=macOS' build
```

## Run macOS UI tests

```bash
xcodebuild -scheme MacSonas -destination 'platform=macOS' test
```

## Configuration notes

- **Google Sign-In**: Set `GIDClientID` in `MacSonas/Info.plist` (same value as `Sonas/Info.plist`)
- **Spotify**: Not applicable on macOS — the Music section shows cached read-only data only
- **WeatherKit / CloudKit**: Require a paid Apple Developer account; enable capabilities in Xcode if available
- **Location**: macOS prompts for "while using" location authorisation on first run

## Menu bar icon

The Sonas icon appears in the macOS menu bar immediately after launch. Click it to open the family status popover. Use
**Open Sonas** in the popover or click the Dock icon to open the main window.
