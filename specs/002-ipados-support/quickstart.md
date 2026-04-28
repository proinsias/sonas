# Quickstart: Sonas u2014 Full iPadOS Support

## Prerequisites

- Xcode 16+ with iOS 17+ simulator (iPad Air or iPad Pro recommended)
- Existing Sonas project building cleanly on `main`
- All existing tests passing: `xcodebuild test -scheme Sonas`

## Development Setup

No new dependencies, tools, or environment variables are required for this feature. All changes use SwiftUI and UIKit
APIs available in the project's existing minimum deployment target (iOS 17).

## Running the App on iPad Simulator

1. In Xcode, select an **iPad Pro (13-inch)** or **iPad Air** simulator
2. Build and run: **u2318R**
3. The app launches in full-screen landscape u2014 the 3-column grid is already functional (existing code)
4. To test Slide Over: Xcode Simulator menu u2192 **Device u2192 Override Software Keyboard** is not applicable; use the
   Home gesture to open another app and drag Sonas into Slide Over

**Tip**: Use **Environment Overrides** (Xcode debug bar) to force Compact horizontal size class and verify the fallback
single-column layout without needing to resize.

## Key Files for This Feature

| File                                                    | Role                                              |
| ------------------------------------------------------- | ------------------------------------------------- |
| `Sonas/App/AppSection.swift`                            | NEW: all other iPad files depend on it            |
| `Sonas/Platform/iPad/IPadShell.swift`                   | NEW: NavigationSplitView root                     |
| `Sonas/Platform/iPad/SidebarView.swift`                 | NEW: Sidebar section list                         |
| `Sonas/App/SonasApp.swift`                              | MODIFY: IPadShell, `.commands`, multi-window      |
| `Sonas/App/SceneDelegates/IPadSceneDelegate.swift`      | NEW: Stage Manager minimum size restriction       |
| `Sonas/Shared/Commands/SonasCommands.swift`             | NEW: keyboard shortcut declarations               |
| `Sonas/Shared/Extensions/View+PointerInteraction.swift` | NEW: hover + context menus                        |
| `Info.plist.template`                                   | MODIFY: `UIApplicationSupportsMultipleScenes=YES` |

## Build Order

Implement in this order to avoid compilation errors:

1. `AppSection.swift` — no dependencies
2. `View+PointerInteraction.swift` — depends on CalendarModels, LocationModels
3. `SidebarView.swift` — depends on AppSection
4. `IPadShell.swift` — depends on AppSection, SidebarView, all panel views
5. `SonasCommands.swift` — depends on AppSection
6. `IPadSceneDelegate.swift` — UIKit scene delegate
7. Modify `SonasApp.swift` — depends on IPadShell, SonasCommands
8. `Info.plist.template` — independent
9. `AppSectionTests.swift`, `IPadLayoutUITests.swift` — after source complete

## Testing on Physical iPad

For multi-window testing, a physical iPad is required (simulators support only one window):

1. Long-press the Sonas icon in the dock
2. Tap **"Show All Windows"** or drag the icon to the right side of the screen
3. A new Sonas window scene should open independently
4. Verify each window can navigate to different sections simultaneously

## Stage Manager Testing

1. iPad (M1 chip or later) with iPadOS 16+
2. Enable Stage Manager: **Settings u2192 Home Screen & Multitasking u2192 Stage Manager**
3. Open Sonas, resize the window to minimum width
4. Verify layout switches to single-column (Compact size class) at narrow widths
5. Restore to full size and verify multi-column layout returns

## Regression Check

After all changes, run the full test suite on iPhone simulator to confirm no regressions:

```bash
xcodebuild test -scheme Sonas \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```
