# UI Contract: MacMenuBarPopoverView

**Component**: `MacMenuBarPopoverView` — content of the `MenuBarExtra` popover  
**File**: `Sonas/Platform/macOS/MacMenuBarPopoverView.swift`

## Responsibilities

- Renders a compact, always-cached summary: family location names, next calendar event, current weather
- Shows "last updated [time]" indicator when `MenuBarState.isOffline` is true (FR-017)
- Provides an "Open Sonas" button that brings the main window to front (FR-003 scenario 3)
- Opens within ≤300ms with no loading spinner (SC-002) — data is always served from cache

## Interface

```
MacMenuBarPopoverView()
// Reads MenuBarState from @Environment
// Calls openWindow(id: "main") via @Environment(\.openWindow)
```

### Environment Dependencies

| Key              | Type               | Purpose                                   |
| ---------------- | ------------------ | ----------------------------------------- |
| `\.menuBarState` | `MenuBarState`     | Data source for all displayed content     |
| `\.openWindow`   | `OpenWindowAction` | Opens the main window on "Open Sonas" tap |

## Layout (compact, fixed-width popover)

```
┌─────────────────────────────┐
│  📍 Family                   │
│     Alice — Home             │
│     Bob — Work               │
│                              │
│  📅 Next Event               │
│     Team Standup · 9:00 AM   │
│                              │
│  🌤 Weather                  │
│     18°C · Partly Cloudy     │
│                              │
│  Last updated 2 min ago  ←── shown only when offline
│                              │
│  [    Open Sonas    ]        │
└─────────────────────────────┘
```

## Acceptance Contract

| Scenario                                     | Expected Behaviour                                         |
| -------------------------------------------- | ---------------------------------------------------------- |
| Opens when no cached data exists             | Shows "No data yet" placeholder in each section            |
| `isOffline` is true                          | Shows "Last updated [relative time]" below weather section |
| "Open Sonas" tapped with window already open | Window comes to front; popover closes                      |
| "Open Sonas" tapped with no window open      | New window created; popover closes                         |
| `nextEvent` is nil                           | Next Event section shows "No upcoming events"              |
| `familyLocations` is empty                   | Family section shows "Location unavailable"                |

## Performance Contract

- View body executes synchronously (no async tasks, no network calls)
- All data read from `MenuBarState` which is populated from `CacheService` before popover opens
- Target render time: ≤16ms (1 frame at 60fps)
