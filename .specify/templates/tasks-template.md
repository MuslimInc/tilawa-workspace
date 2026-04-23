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

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 Establish feature folder structure under apps/[app_name]/lib/features/[feature]/
- [ ] T005 [P] Define domain entities and repository contracts used by all stories
- [ ] T006 [P] Configure BLoC providers and dependency injection boundaries
- [ ] T007 Add GoRouter route shell, redirect, or deep-link wiring for the feature
- [ ] T008 Configure structured logging and diagnostics context for the feature
- [ ] T009 Identify Tilawa UI Kit components, tokens, and responsive constraints required by the feature
- [ ] T010 Define test fixtures, fakes, and performance measurement approach for critical paths

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T011 [P] [US1] Unit test for [use case/BLoC/mapper] in apps/[app_name]/test/features/[feature]/[layer]/[name]_test.dart
- [ ] T012 [P] [US1] Widget test for [page/widget/state] in apps/[app_name]/test/features/[feature]/presentation/[name]_test.dart
- [ ] T013 [P] [US1] Responsive/RTL widget test for [surface] in apps/[app_name]/test/features/[feature]/presentation/[name]_test.dart
- [ ] T014 [US1] Performance regression task for [critical path] with evidence recorded in specs/[###-feature-name]/quickstart.md or plan.md

### Implementation for User Story 1

- [ ] T015 [P] [US1] Create domain entity/value object in apps/[app_name]/lib/features/[feature]/domain/entities/[entity].dart
- [ ] T016 [P] [US1] Create repository contract in apps/[app_name]/lib/features/[feature]/domain/repositories/[repository].dart
- [ ] T017 [US1] Implement use case in apps/[app_name]/lib/features/[feature]/domain/usecases/[use_case].dart
- [ ] T018 [US1] Implement data model/mapper in apps/[app_name]/lib/features/[feature]/data/[path]/[file].dart
- [ ] T019 [US1] Implement BLoC/Cubit in apps/[app_name]/lib/features/[feature]/presentation/bloc/[bloc].dart
- [ ] T020 [US1] Implement page/widget using Tilawa UI Kit components in apps/[app_name]/lib/features/[feature]/presentation/[path]/[file].dart
- [ ] T021 [US1] Wire GoRouter route or redirect in apps/[app_name]/lib/[routing_path]/[file].dart
- [ ] T022 [US1] Add structured logging for state transitions, failures, and async durations

**Checkpoint**: At this point, User Story 1 MUST be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2

- [ ] T023 [P] [US2] Unit test for [use case/BLoC/mapper] in apps/[app_name]/test/features/[feature]/[layer]/[name]_test.dart
- [ ] T024 [P] [US2] Widget test for [page/widget/state] in apps/[app_name]/test/features/[feature]/presentation/[name]_test.dart

### Implementation for User Story 2

- [ ] T025 [P] [US2] Extend domain contract or use case in apps/[app_name]/lib/features/[feature]/domain/[path]/[file].dart
- [ ] T026 [US2] Implement data source/repository change in apps/[app_name]/lib/features/[feature]/data/[path]/[file].dart
- [ ] T027 [US2] Implement BLoC state/event changes in apps/[app_name]/lib/features/[feature]/presentation/bloc/[bloc].dart
- [ ] T028 [US2] Implement UI changes using Tilawa UI Kit components in apps/[app_name]/lib/features/[feature]/presentation/[path]/[file].dart

**Checkpoint**: At this point, User Stories 1 AND 2 MUST both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3

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
