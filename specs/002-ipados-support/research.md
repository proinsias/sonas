# Research: Sonas u2014 Full iPadOS Support

---

## Decision 1: iPad Navigation Architecture

**Decision**: `NavigationSplitView` with two-column layout (sidebar + content). The sidebar lists all `AppSection`
cases; the content column shows the section-specific panel or the full multi-column dashboard when "Dashboard" is
selected. On iPhone and compact-width iPad, the existing `NavigationStack` + `DashboardView` is used unchanged.

**Rationale**: `NavigationSplitView` is Apple's canonical iPad navigation primitive (available since iOS 16 / iPadOS
16). It automatically handles sidebar collapse in portrait (overlaid sheet), integrates with Stage Manager window
resizing, and maps naturally to the spec's requirement of "sidebar lists sections, detail loads in trailing panel."
Using `NavigationSplitView` instead of a custom sidebar avoids one-off component creation (Constitution III) and ensures
future compatibility with iPadOS system features (Spotlight, quick look, drag targets).

The size-class gate (`horizontalSizeClass == .regular`) applied at the `SonasApp` `WindowGroup` body level ensures that
the iPhone layout (`NavigationStack` u2192 `DashboardView`) receives no changes.

**Alternatives considered**:

- Custom drawer overlay: produces one-off component; fails Constitution III; rejected.
- `TabView` with `.sidebarAdaptable` style (iOS 18 new API): attractive but changes the iPhone tab bar to a sidebar
  automatically u2014 conflicts with the clarified requirement to keep tab bar on iPhone; rejected.
- `NavigationSplitView` with three columns (sidebar + content + detail): overengineered for current feature scope;
  deferred to a future detail-view expansion.

---

## Decision 2: Keyboard Shortcut Registry

**Decision**: SwiftUI `.commands { CommandGroup(...) }` modifier on the `WindowGroup` in `SonasApp`, combined with
`.keyboardShortcut(_:modifiers:)` on each `SidebarView` navigation `Button`.

**Rationale**: SwiftUI's `.commands` modifier is the idiomatic way to register keyboard shortcuts in a scene-aware
manner on iPadOS 15+. It integrates with the system's Command key overlay (shown when user holds u2318 on an external
keyboard) without any custom implementation. The shortcut overlay is automatic u2014 FR-004 is satisfied with zero
additional code. Using `.keyboardShortcut` on sidebar buttons means the shortcuts are scoped to the active window
(correct for multi-window scenarios).

Shortcuts assigned:

| Section            | Shortcut                              |
| ------------------ | ------------------------------------- |
| Dashboard overview | u21984 + 1                            |
| Location           | u21984 + 2                            |
| Calendar           | u21984 + 3                            |
| Weather            | u21984 + 4                            |
| Tasks              | u21984 + 5                            |
| Photos             | u21984 + 6                            |
| Jam                | u21984 + 7                            |
| Settings           | u21984 + , (comma, system convention) |
| Refresh            | u21984 + R                            |

**Alternatives considered**:

- `UIKeyCommand` via `UIResponder`: UIKit-level; bypasses SwiftUI command overlay; rejected.
- Custom shortcut sheet overlay (manual `HStack` of shortcut labels): manual reimplementation of system feature;
  rejected.

---

## Decision 3: Pointer Hover and Context Menu

**Decision**: Apply `.hoverEffect(.highlight)` to all interactive panel cards via a shared
`View+PointerInteraction.swift` extension. Apply `.contextMenu { }` to `LocationPanelView` cards (Get Directions, Copy
Location, Open in Maps) and `EventsPanelView` rows (Copy Event, Add Reminder).

**Rationale**: `.hoverEffect` is a SwiftUI modifier available since iOS 15 / iPadOS 15 that automatically shows the
system-standard pointer hover state on connected pointer devices and is a no-op on touch-only devices u2014 zero risk to
iPhone UX. `.contextMenu` similarly shows nothing on non-right-click interactions on touch. Both are design-system-
level additions that express the feature requirement without any per-device conditional code.

Context menu scope limited to Location and Calendar panels for v1 (highest daily-use panels). Weather, Tasks, and Photos
context menus deferred to a follow-up.

**Alternatives considered**:

- `UIPointerInteraction` (UIKit): requires `UIViewRepresentable` wrappers; adds complexity without benefit since SwiftUI
  `.hoverEffect` covers the requirement; rejected.
- `.hoverEffect(.lift)`: produces a floating card effect more appropriate for photo thumbnails than dashboard panels;
  `.highlight` chosen for panels.

---

## Decision 4: Multi-Window Support

**Decision**: Set `UIApplicationSupportsMultipleScenes = YES` in Info.plist. The existing `WindowGroup` in `SonasApp`
already supports scene creation automatically once this key is set. No additional scene delegate code required.

**Rationale**: On iPadOS, setting `UIApplicationSupportsMultipleScenes` is the only required change to enable
multi-window via the system UI (long-press on the app icon, drag from multitasking exposu00e9). SwiftUI's `WindowGroup`
automatically manages new scene creation and restoration. Existing `@State` in each scene is independent by default. The
`@SceneStorage` property wrapper is used for sidebar selection persistence so each window restores to its last selected
section independently.

**Alternatives considered**:

- Custom `UIWindowSceneDelegate`: necessary only if custom window lifecycle handling is needed; overkill for current
  requirements; rejected.

---

## Decision 5: Stage Manager Compatibility

**Decision**: Set a minimum scene size of `CGSize(width: 320, height: 400)` via
`UIWindowScene.SizeRestrictions.minimumSize` applied in a `UIWindowSceneDelegate`. No maximum size restriction (let the
OS manage). Existing size-class-based layout switching handles all intermediate sizes correctly.

**Rationale**: Without a minimum size restriction, Stage Manager can shrink the Sonas window below the point where the
Compact-width single-column layout still renders legibly. Setting a 320pt minimum (the narrowest Slide Over width)
ensures the existing Compact layout is always the floor. The existing `horizontalSizeClass` / `verticalSizeClass`
switching in `DashboardView` handles all Stage Manager resize events automatically u2014 no additional layout code is
needed. Stage Manager compatibility is therefore achieved with one new delegate method.

**Alternatives considered**:

- `UIWindowScene.SizeRestrictions.maximumSize`: restricting the maximum size prevents users from using Sonas in
  full-screen on large-screen iPads; rejected.
- Geometry reader u2013 based breakpoints: fragile against future screen sizes; size class is the correct semantic
  abstraction; rejected.
