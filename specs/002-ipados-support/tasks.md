# Tasks: Sonas — Full iPadOS Support

**Input**: Design documents from `/specs/002-ipados-support/` **Prerequisites**: plan.md (required), spec.md (required
for user stories), research.md, data-model.md, contracts/

**Tests**: The feature specification identifies specific independent tests for each user story, and mentions new UI test
targets. Therefore, test tasks will be included where appropriate.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `Sonas/` for source, `SonasTests/` for unit tests, `SonasUITests/` for UI tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create AppSection enum in `Sonas/App/AppSection.swift`
- [x] T002 Create View+PointerInteraction extension in `Sonas/Shared/Extensions/View+PointerInteraction.swift`
- [x] T003 Create AppSectionTests in `SonasTests/Unit/AppSectionTests.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create SidebarView in `Sonas/Platform/iPad/SidebarView.swift`
- [x] T005 Create SonasCommands in `Sonas/Shared/Commands/SonasCommands.swift`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Expanded Multi-Panel Dashboard (Priority: P1) 🎯 MVP

**Goal**: An iPad user sees a richly laid-out dashboard that exploits the large screen with multi-column layout.

**Independent Test**: Launch the app on an iPad in full-screen landscape orientation. Verify that at least three
distinct information panels (e.g., location, calendar, weather) are visible simultaneously without scrolling and that no
panel contains excessive whitespace.

### Tests for User Story 1 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T006 [P] [US1] Create IPadLayoutUITests for basic dashboard layout in `SonasUITests/IPadLayoutUITests.swift`

### Implementation for User Story 1

- [x] T007 [US1] Create IPadShell (NavigationSplitView root) in `Sonas/Platform/iPad/IPadShell.swift`
- [x] T008 [US1] Modify SonasApp to inject IPadShell at root for Regular width in `Sonas/App/SonasApp.swift`
- [x] T009 [US1] Modify DashboardView to consume IPadShell in `Sonas/Features/Dashboard/DashboardView.swift`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Keyboard and Pointer Interaction (Priority: P2)

**Goal**: iPad user navigates Sonas entirely with keyboard shortcuts and trackpad/mouse.

**Independent Test**: Connect a Magic Keyboard to an iPad running Sonas. Navigate through all primary panels, trigger a
data refresh, and open at least one detail view using only keyboard input. Hover over interactive elements with a
trackpad and confirm visual feedback.

### Tests for User Story 2 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T010 [P] [US2] Update IPadLayoutUITests for keyboard navigation and hover in
      `SonasUITests/IPadLayoutUITests.swift`

### Implementation for User Story 2

- [x] T011 [US2] Apply `.commands` modifier to WindowGroup in `Sonas/App/SonasApp.swift`
- [x] T012 [US2] Apply `.panelHoverEffect()` via extension to all interactive panel cards
- [x] T013 [US2] Apply `.contextMenu { }` to LocationPanelView cards
- [x] T014 [US2] Apply `.contextMenu { }` to EventsPanelView rows

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Multi-Window and Split View Support (Priority: P2)

**Goal**: iPad user runs Sonas alongside another app in Split View, or opens a second Sonas window without state loss.

**Independent Test**: Place Sonas in a 1/3-width Slide Over panel. Confirm that content remains legible and no UI
elements overflow their containers. Then open a second Sonas window and confirm it opens independently.

### Tests for User Story 3 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T015 [P] [US3] Update IPadLayoutUITests for multi-window scene opening in `SonasUITests/IPadLayoutUITests.swift` —
      requires physical iPad (simulators support one window only)

### Implementation for User Story 3

- [x] T016 [US3] Set `UIApplicationSupportsMultipleScenes = YES` in `Info.plist`
- [x] T017 [US3] Ensure `@SceneStorage("selectedSection")` is used in `IPadShell.swift` for per-window state persistence

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Stage Manager Compatibility (Priority: P3)

**Goal**: iPad user running iPadOS 16+ with Stage Manager enabled can resize Sonas window to any supported size.

**Independent Test**: Enable Stage Manager on an iPadOS 16+ device. Open Sonas, resize its window to the minimum and
maximum supported dimensions, then bring it back to foreground after switching to another app. Confirm no crashes and no
data loss.

### Tests for User Story 4 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T018 [P] [US4] Update IPadLayoutUITests for Stage Manager resize in `SonasUITests/IPadLayoutUITests.swift` —
      requires M1+ iPad with iPadOS 16+ and Stage Manager enabled (not automatable in simulator)

### Implementation for User Story 4

- [x] T019 [US4] Set `UIWindowScene.SizeRestrictions.minimumSize` in `Sonas/App/SceneDelegates/IPadSceneDelegate.swift`
      (new file)

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: User Story 5 - iPadOS-Specific Navigation Patterns (Priority: P3)

**Goal**: iPad user finds Sonas navigation intuitive via a sidebar, not a tab bar.

**Independent Test**: Launch Sonas on an iPad in landscape. Confirm the primary navigation is a sidebar or split-view
navigation controller, not a tab bar. Tap a navigation item and confirm the detail view appears in the trailing panel
rather than replacing the sidebar.

### Implementation for User Story 5

- [x] T020 [US5] Verify sidebar behavior at Regular horizontal size class in `IPadShell.swift`
- [x] T021 [US5] Verify tab bar fallback at Compact horizontal size class is unchanged in `Sonas/App/SonasApp.swift`
- [x] T022 [US5] Verify iPhone layout is unaffected in `Sonas/App/SonasApp.swift`

**Checkpoint**: All user stories should now be independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T023 Run quickstart.md validation
- [x] T024 Perform a regression check on iPhone simulator as described in `quickstart.md`
- [x] T025 Code cleanup and refactoring
- [x] T026 Documentation updates in `CLAUDE.md`, `README.md`, `spec.md`, and `quickstart.md`
- [x] T027 Run all existing tests (`xcodebuild test -scheme Sonas`)
- [x] T028 Update `README.md` with new feature details and platform support

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-7)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently
  testable
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently
  testable
- **User Story 4 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2/US3 but should be
  independently testable
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2/US3/US4 but should be
  independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models/Enums before views that depend on them
- Views before integrating into parent views
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- Tasks marked [P] can run in parallel (different files, no dependencies)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (if tests requested):
Task: "Create IPadLayoutUITests for basic dashboard layout in SonasUITests/IPadLayoutUITests.swift"

# Launch all implementations for User Story 1 together (after tests fail):
Task: "Create IPadShell (NavigationSplitView root) in Sonas/Platform/iPad/IPadShell.swift"
Task: "Modify SonasApp to inject IPadShell at root for Regular width in Sonas/App/SonasApp.swift"
Task: "Modify DashboardView to consume IPadShell in Sonas/Features/Dashboard/DashboardView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Add User Story 5 → Test independently → Deploy/Demo
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
   - Developer D: User Story 4
   - Developer E: User Story 5
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
