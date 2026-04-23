<!--
Sync Impact Report:
- Version change: 1.1.0 -> 1.2.0
- Modified principles:
  - I. Strict Layered Clean Architecture -> I. Clean Architecture Boundaries
  - II. Reactive State Management & Routing: strengthened BLoC and GoRouter rules
  - III. Atomic Design & Tilawa UI Kit: added design-token and component ownership gates
  - IV. Performance-First Development (Anti-Jank) -> IV. Performance-First Flutter Delivery
  - V. High Observability & Diagnostics -> V. Structured Observability & Diagnostics
  - VI. Safe Delivery Rules -> VI. Safe Refactoring & Delivery
- Added sections:
  - None
- Removed sections:
  - None
- Templates requiring updates:
  - /Users/mohammadkamel/flutter_projects/tilawa_workspace/.specify/templates/plan-template.md: ✅ updated - Constitution Check now enumerates Tilawa-specific gates.
  - /Users/mohammadkamel/flutter_projects/tilawa_workspace/.specify/templates/spec-template.md: ✅ updated - already requires independently testable stories and measurable outcomes.
  - /Users/mohammadkamel/flutter_projects/tilawa_workspace/.specify/templates/tasks-template.md: ✅ updated - tests now reflect Tilawa critical-path gates.
  - /Users/mohammadkamel/flutter_projects/tilawa_workspace/.specify/templates/checklist-template.md: ✅ updated - generic checklist generation remains compatible.
  - /Users/mohammadkamel/flutter_projects/tilawa_workspace/.specify/templates/commands: ✅ updated - directory is not present in this workspace.
- Follow-up TODOs: None
-->

# Tilawa Workspace Constitution

## Core Principles

### I. Clean Architecture Boundaries
Tilawa Workspace MUST preserve Clean Architecture boundaries across every Flutter
app and shared package.

- **Layer Rule**: Domain owns entities, value objects, repository contracts, and
  use cases. Domain MUST NOT depend on Flutter UI, routing, persistence, network,
  generated data models, or presentation state.
- **Presentation Rule**: Presentation contains widgets, pages, routes, and BLoC
  state. Presentation MUST depend on domain abstractions and MUST NOT import data
  implementations directly.
- **Data Rule**: Data implements repositories, data sources, DTOs, serializers,
  and mappers. Data MUST translate external models into domain types at the layer
  boundary.
- **Dependency Direction**: Dependencies MUST point toward domain contracts.
  Cross-feature dependencies MUST go through explicit public APIs or shared
  packages, not private implementation files.
- **Feature Cohesion**: Feature-first organization is permitted only when the
  internal presentation, domain, and data boundaries remain visible and reviewable.

### II. Reactive State Management & Routing
Feature behavior MUST be driven by predictable BLoC state and declarative routing.

- **BLoC**: Feature state, workflows, and user-triggered business behavior MUST
  use BLoC package patterns (`Bloc` or `Cubit`) with explicit immutable states.
- **Widget State**: Local widget state is limited to ephemeral view concerns such
  as focus, animation, and controller lifecycle. Business decisions MUST NOT live
  in widgets.
- **GoRouter**: GoRouter MUST be the source of truth for app routes, deep links,
  redirects, and guarded navigation. Direct `Navigator` usage is limited to local
  surfaces such as dialogs, sheets, and nested ephemeral flows.
- **State Transitions**: BLoC events, state names, and route transitions MUST be
  clear enough to test and diagnose without reading widget internals.

### III. Atomic Design & Tilawa UI Kit
Reusable UI MUST be built through Atomic Design and the Tilawa UI Kit.

- **Component Ownership**: Shared reusable UI belongs in the Tilawa UI Kit and
  MUST be classified as foundation, atom, molecule, organism, or layout primitive.
- **Token Usage**: Colors, typography, spacing, radius, elevation, and breakpoints
  MUST come from theme, localization, or Tilawa UI Kit tokens. Hard-coded visual
  constants are allowed only inside token definitions or documented one-off
  measurements.
- **Reuse Before Custom UI**: Feature UI MUST reuse existing Tilawa UI Kit
  components before adding new local components. New reusable components require
  tests and public API documentation appropriate to their scope.
- **Responsive Contract**: Screens and reusable components MUST support compact,
  medium, expanded, RTL, safe-area, and text-scaling constraints relevant to their
  surface.

### IV. Performance-First Flutter Delivery
Low jank and fast interaction are release requirements, not polish work.

- **Build Discipline**: `build` methods MUST be free of network calls, disk I/O,
  parsing, expensive text measurement, and avoidable object churn.
- **Rebuild Control**: State selection, widget decomposition, `const`
  constructors, keys, and memoized inputs MUST be used where they reduce rebuild
  cost or layout instability.
- **Async Work**: Expensive CPU work, large data transforms, font or asset
  preparation, and repeated calculations MUST run outside hot UI paths through
  caching, isolates, precomputation, debouncing, or throttling.
- **Measurement**: Performance-sensitive changes MUST include profiling evidence,
  benchmark output, or a documented local measurement plan with regression
  thresholds.
- **Frame Budget**: Code touching scrolling, page transitions, Quran text
  rendering, audio controls, startup, or adaptive layout MUST be reviewed for
  frame budget impact.

### V. Structured Observability & Diagnostics
The codebase MUST be diagnosable in development, test, and production builds.

- **Structured Logging**: Production diagnostics MUST use structured logging, not
  ad hoc `print` output. Logs MUST include feature or screen context, operation
  name, error category when applicable, and duration for async or performance
  sensitive operations.
- **State Diagnostics**: BLoC transitions, guarded route decisions, repository
  failures, retries, and recoverable errors MUST be observable at the appropriate
  log level without exposing secrets or personal data.
- **Traceability**: Logs and errors MUST preserve enough context to connect a user
  action, state transition, data operation, and failure path during debugging.
- **Maintainability**: Complexity, custom abstractions, and cross-cutting helpers
  MUST have a clear owner and reviewable purpose.

### VI. Safe Refactoring & Delivery
Changes MUST preserve architectural integrity and keep delivery reversible.

- **Scoped Changes**: PRs MUST separate behavior changes from broad refactors
  unless the refactor is required to deliver the behavior safely.
- **Boundary Protection**: Refactors MUST preserve or improve layer boundaries,
  public APIs, tests, and diagnostics. Any temporary violation requires a waiver
  under Governance.
- **Reviewability**: Large changes MUST include a migration plan, affected paths,
  test strategy, and rollback or mitigation notes.
- **Compatibility**: Shared package and Tilawa UI Kit changes MUST document
  downstream impact on apps and feature teams.

## Development Quality Standards

- **Naming Conventions**: Classes use PascalCase, members and functions use
  camelCase, files use snake_case, and generated files follow generator defaults.
- **SOLID**: Classes, BLoCs, use cases, repositories, and widgets MUST have
  focused responsibilities and explicit dependencies.
- **Dependency Injection**: Runtime dependencies MUST be injected through approved
  project patterns. Hidden singletons and service lookups are allowed only for
  established infrastructure boundaries.
- **Configuration**: User-facing strings, dimensions, colors, and environment
  values MUST be managed through localization, themes, tokens, constants, or
  typed configuration.
- **Static Quality**: Flutter and Dart analyzer warnings, formatting failures,
  and project lint violations block merge unless an approved waiver exists.

## Testing Discipline

- **Unit Tests**: Domain use cases, entities with behavior, validators, BLoCs,
  repositories, data mappers, error handling, and routing guards MUST have unit
  tests covering success, failure, and edge cases.
- **Widget Tests**: Reusable Tilawa UI Kit components, non-trivial feature
  widgets, responsive/adaptive layouts, RTL behavior, accessibility-relevant
  states, and BLoC-driven presentation states MUST have widget tests.
- **Critical Paths**: Critical paths are P1 user stories plus app startup, Quran
  reader rendering and navigation, ayah interaction, audio/player controls,
  qibla behavior, settings persistence, offline/cache behavior, authentication
  or onboarding when present, and any flow named as release-critical in a spec or
  plan.
- **Performance-Sensitive Tests**: Changes to scrolling, large lists or grids,
  font/text rendering, image or audio loading, startup, route transitions,
  isolates, caching, or adaptive layout MUST include targeted regression tests
  and performance evidence appropriate to the risk.
- **Regression Protection**: No PR may reduce meaningful coverage or remove tests
  for critical paths without a documented replacement or approved waiver.
- **Determinism**: Tests MUST be deterministic, isolated from real network and
  wall-clock timing, and use fakes, fixtures, or controlled clocks for external
  dependencies.

## Governance

This Constitution is the highest project-level authority for Tilawa Workspace.
Specs, plans, tasks, PRs, and architecture decisions MUST comply with it.

- **Amendment Procedure**: Amendments require a PR that changes this file,
  updates the Sync Impact Report, records rationale, identifies affected
  templates or docs, updates the version and Last Amended date, and receives
  approval from the project maintainer or designated architecture owner.
- **Semantic Versioning**: MAJOR increments remove or redefine principles,
  governance rules, or compatibility expectations in a way that forces existing
  accepted work to change. MINOR increments add principles, sections, mandatory
  gates, or materially expanded guidance. PATCH increments clarify wording,
  fix typos, or improve examples without changing compliance obligations.
- **Compliance Review**: Every PR MUST state the affected constitutional
  principles, tests performed, and any waiver. Architecture decisions MUST record
  how the decision satisfies architecture, performance, testing, observability,
  and delivery rules.
- **Spec Kit Checks**: Feature plans MUST include a Constitution Check before
  design work and repeat it after design. Task lists MUST include concrete tasks
  for required tests, diagnostics, performance work, and UI Kit updates.
- **Waivers**: Temporary exceptions MUST be documented in the PR or architecture
  decision with the waived principle, scope, reason, owner, expiry date, risk,
  mitigation, and cleanup task. Expired waivers block related work until resolved.
- **Conflict Resolution**: When speed conflicts with this Constitution, the
  Constitution prevails unless an approved, time-boxed waiver exists.

**Version**: 1.2.0 | **Ratified**: 2026-04-23 | **Last Amended**: 2026-04-23
