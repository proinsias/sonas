# UI Contract: MacShell

**Component**: `MacShell` — root view of the `MacSonas` main window  
**File**: `Sonas/Platform/macOS/MacShell.swift`

## Responsibilities

- Hosts the macOS `NavigationSplitView` with `MacSidebarView` (leading column) and section content (detail column)
- Owns all section ViewModels as `@State` (one per window instance)
- Persists selected section via `@SceneStorage("mac.selectedSection")`
- Listens for `.sonasNavigationRequested` to support keyboard shortcuts and notification deep-links
- Adds macOS toolbar items (refresh button, window title)

## Interface

```
MacShell()  // No external parameters; all ViewModels created internally
```

### Scene Storage

| Key                   | Type          | Default                                  |
| --------------------- | ------------- | ---------------------------------------- |
| `mac.selectedSection` | `AppSection?` | nil → resolved to `.dashboard` on appear |

### Internal ViewModels (one instance per window)

- `DashboardViewModel`, `WeatherViewModel`, `TasksViewModel`, `PhotoViewModel`, `JamViewModel`
- Created via `.makeDefault()` factories (same as `IPadShell`)

## Acceptance Contract

| Scenario                                 | Expected Behaviour                                                   |
| ---------------------------------------- | -------------------------------------------------------------------- |
| First appearance with nil section        | Selects `.dashboard` automatically                                   |
| Sidebar tap on a section                 | Detail column updates immediately                                    |
| `.sonasNavigationRequested` notification | `selectedSection` updates to the notified `AppSection`               |
| Window resize                            | Sidebar remains visible at all widths ≥ 800pt (auto-hide below that) |
| Cmd+R keyboard shortcut                  | Posts `.sonasRefreshRequested` (handled by active section ViewModel) |

## Dependencies

Reuses: `AppSection`, `SidebarView` pattern, all feature panel views (`DashboardView`, `LocationPanelView`, etc.),
`CacheService.shared`, `PanelView`, `LoadingStateView`, `ErrorStateView`
