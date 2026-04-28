# Data Model: Sonas u2014 Full iPadOS Support

This feature introduces no new persistent data models. All existing SwiftData models, CloudKit records, and service
layer types are unchanged. The new types introduced are UI-layer navigation abstractions.

---

## AppSection

**Kind**: `enum` (value type, `CaseIterable`, `Hashable`, `Identifiable`) **Location**: `Sonas/App/AppSection.swift`

Represents every navigable section in the app. Used as the sidebar selection type in `NavigationSplitView` and as the
backing type for keyboard shortcut registration.

```
AppSection
u251cu2500u2500 .dashboard       u2014 Multi-column panel overview (iPad default)
u251cu2500u2500 .location        u2014 Family member map and location cards
u251cu2500u2500 .calendar        u2014 Upcoming events panel
u251cu2500u2500 .weather         u2014 Weather detail panel
u251cu2500u2500 .tasks           u2014 Todoist tasks panel
u251cu2500u2500 .photos          u2014 Photo gallery panel
u251cu2500u2500 .jam             u2014 Spotify Jam panel
u2514u2500u2500 .settings        u2014 App settings sheet (presented modally from sidebar)
```

**Attributes per case**:

| Attribute          | Type                | Description                                                               |
| ------------------ | ------------------- | ------------------------------------------------------------------------- |
| `id`               | `String`            | Stable string identifier (= `rawValue`) for `@SceneStorage` serialisation |
| `title`            | `String`            | Display label in sidebar                                                  |
| `systemImage`      | `String`            | SF Symbol name from `Icons.swift`                                         |
| `keyboardShortcut` | `KeyboardShortcut?` | `.command + digit` or `.command + comma` for settings                     |

**Constraints**:

- `.settings` does NOT appear as a navigable content column; it triggers a `.sheet` presentation from the sidebar.
- The default selected section on first launch is `.dashboard`.
- `@SceneStorage("selectedSection")` is used in `iPadShell` to persist per-window selection across backgrounding.

---

## LayoutConfiguration (conceptual)

**Kind**: Computed from environment u2014 not a stored type.

The layout configuration is derived entirely from SwiftUI environment values at render time:

| Input                 | Source                                | Drives                                      |
| --------------------- | ------------------------------------- | ------------------------------------------- |
| `horizontalSizeClass` | `@Environment(\.horizontalSizeClass)` | Sidebar vs tab bar; column count            |
| `verticalSizeClass`   | `@Environment(\.verticalSizeClass)`   | Two-column vs three-column iPhone landscape |
| `selectedSection`     | `@SceneStorage("selectedSection")`    | Active sidebar item per window              |

No explicit `LayoutConfiguration` struct is required; the environment values are sufficient.

---

## WindowScene State

**Kind**: Per-scene `@SceneStorage` u2014 not a shared model.

Each Sonas window scene independently stores:

| Key                 | Type                     | Default       |
| ------------------- | ------------------------ | ------------- |
| `"selectedSection"` | `String` (AppSection.id) | `"dashboard"` |

This ensures that two open windows can independently navigate to different sections without shared state coupling.
