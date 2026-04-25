# Feature Specification: Sonas — Full iPadOS Support

**Feature Branch**: `002-ipados-support` **Created**: 2026-04-25 **Status**: Draft **Input**: User description: "Sonas
should fully support iPadOS capabilities, rather than just being an iOS application viewed on an iPad."

## User Scenarios & Testing _(mandatory)_

### User Story 1 — Expanded Multi-Panel Dashboard (Priority: P1)

An iPad user opens Sonas and immediately sees a richly laid-out dashboard that exploits the large screen: location map,
calendar panel, weather detail, and photo gallery are all visible simultaneously in a multi-column layout, with no
scrolling required to access primary information. The experience feels purpose-built for iPad, not stretched from
iPhone.

**Why this priority**: The core value of Sonas is at-a-glance family awareness. On iPad that means showing more at once,
not the same content scaled up. Without this, the app remains a large iPhone app rather than a true iPadOS citizen.

**Independent Test**: Launch the app on an iPad in full-screen landscape orientation. Verify that at least three
distinct information panels (e.g., location, calendar, weather) are visible simultaneously without scrolling and that no
panel contains excessive whitespace.

**Acceptance Scenarios**:

1. **Given** the app is launched on an iPad in landscape orientation, **When** the dashboard loads, **Then** at least
   three primary panels are displayed side by side without requiring any scrolling.
2. **Given** the app is in landscape orientation, **When** the user rotates to portrait, **Then** the layout reflows
   gracefully — no content is clipped, overlapping, or hidden.
3. **Given** the app is displayed at any iPad screen size (9.7" to 13"), **When** the layout renders, **Then** all
   interactive elements are comfortably reachable and no text is too small to read without zooming.
4. **Given** the user is on an older iPad with a smaller screen, **When** the app loads, **Then** the layout
   automatically adapts column count to available width.

---

### User Story 2 — Keyboard and Pointer Interaction (Priority: P2)

An iPad user with a Magic Keyboard or external keyboard navigates Sonas entirely without touching the screen. They use
keyboard shortcuts to jump between panels, refresh data, and launch actions. When using a trackpad or mouse, interactive
elements respond with appropriate hover states and support right-click context menus where applicable.

**Why this priority**: iPad productivity users expect keyboard-driven interaction as a first-class experience. Shipping
without it relegates Sonas to touch-only use and excludes the growing segment of keyboard-attached iPad users.

**Independent Test**: Connect a Magic Keyboard to an iPad running Sonas. Navigate through all primary panels, trigger a
data refresh, and open at least one detail view using only keyboard input. Hover over interactive elements with a
trackpad and confirm visual feedback.

**Acceptance Scenarios**:

1. **Given** a hardware keyboard is connected, **When** the user presses the documented shortcut for each primary panel,
   **Then** focus moves to that panel immediately.
2. **Given** a hardware keyboard is connected, **When** the user holds the Command key, **Then** a shortcut cheat-sheet
   overlay appears listing all available shortcuts.
3. **Given** a trackpad is in use, **When** the user hovers over an interactive element (card, button, link), **Then**
   the element displays a visible hover state.
4. **Given** a trackpad is in use, **When** the user right-clicks (or two-finger taps) on a family member's location
   card, **Then** a context menu appears with relevant actions (e.g., get directions, send message).

---

### User Story 3 — Multi-Window and Split View Support (Priority: P2)

An iPad user runs Sonas alongside another app in Split View, or opens a second Sonas window (e.g., one showing the
dashboard, one focused on the weather detail). The app scales correctly in Split View compact widths and does not lose
state when moved between windows or size classes.

**Why this priority**: Split View and multi-window are cornerstones of iPad multitasking. Without proper support, Sonas
actively breaks when placed in Split View — an unacceptable regression for iPad power users.

**Independent Test**: Place Sonas in a 1/3-width Slide Over panel. Confirm that content remains legible and no UI
elements overflow their containers. Then open a second Sonas window and confirm it opens independently.

**Acceptance Scenarios**:

1. **Given** Sonas is placed in Slide Over or a 1/3 Split View column, **When** the app renders at compact width,
   **Then** it switches to a single-column layout and all content remains accessible.
2. **Given** Sonas is in a 1/2 Split View column, **When** the app renders, **Then** it shows a two-panel layout without
   overflow or clipping.
3. **Given** multi-window is available on the device, **When** the user long-presses the app icon or uses the
   multitasking menu, **Then** a new independent Sonas window opens with its own state.
4. **Given** two Sonas windows are open, **When** data refreshes in one window, **Then** both windows reflect the
   updated data within the standard refresh interval.

---

### User Story 4 — Stage Manager Compatibility (Priority: P3)

An iPad user running iPadOS 16+ with Stage Manager enabled can resize the Sonas window to any supported size, overlap it
with other windows, and switch between it and other apps without Sonas losing its state or crashing.

**Why this priority**: Stage Manager is the primary desktop-like multitasking mode on modern iPads. Compatibility is
expected by iPadOS 16+ users and failure here causes visible crashes or broken layouts.

**Independent Test**: Enable Stage Manager on an iPadOS 16+ device. Open Sonas, resize its window to the minimum and
maximum supported dimensions, then bring it back to foreground after switching to another app. Confirm no crashes and no
data loss.

**Acceptance Scenarios**:

1. **Given** Stage Manager is active, **When** the Sonas window is resized to the minimum supported width, **Then** the
   layout adapts without clipping, overflow, or crash.
2. **Given** Stage Manager is active, **When** the user switches away and returns to Sonas, **Then** the previously
   visible content is restored without requiring a full reload.
3. **Given** Stage Manager is active, **When** Sonas runs alongside three other apps simultaneously, **Then** Sonas
   maintains normal refresh behaviour and does not degrade performance.

---

### User Story 5 — iPadOS-Specific Navigation Patterns (Priority: P3)

An iPad user familiar with iPadOS conventions finds Sonas navigation intuitive: the app uses a sidebar for top-level
navigation rather than a tab bar, and detail views push into adjacent panels rather than taking over the full screen.

**Why this priority**: Using iPhone navigation patterns (bottom tab bar, full-screen push navigation) on iPad is a
well-known usability regression. Apple's own Human Interface Guidelines mandate sidebar-based navigation for iPad.

**Independent Test**: Launch Sonas on an iPad in landscape. Confirm the primary navigation is a sidebar or split-view
navigation controller, not a tab bar. Tap a navigation item and confirm the detail view appears in the trailing panel
rather than replacing the sidebar.

**Acceptance Scenarios**:

1. **Given** the app is on an iPad in landscape, **When** the main navigation renders, **Then** a sidebar lists all
   primary sections and is persistently visible.
2. **Given** the sidebar is visible, **When** the user selects a section, **Then** the detail content loads in the
   trailing panel without dismissing the sidebar.
3. **Given** the app is on an iPad in portrait, **When** the navigation renders, **Then** the sidebar is accessible via
   a swipe or toolbar button and overlays rather than disappearing entirely.
4. **Given** the app is switched to an iPhone (e.g., on a universal build), **When** the navigation renders, **Then**
   the app falls back to tab bar navigation without any visual breakage.

---

### Edge Cases

- What happens when the app transitions between Split View and full-screen mid-session without a restart?
- How does the multi-column layout behave on the smallest iPad (iPad mini) in landscape?
- What happens if Stage Manager is enabled but the device does not meet Apple's Stage Manager requirements?
- How does keyboard shortcut registration behave when Sonas loses and regains focus in a multi-window session?
- What happens when the app is backgrounded for an extended period and then restored in a different size class?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The app MUST display an adaptive multi-column dashboard layout on iPad, showing at minimum the location
  panel, calendar panel, and weather panel simultaneously in landscape without scrolling.
- **FR-002**: The dashboard layout MUST respond to size class changes in real time — switching between multi-column and
  single-column based on available horizontal space.
- **FR-003**: The app MUST register and respond to keyboard shortcuts for navigating between all primary sections,
  refreshing data, and triggering the most common per-section actions.
- **FR-004**: The app MUST display a Command key shortcut overlay when the user holds the Command key on a connected
  hardware keyboard.
- **FR-005**: Interactive elements MUST display hover states when the user interacts with a connected pointer device
  (trackpad or mouse).
- **FR-006**: The app MUST support right-click context menus on primary interactive elements (family member cards, event
  entries, weather locations) when a pointer device is in use.
- **FR-007**: The app MUST support Split View and Slide Over, adapting to compact width by switching to a single-column
  layout with all content still accessible.
- **FR-008**: The app MUST support opening a second independent window on devices where iPadOS multi-window is
  available.
- **FR-009**: When running in multiple windows, all windows MUST reflect the same underlying data after each refresh
  cycle.
- **FR-010**: The app MUST be compatible with Stage Manager on iPadOS 16+ — resizeable to minimum and maximum window
  dimensions without crashing or losing visible state.
- **FR-011**: On iPad in landscape orientation, the primary navigation MUST be presented as a persistent sidebar rather
  than a bottom tab bar.
- **FR-012**: On iPad in portrait orientation, the primary sidebar MUST be accessible via a toolbar button or swipe
  gesture and MUST overlay rather than disappear.
- **FR-013**: The iPhone layout and navigation (tab bar, single-column) MUST remain fully intact and unaffected by
  iPadOS-specific changes.
- **FR-014**: The app MUST NOT display iPhone-only layout patterns (bottom tab bar as primary navigation, full-screen
  push navigation) when running natively on iPad.

### Key Entities

- **Size Class**: An abstraction representing horizontal and vertical space available to the app window (compact,
  regular). Drives layout decisions.
- **Window Scene**: An independent instance of the app's UI, each with its own state and lifecycle. Multiple scenes can
  be active simultaneously on iPadOS.
- **Layout Configuration**: The set of panel arrangements and navigation patterns active for a given size class and
  orientation.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: On any iPad model in landscape orientation, all three primary panels (location, calendar, weather) are
  visible simultaneously without scrolling on 100% of screen size/orientation combinations.
- **SC-002**: All primary navigational sections are reachable using keyboard shortcuts alone, with no more than one
  keypress per section.
- **SC-003**: The app passes Apple's App Store review without any iPad-specific layout or multi-window rejection
  feedback.
- **SC-004**: The app renders without visual breakage (no clipped content, overflow, or empty white space) across all
  four supported iPadOS window sizes: full screen, 2/3 split, 1/2 split, and Slide Over.
- **SC-005**: No crashes occur when the app transitions between window sizes, enters or exits Stage Manager, or switches
  between foreground and background in a multi-window session.
- **SC-006**: All data visible in one Sonas window is consistent with data in a simultaneously open second window within
  one refresh cycle.
- **SC-007**: The iPhone experience is regression-free: all iPhone user stories from the 001-family-command-center spec
  pass without modification after iPadOS support is introduced.

## Assumptions

- The minimum supported iPadOS version matches the existing iOS deployment target (iOS 17).
- Stage Manager support targets iPadOS 16+ only; older iPads running iPadOS 17 that do not support Stage Manager are out
  of scope for Stage Manager-specific behaviour.
- Apple Pencil interaction (drawing, annotation) is out of scope for this feature.
- Custom drag-and-drop between Sonas and other apps (e.g., dragging a calendar event out of Sonas) is out of scope for
  v1 of this feature; drag-and-drop within the app is in scope only if it improves layout customisation.
- The sidebar navigation pattern applies when horizontal size class is Regular (iPad full-screen and large Split View);
  Compact size class continues to use the existing iPhone tab bar.
- All existing Sonas data sources (location, calendar, weather, photos, Todoist, Spotify) remain unchanged; this feature
  concerns layout and interaction, not new data integrations.
- Keyboard shortcut design will follow Apple Human Interface Guidelines; no user-customisable shortcuts are required for
  v1.
