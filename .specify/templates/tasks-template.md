---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Include test tasks required by the Tilawa Workspace Constitution.
Unit tests are mandatory for domain logic, BLoCs, repositories, mappers,
validators, error handling, and routing guards. Widget tests are mandatory for
reusable Tilawa UI Kit components, non-trivial feature widgets, responsive or
adaptive layouts, RTL behavior, accessibility-relevant states, and BLoC-driven
presentation states. Performance-sensitive changes require targeted regression
tests and performance evidence. Omit required tests only when an approved waiver
is documented with owner and expiry.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app feature**: `apps/[app_name]/lib/features/[feature]/`
  and `apps/[app_name]/test/features/[feature]/`
- **Domain layer**: `domain/entities/`, `domain/repositories/`,
  `domain/usecases/`
- **Data layer**: `data/models/`, `data/mappers/`, `data/datasources/`,
  `data/repositories/`
- **Presentation layer**: `presentation/bloc/`, `presentation/pages/`,
  `presentation/widgets/`
- **Shared core**: `packages/core/lib/` and `packages/core/test/`
- **Tilawa UI Kit**: `packages/ui_kit/lib/src/` and `packages/ui_kit/test/`
- Paths shown below are examples. Generated tasks MUST use concrete paths from
  `plan.md`.

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/
  
  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment
  
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Tech Stack Reference (Tilawa Workspace)

**Language/Runtime**: Flutter / Dart 3.x+  
**State Management**: BLoC, Cubit (flutter_bloc)  
**Routing**: GoRouter with deep-linking  
**Storage**: Hydrated BLoC, HydratedStorage, local_preferences, secure_storage  
**Testing**: `flutter test` (unit + widget), golden tests, benchmark tests  
**UI Design**: Tilawa UI Kit with atomic design (foundation, atoms, molecules, organisms)  
**Dart/Flutter Idioms**: Prefer `Row`/`Column`/`Flex.spacing` for simple fixed gaps and Dart dot shorthands where receiver type is obvious  
**Core Utilities**: packages/core (logging, DI via getIt, error handling, network)  
**Performance**: 60 fps target, <500ms startup, smooth Quran text rendering  
**Constraints**: RTL support (Arabic/LTR), offline capability, accessibility (a11y)

---

## Phase 1: Setup (Tilawa Feature Structure)

**Purpose**: Initialize Tilawa feature following Clean Architecture boundaries

**Architecture Checkpoint**:
- [ ] T001 [P] Verify plan.md has Constitution Check gates passing (clean layers, BLoC, GoRouter, UI Kit)
- [ ] T002 Create feature folder structure: `apps/tilawa/lib/features/[feature]/`
  - `domain/entities/`, `domain/repositories/`, `domain/usecases/`
  - `data/models/`, `data/mappers/`, `data/datasources/`, `data/repositories/`
  - `presentation/bloc/`, `presentation/pages/`, `presentation/widgets/`
- [ ] T003 [P] Add feature to pubspec.yaml dependencies (if new package)
- [ ] T004 [P] Configure BLoC provider setup in `presentation/bloc/[feature]_bloc.dart` or `_cubit.dart`
- [ ] T005 Create test scaffolding: `apps/tilawa/test/features/[feature]/`
  - Mirror `lib/features/[feature]` structure for test organization

---

## Phase 2: Domain Layer (Foundation - Must Complete Before Data/Presentation)

**Purpose**: Define domain contracts and business logic independent of Flutter/persistence

**⚠️ CRITICAL**: Domain MUST NOT import Flutter, routing, or data layers. This phase establishes the contracts all other layers depend on.

- [ ] T006 [P] Create domain entities in `domain/entities/[entity].dart` (immutable, no Flutter imports)
- [ ] T007 [P] Create value objects in `domain/entities/[value_object].dart` if needed for type safety
- [ ] T008 [P] Define repository contracts in `domain/repositories/[repository].dart` (pure Dart interfaces)
- [ ] T009 [P] Define use cases in `domain/usecases/[use_case].dart` (call repo contracts, apply business rules)
- [ ] T010 [P] Create failure/error types in `domain/failures/[failures].dart` if custom error handling needed
- [ ] T011 [P] **[TEST]** Unit test entities and value objects in `test/features/[feature]/domain/entities/`
- [ ] T012 [P] **[TEST]** Unit test use cases with mock repositories in `test/features/[feature]/domain/usecases/`

**Checkpoint**: Domain layer complete and independently testable - no dependencies on Flutter or external services

---

## Phase 3: Data Layer (Repository Implementations)

**Purpose**: Implement concrete repositories, mappers, and data sources that fulfill domain contracts

- [ ] T013 [P] Create DTOs in `data/models/[dto].dart` (maps to external/internal data format)
- [ ] T014 [P] Create mappers in `data/mappers/[mapper].dart` (DTO ↔ Domain Entity translation)
- [ ] T015 [P] Create local data source in `data/datasources/[local_data_source].dart` if using SharedPreferences/Hive
- [ ] T016 [P] Create remote data source in `data/datasources/[remote_data_source].dart` if using APIs
- [ ] T017 [P] Implement repository in `data/repositories/[repository]_impl.dart` (orchestrates data sources, applies mappers)
- [ ] T018 [P] Add dependency injection wiring in DI setup (packages/core or app bootstrap)
- [ ] T019 [P] **[TEST]** Unit test mappers with realistic DTOs in `test/features/[feature]/data/mappers/`
- [ ] T020 [P] **[TEST]** Unit test data sources (mocked HTTP/local storage) in `test/features/[feature]/data/datasources/`
- [ ] T021 **[TEST]** Unit test repository implementations in `test/features/[feature]/data/repositories/`

**Checkpoint**: Data layer complete - repositories fulfill domain contracts

---

## Phase 4: Presentation Layer - BLoC/State Management (User Stories Begin)

**Purpose**: Build state management for each user story using BLoC pattern

- [ ] T022 [P] Create BLoC events in `presentation/bloc/[feature]_event.dart`
- [ ] T023 [P] Create BLoC states in `presentation/bloc/[feature]_state.dart` (immutable, sealed/union recommended)
- [ ] T024 Create BLoC/Cubit implementation in `presentation/bloc/[feature]_bloc.dart` or `_cubit.dart`
  - Inject use cases, handle events, emit states
  - Add structured logging for state transitions and errors
- [ ] T025 **[TEST]** Unit test BLoC event→state mappings in `test/features/[feature]/presentation/bloc/`
  - Mock repositories/use cases
  - Verify state changes for success/failure scenarios

**Checkpoint**: BLoC state machine testable independently of UI

---

## Phase 5: Presentation Layer - UI & Routing

---

## Phase 5: Presentation Layer - UI & Routing

**Purpose**: Build user-facing widgets using Tilawa UI Kit, integrate with BLoC and GoRouter

- [ ] T026 [P] Plan Tilawa UI Kit component usage (atoms, molecules, organisms) - reference `packages/ui_kit/lib/src/`
- [ ] T027 [P] Create pages/screens in `presentation/pages/` - wire BLoC with BlocBuilder/BlocListener
- [ ] T028 [P] Create reusable widgets in `presentation/widgets/` (extract from pages if shared across features)
  - Use `Row`/`Column`/`Flex.spacing` instead of separator `SizedBox` widgets for simple fixed gaps
  - Use Dart dot shorthands for enum-like/static values where the receiver type is obvious
- [ ] T029 Create routes in GoRouter configuration (`apps/tilawa/lib/routing/` or feature-local routing)
  - Add route path, builder, guards, deep-linking if applicable
- [ ] T030 Add structured logging for route transitions, user interactions
- [ ] T031 **[TEST]** Widget test for page state rendering in `test/features/[feature]/presentation/pages/`
  - Test BLoC state → UI rendering mapping
- [ ] T032 **[TEST]** Widget test for responsive/RTL behavior in `test/features/[feature]/presentation/pages/`
  - Compact, medium, expanded layouts
  - RTL text/icon mirroring (Arabic)
  - Safe area and padding
- [ ] T033 **[TEST]** Widget test for accessibility (a11y) if user-facing state changes
  - Screen reader semantics
  - Touch target sizes

**Checkpoint**: Feature fully renders with BLoC → UI flow working end-to-end

---

## Phase 6: Integration & Performance Validation

**Purpose**: Verify feature works in full app context and meets performance targets

- [ ] T034 Integration test: Feature launched from app root, user flows complete
- [ ] T035 **[TEST]** Performance regression test for critical path (scroll, tap, load)
  - Use DevTools profiler or benchmark test
  - Record baseline in `specs/[###-feature-name]/quickstart.md` or `plan.md`
  - Target: 60 fps, <500ms critical operations, no jank
- [ ] T036 Device testing: Feature works on low-end device (e.g., Snapdragon 600 series)
- [ ] T037 Test offline behavior if feature requires network
- [ ] T038 Verify RTL rendering on Arabic device/emulator
- [ ] T039 Golden test snapshots for visual regression (if UI Kit changes)

**Checkpoint**: Feature meets performance, accessibility, and localization requirements

---

## Constitution Compliance Checklist (Must Pass Before Merge)

**Reference**: `.specify/memory/constitution.md`

- [ ] **Clean Architecture**: Domain has no Flutter imports, data implements domain contracts, presentation depends on domain
- [ ] **BLoC State Management**: Feature state driven by BLoC/Cubit, widgets ephemeral state only
- [ ] **GoRouter**: Routes declared, deep-linking supported, guards in place if needed
- [ ] **Tilawa UI Kit**: Shared UI from packages/ui_kit, components classified (foundation/atom/molecule/organism)
- [ ] **Dart/Flutter Idioms**: UI code uses `spacing` properties and Dart dot shorthands where appropriate
- [ ] **Responsive/Adaptive**: Compact/medium/expanded layouts planned, RTL behavior verified
- [ ] **Performance**: Hot paths avoid build(), scroll/startup/Quran text rendering measured, jank regression tested
- [ ] **Structured Logging**: BLoC transitions, route decisions, failures, async durations logged
- [ ] **Testing**: Unit tests for domain/data, widget tests for presentation, performance tests for critical paths
- [ ] **Safe Refactoring**: Scope clear, migration plan documented, downstream impact assessed

- [ ] T029 [P] [US3] Unit test for [use case/BLoC/mapper] in apps/[app_name]/test/features/[feature]/[layer]/[name]_test.dart
- [ ] T030 [P] [US3] Widget test for [page/widget/state] in apps/[app_name]/test/features/[feature]/presentation/[name]_test.dart

### Implementation for User Story 3

- [ ] T031 [P] [US3] Extend domain behavior in apps/[app_name]/lib/features/[feature]/domain/[path]/[file].dart
- [ ] T032 [US3] Implement data/persistence behavior in apps/[app_name]/lib/features/[feature]/data/[path]/[file].dart
- [ ] T033 [US3] Implement BLoC and UI behavior in apps/[app_name]/lib/features/[feature]/presentation/[path]/[file].dart

**Checkpoint**: All user stories MUST now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance profiling/evidence for performance-sensitive paths
- [ ] TXXX [P] Additional unit/widget tests for critical paths and regressions
- [ ] TXXX [P] Analyzer and formatter validation
- [ ] TXXX Security hardening
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but MUST remain independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but MUST remain independently testable

### Within Each User Story

- Required tests MUST be written and FAIL before implementation
- Domain contracts and entities before data implementations
- Use cases before BLoC behavior
- BLoC behavior before UI wiring
- GoRouter integration after routes and guards are defined
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for [use case/BLoC/mapper] in apps/[app_name]/test/features/[feature]/..."
Task: "Widget test for [page/widget/state] in apps/[app_name]/test/features/[feature]/..."

# Launch independent layer tasks for User Story 1 together:
Task: "Create domain entity in apps/[app_name]/lib/features/[feature]/domain/entities/..."
Task: "Create Tilawa UI Kit component test in packages/ui_kit/test/..."
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
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story MUST be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
