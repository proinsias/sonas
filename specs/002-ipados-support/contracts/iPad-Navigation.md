# Contract: iPad Navigation Shell

**File**: `Sonas/Platform/iPad/iPadShell.swift` **Consumed by**: `DashboardView` (conditionally, at Regular horizontal
size class)

---

## Purpose

`iPadShell` is the root view for iPadOS at Regular horizontal size class. It wraps all section content in a
`NavigationSplitView` with a persistent sidebar, replacing the `NavigationStack` used on iPhone.

---

## Interface

```swift
/// Root navigation container for iPad Regular-width layout.
/// Inject in place of NavigationStack when horizontalSizeClass == .regular.
struct iPadShell: View {
    /// The section currently shown in the content column.
    /// Persisted per window scene via @SceneStorage.
    @SceneStorage("selectedSection") var selectedSection: String

    var body: some View { /* NavigationSplitView */ }
}
```

**Responsibilities**:

- Renders a two-column `NavigationSplitView` (sidebar + content)
- Sidebar column: `SidebarView` with all `AppSection` cases
- Content column: section-specific panel view switched on `selectedSection`
  - `.dashboard` u2192 `DashboardView` (existing multi-column layout)
  - `.location` u2192 `LocationPanelView`
  - `.calendar` u2192 `EventsPanelView`
  - `.weather` u2192 `WeatherPanelView`
  - `.tasks` u2192 `TasksPanelView`
  - `.photos` u2192 `PhotoGalleryView`
  - `.jam` u2192 `JamPanelView`
  - `.settings` u2192 triggers `SettingsView` sheet (NOT a content column)
- Does NOT own any view model state; passes existing view models from parent
- Does NOT conditionally compile with `#if os(iOS)` guards (runs on all SwiftUI targets but iPad layout only activates
  at Regular width)

**Non-responsibilities**:

- Does NOT handle iPhone layout (caller is responsible for routing to NavigationStack at Compact width)
- Does NOT fetch or cache data
- Does NOT register keyboard shortcuts (that is `SonasCommands`)

---

## SidebarView Interface

**File**: `Sonas/Platform/iPad/SidebarView.swift`

```swift
/// Sidebar section list for NavigationSplitView.
struct SidebarView: View {
    /// Binding to the parent shell's selected section.
    @Binding var selectedSection: String
    /// Callback triggered when user taps Settings.
    var onSettingsTapped: () -> Void

    var body: some View { /* List of AppSection navigation links */ }
}
```

**Responsibilities**:

- Renders `List` of `NavigationLink` items for all `AppSection.allCases` (excluding `.settings`)
- `.settings` rendered as a `Button` that calls `onSettingsTapped`
- Each navigation item carries its `.keyboardShortcut` from `AppSection`
- Applies `.listStyle(.sidebar)` for iPadOS sidebar chrome

---

## AppSection Interface

**File**: `Sonas/App/AppSection.swift`

```swift
enum AppSection: String, CaseIterable, Hashable, Identifiable {
    case dashboard, location, calendar, weather, tasks, photos, jam, settings

    var id: String { rawValue }
    var title: String { /* e.g. "Dashboard", "Location" */ }
    var systemImage: String { /* SF Symbol name */ }
    var keyboardShortcut: KeyboardShortcut? { /* e.g. .init("1", modifiers: .command) */ }
}
```

**Constraints**:

- `rawValue` strings MUST be stable (used as `@SceneStorage` keys)
- `systemImage` MUST reference only names defined in `Icons.swift`
- `keyboardShortcut` for `.settings` MUST be `.init(",", modifiers: .command)` (system convention)
- `keyboardShortcut` for `.refresh` is NOT on `AppSection`; it lives in `SonasCommands`
