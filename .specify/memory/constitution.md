<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0  (initial ratification)
Version bump rationale: First adoption — MAJOR version 1, no prior baseline.

Modified principles: N/A (initial creation)

Added sections:
  - Core Principles (I–IV)
  - Quality Standards
  - Development Workflow
  - Governance

Removed sections: N/A

Templates requiring updates:
  - .specify/templates/plan-template.md  ✅ Constitution Check gate aligns with principles below
  - .specify/templates/spec-template.md  ✅ Success Criteria section requires measurable UX + performance metrics
  - .specify/templates/tasks-template.md ✅ Phase N polish tasks include performance + accessibility verification

Follow-up TODOs:
  - None. All placeholders resolved.
-->

# Sonas Constitution

## Core Principles

### I. Code Quality (NON-NEGOTIABLE)

Every line of code merged into the main branch MUST meet the following bar:

- Code MUST be readable without inline comments; extract to named functions/variables before resorting to explanatory
  comments.
- Functions MUST have a single, clear responsibility; keep cyclomatic complexity ≤ 10 per function.
- External interfaces (APIs, components, data models) MUST be explicitly typed; no implicit `any` or untyped public
  surfaces.
- Dependencies MUST be chosen deliberately: evaluate maintenance status, license compatibility, and bundle-size impact
  before adding a new package.
- Dead code, unused imports, and commented-out blocks MUST be removed before merge; version control preserves history.
- All PRs MUST pass lint and static-analysis gates with zero suppressions unless the suppression includes a tracking
  issue reference and expiry date.

Rationale: Sonas is a household-critical app that family members rely on daily. Unclear or fragile code compounds over
time and slows the delivery of features that matter to real families.

### II. Test-First Development (NON-NEGOTIABLE)

Testing is not optional and MUST follow the Red-Green-Refactor cycle:

- Tests MUST be written and confirmed to fail before implementation begins.
- Every user-facing feature MUST have at least one acceptance/integration test that exercises the full path from input
  to observable output.
- Unit tests MUST cover all business-logic functions; aim for ≥ 80 % line coverage on `src/` directories; coverage MUST
  NOT regress between PRs.
- Contract tests MUST be written for every external integration (location services, calendar APIs, notification
  providers) to guard against upstream breakage.
- Flaky tests MUST be quarantined and fixed within one sprint; a flaky test is treated as a failing test for merge-gate
  purposes.
- Test names MUST follow the pattern `given_<state>_when_<action>_then_<outcome>` or an equivalent BDD format so
  failures are self-documenting.

Rationale: Family members act on data shown by Sonas (locations, schedules). Incorrect data or broken features erode
trust quickly; a strong test baseline is the earliest safeguard.

### III. User Experience Consistency

Every surface presented to family members MUST feel like one cohesive product:

- Visual language (colours, typography, spacing, iconography) MUST follow the established design system; deviations
  require documented design-system amendments.
- Interactive elements (buttons, modals, loading states, error messages) MUST reuse shared components; new one-off
  components require a justification comment in the PR.
- Error messages shown to users MUST be human-readable and actionable; technical identifiers or stack traces MUST never
  surface in the UI.
- Navigation patterns MUST remain consistent; a user MUST always know where they are and how to return to a previous
  context.
- Accessibility MUST be treated as a first-class requirement: all interactive elements MUST be keyboard-navigable and
  meet WCAG 2.1 AA colour-contrast ratios.
- New screens and flows MUST be validated against the family-member mental model described in the product brief before
  merging; screenshots or recordings MUST be attached to the PR.

Rationale: Sonas is used by all family members — including children and less tech-savvy adults. A consistent,
predictable interface reduces friction and increases adoption.

### IV. Performance Requirements

Sonas MUST remain fast and responsive under normal household usage:

- Initial page/screen load MUST complete in ≤ 2 s on a mid-range device over a residential broadband connection (≥ 25
  Mbps).
- Location and calendar data MUST refresh within ≤ 5 s of a user-triggered action; background refresh latency MUST not
  exceed 60 s.
- UI interactions (button presses, navigation transitions) MUST respond within ≤ 100 ms to maintain perceived immediacy.
- Cumulative Layout Shift (CLS) MUST be < 0.1; Largest Contentful Paint (LCP) MUST be ≤ 2.5 s (Core Web Vitals
  thresholds for web surfaces).
- Memory usage MUST be profiled for every feature that introduces continuous polling or real-time subscriptions; leaks
  MUST be caught in review, not production.
- Performance baselines MUST be recorded in the feature plan and verified in the task checklist before the feature is
  considered done.

Rationale: The Command Center is often glanced at in passing (morning rush, quick check before pickup). Sluggishness
undermines the core value proposition of fast, at-a-glance family awareness.

## Quality Standards

### Linting & Formatting

- Linting and formatting MUST be enforced by automated tooling (e.g., ESLint/Prettier for TypeScript, Ruff/Black for
  Python); configuration lives in the repo root.
- No PR may be merged with lint errors; warnings MUST either be resolved or converted to tracked issues with an expiry
  milestone.

### Dependency Management

- Direct dependencies MUST be pinned to exact versions in lock files.
- Dependency updates MUST be reviewed for changelog breaking changes, not auto-merged without a passing full test suite.
- Transitive vulnerabilities flagged by the security scanner MUST be resolved within 7 days (critical) or 30 days
  (high).

### Logging & Observability

- Structured logging MUST be used throughout; key family-data events (location update, event sync, notification sent)
  MUST emit logs at INFO level.
- No PII (names, addresses, precise coordinates) MUST appear in log output at DEBUG or above unless the deployment
  environment is flagged as local-only.

## Development Workflow

### Branch & PR Process

1. Feature work MUST live on a short-lived branch named `###-short-description`.
2. PRs MUST reference the spec or issue that motivated them.
3. PRs MUST include: summary of changes, screenshots/recordings for UI changes, and a test plan confirming acceptance
   criteria are met.
4. At least one peer review approval is REQUIRED before merge; self-merges are forbidden on `main`.

### Constitution Check Gate

Before moving from research to design (Plan Phase 1), the plan document MUST explicitly verify compliance with each
principle:

- [ ] Code Quality: complexity and typing constraints can be satisfied by the proposed approach.
- [ ] Test-First: acceptance and integration tests identified; test-failure baseline can be established before coding
      begins.
- [ ] UX Consistency: no new one-off components; design-system components identified.
- [ ] Performance: load-time and interaction-time budgets defined; profiling strategy identified for any
      polling/subscription work.

Any violation MUST be logged in the plan's Complexity Tracking table with justification and an alternative that was
considered and rejected.

## Governance

- This constitution supersedes all other development practices; conflicts resolve in its favour.
- Amendments require: (a) a written proposal explaining the change, (b) approval from at least two active contributors,
  and (c) a migration plan for any in-flight work affected by the change.
- MAJOR amendments (principle removal or redefinition) require a one-sprint notice period before taking effect.
- All PRs and code reviews MUST verify compliance with this constitution; reviewers MUST explicitly note any principle
  violation observed.
- Complexity exceptions documented in plan files expire after the feature ships; they do not grant permanent licence to
  deviate.

**Version**: 1.0.0 | **Ratified**: 2026-04-07 | **Last Amended**: 2026-04-07
