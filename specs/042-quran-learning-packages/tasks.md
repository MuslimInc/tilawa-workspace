# Tasks: Quran Learning Packages

**Input**: Design documents from `specs/042-quran-learning-packages/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md  
**Tests**: Mandatory for domain/accounting, privileged mutations, authorization, rules, BLoCs, UI states, concurrency, idempotency, and critical E2E paths.

## Phase 1: Setup and Regression Baseline

**Purpose**: Protect existing individual booking/manual-payment behavior before adding an entitlement source.

- [ ] T001 Record current package, app, functions, rules, and admin baseline commands/results in specs/042-quran-learning-packages/quickstart.md
- [ ] T002 [P] Add pay-per-session regression fixtures for package-null bookings in functions/test/quranSessions/createSessionBooking.test.ts
- [ ] T003 [P] Add existing cancellation/no-show behavior baselines in functions/test-integration/quranSessionLifecycle.integration.test.ts
- [ ] T004 [P] Add existing Egypt manual-payment confirmation/rejection baselines in functions/test-integration/manualPackagePaymentBaseline.integration.test.ts
- [ ] T005 Document collection ownership, claims, feature flags, metrics, and rollback owners in docs/quran_sessions/package_operations.md

**Checkpoint**: Existing booking and manual-payment behavior is executable and unchanged when `packageId` is absent.

---

## Phase 2: Foundational Package and Credit Boundary

**Purpose**: Create shared types, authorization, atomic accounting, rules, and projections that block every user story.

**⚠️ CRITICAL**: No story implementation begins until package invariants and server-only writes pass.

- [ ] T006 [P] Add package/order/credit domain entities and value objects in packages/quran_sessions/lib/src/domain/entities/quran_learning_package.dart
- [ ] T007 [P] Add package failure hierarchy in packages/quran_sessions/lib/src/domain/failures/quran_package_failure.dart
- [ ] T008 [P] Add package repository and command gateway contracts in packages/quran_sessions/lib/src/domain/repositories/quran_package_repository.dart
- [ ] T009 [P] Add package DTOs and mappers with invariant validation in packages/quran_sessions/lib/src/data/dtos/quran_package_dto.dart and packages/quran_sessions/lib/src/data/mappers/quran_package_mapper.dart
- [ ] T010 Add package catalog, order, entitlement, and movement TypeScript types in functions/src/quranSessions/packages/packageTypes.ts
- [ ] T011 Implement atomic issue/reserve/consume/restore/expire/adjust service with deterministic movement ids in functions/src/quranSessions/packages/packageCreditService.ts
- [ ] T012 Implement package authorization and granular admin-claim guards in functions/src/quranSessions/packages/packageAuth.ts
- [ ] T013 Implement bounded package/order/activity query projections in functions/src/quranSessions/packages/packageProjectionService.ts
- [ ] T014 [P] Add unit tests for invariants, concurrency preconditions, and deterministic movements in functions/test/quranSessions/packageCreditService.test.ts
- [ ] T015 [P] Add Dart entity/mapper success, corruption, and edge tests in packages/quran_sessions/test/domain/quran_learning_package_test.dart and packages/quran_sessions/test/data/quran_package_mapper_test.dart
- [ ] T016 Add Firestore deny-client-write and participant/admin read boundaries in firestore.rules
- [ ] T017 Add required bounded query indexes in firestore.indexes.json
- [ ] T018 [P] Add owner/guardian/teacher/admin/unauthorized rules tests in functions/test-rules/quranPackages.rules.test.ts
- [ ] T019 Export package callables and shared services through functions/src/index.ts and register Flutter package dependencies in apps/tilawa/lib/features/quran_sessions/di/quran_sessions_module.dart

**Checkpoint**: Package counters and ledger remain consistent under duplicate and concurrent events; clients cannot mutate operational documents.

---

## Phase 3: User Story 1 — Purchase and Activate a Package (Priority: P1) 🎯 Sale MVP

**Goal**: Sell one Egypt eight-session package via manual payment and activate it once.

**Independent Test**: Submit one eligible Egypt order, confirm payment, and observe exactly one active package with eight credits; reject/retry/non-Egypt paths have no entitlement effect.

- [ ] T020 [P] [US1] Add create/cancel order and resolve-payment use cases in packages/quran_sessions/lib/src/domain/usecases/quran_package_order_usecases.dart
- [ ] T021 [P] [US1] Implement `createQuranPackageOrder` with immutable terms/payment snapshot in functions/src/quranSessions/packages/createPackageOrder.ts
- [ ] T022 [P] [US1] Implement owner/guardian pending-order cancellation in functions/src/quranSessions/packages/cancelPackageOrder.ts
- [ ] T023 [US1] Implement idempotent admin confirm/reject and one-time package activation in functions/src/quranSessions/packages/resolvePackagePayment.ts
- [ ] T024 [P] [US1] Implement Firebase package command/read gateways in apps/tilawa/lib/features/quran_sessions/data/firebase/firebase_quran_package_gateway.dart
- [ ] T025 [US1] Add order/pending-payment/activation BLoC states in packages/quran_sessions/lib/src/presentation/blocs/package_order/package_order_bloc.dart
- [ ] T026 [US1] Build localized package disclosure, payment instruction, and pending screens in packages/quran_sessions/lib/src/presentation/screens/quran_package_checkout_screen.dart
- [ ] T027 [US1] Add typed package routes and feature-gate redirects in packages/quran_sessions/lib/src/presentation/router/quran_package_routes.dart and apps/tilawa/lib/features/quran_sessions/router/quran_sessions_router.dart
- [ ] T028 [P] [US1] Add callable validation/idempotency/market tests in functions/test/quranSessions/packageOrderCallables.test.ts
- [ ] T029 [P] [US1] Add activation/rejection/concurrent-confirm emulator tests in functions/test-integration/quranPackageOrder.integration.test.ts
- [ ] T030 [P] [US1] Add checkout/pending/error/RTL/text-scale widget tests in packages/quran_sessions/test/presentation/quran_package_checkout_screen_test.dart

**Checkpoint**: Egypt package can be sold and activated without booking support.

---

## Phase 4: User Story 2 — Book and Account for Sessions (Priority: P1) 🎯 Usage MVP

**Goal**: Consume and restore package credits through the existing individual booking lifecycle.

**Independent Test**: Book one package session, restore it before cutoff, consume it for late cancellation, restore teacher-failure credit, and allow only one concurrent final-credit booking.

- [ ] T031 [P] [US2] Add package booking and balance/activity use cases in packages/quran_sessions/lib/src/domain/usecases/quran_package_booking_usecases.dart
- [ ] T032 [US2] Implement `createQuranPackageBooking` by composing existing eligibility/slot locks with atomic credit reservation in functions/src/quranSessions/packages/createPackageBooking.ts
- [ ] T033 [US2] Integrate deterministic credit finalization with cancellation, teacher response, no-show, completion, and expiry in functions/src/quranSessions/packages/packageLifecycleCreditAdapter.ts
- [ ] T034 [US2] Add optional package linkage without changing pay-per-session behavior in functions/src/quranSessions/createSessionBooking.ts
- [ ] T035 [US2] Implement expiration/reconciliation job and bounded mismatch report in functions/src/quranSessions/packages/reconcilePackageCredits.ts
- [ ] T036 [US2] Add package balance/activity repository implementation in apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_quran_package_repository.dart
- [ ] T037 [US2] Extend booking BLoC with package entitlement selection and authoritative balance refresh in packages/quran_sessions/lib/src/presentation/blocs/booking/booking_bloc.dart
- [ ] T038 [US2] Build package home/balance/activity states with Tilawa UI Kit in packages/quran_sessions/lib/src/presentation/screens/quran_package_detail_screen.dart
- [ ] T039 [P] [US2] Add credit policy/unit tests for every lifecycle result in functions/test/quranSessions/packageLifecycleCreditAdapter.test.ts
- [ ] T040 [P] [US2] Add final-credit concurrency, duplicate cancellation, expiry, and reconciliation integration tests in functions/test-integration/quranPackageBooking.integration.test.ts
- [ ] T041 [P] [US2] Add package booking/balance/activity BLoC and widget tests in packages/quran_sessions/test/presentation/quran_package_booking_test.dart

**Checkpoint**: Eight credits can be booked and reconciled without negative or duplicate balances.

---

## Phase 5: User Story 3 — Compatible Verified Teacher (Priority: P1)

**Goal**: Reduce teacher-fit risk through trustworthy discovery and one bounded compatibility meeting.

**Independent Test**: Filter eligible verified teachers, book one compatibility meeting, record recommendation, and block repeated allowance abuse.

- [ ] T042 [P] [US3] Extend verified teacher profile/filter entities without exposing evidence files in packages/quran_sessions/lib/src/domain/entities/quran_teacher.dart
- [ ] T043 [P] [US3] Add compatibility entity/repository/use cases in packages/quran_sessions/lib/src/domain/entities/quran_compatibility_meeting.dart and packages/quran_sessions/lib/src/domain/usecases/quran_compatibility_usecases.dart
- [ ] T044 [US3] Implement allowance, scheduling, and completion services in functions/src/quranSessions/packages/compatibilityMeetingCallables.ts
- [ ] T045 [US3] Map verified profile evidence and indexed filters in apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_teacher_repository.dart
- [ ] T046 [US3] Extend teacher list/profile BLoCs for package filters, trust labels, and compatibility state in packages/quran_sessions/lib/src/presentation/blocs/teacher_list/teacher_list_bloc.dart and packages/quran_sessions/lib/src/presentation/blocs/teacher_profile/teacher_profile_bloc.dart
- [ ] T047 [US3] Build trust metadata and compatibility request/result UI in packages/quran_sessions/lib/src/presentation/screens/teacher_profile_screen.dart
- [ ] T048 [P] [US3] Add allowance/authorization/idempotency tests in functions/test/quranSessions/compatibilityMeetingCallables.test.ts
- [ ] T049 [P] [US3] Add discovery/profile/compatibility widget tests in packages/quran_sessions/test/presentation/teacher_package_discovery_test.dart

**Checkpoint**: A learner can select a verified fit before purchase.

---

## Phase 6: User Story 4 — Measurable Quran Progress (Priority: P1)

**Goal**: Convert attended sessions into a visible learning plan, reports, homework, and summary.

**Independent Test**: Create baseline/goal, complete one session, submit a structured report, and display a safe progress projection and final summary.

- [ ] T050 [P] [US4] Add learning plan/report/summary entities, failures, repositories, and use cases in packages/quran_sessions/lib/src/domain/entities/quran_learning_progress.dart
- [ ] T051 [US4] Implement learning plan, report, completion guard, and summary callables in functions/src/quranSessions/learning/learningProgressCallables.ts
- [ ] T052 [US4] Implement safe learner/guardian report projection separate from private notes in functions/src/quranSessions/learning/learningProgressProjection.ts
- [ ] T053 [US4] Implement Firebase progress repository in apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_learning_progress_repository.dart
- [ ] T054 [US4] Add progress BLoC and teacher report form state in packages/quran_sessions/lib/src/presentation/blocs/learning_progress/learning_progress_bloc.dart
- [ ] T055 [US4] Build learning plan, report, homework, and summary screens in packages/quran_sessions/lib/src/presentation/screens/quran_learning_progress_screen.dart
- [ ] T056 [P] [US4] Add callable authorization/safe-projection/report-compliance tests in functions/test/quranSessions/learningProgressCallables.test.ts
- [ ] T057 [P] [US4] Add BLoC/widget tests for empty/loading/error/RTL/accessibility states in packages/quran_sessions/test/presentation/quran_learning_progress_screen_test.dart

**Checkpoint**: Package value is expressed as progress, not attendance alone.

---

## Phase 7: User Story 5 — Parent Oversight and Child Safety (Priority: P1)

**Goal**: Provide authorized guardian visibility and deny unsafe/cross-child access.

**Independent Test**: Link guardian to child, activate/complete a package session, verify guardian visibility, and deny revoked/unrelated accounts.

- [ ] T058 [P] [US5] Add guardian oversight scopes/use cases to packages/quran_sessions/lib/src/domain/usecases/quran_guardian_package_usecases.dart
- [ ] T059 [US5] Enforce guardian requirement and role-safe package/progress reads in functions/src/quranSessions/packages/packageGuardianAccess.ts
- [ ] T060 [US5] Add guardian notifications with data-minimized payloads in functions/src/quranSessions/packages/packageNotifications.ts
- [ ] T061 [US5] Implement guardian package gateway and DI binding in apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_guardian_package_repository.dart
- [ ] T062 [US5] Build guardian dashboard and safe report view in packages/quran_sessions/lib/src/presentation/screens/quran_guardian_package_screen.dart
- [ ] T063 [P] [US5] Add child threshold, revoked guardian, cross-user, and data-minimization tests in functions/test-integration/quranPackageGuardian.integration.test.ts
- [ ] T064 [P] [US5] Add guardian dashboard authorization/RTL/accessibility widget tests in packages/quran_sessions/test/presentation/quran_guardian_package_screen_test.dart

**Checkpoint**: Child packages cannot activate or leak data without verified guardian controls.

---

## Phase 8: User Story 6 — Admin Operations (Priority: P1)

**Goal**: Configure plans, resolve payment, inspect credit, adjust/extend safely, and operate kill switches.

**Independent Test**: Configure EG plan, confirm an order, perform one bounded reasoned adjustment/extension, audit it, and stop new sales.

- [ ] T065 [P] [US6] Add admin plan/order/package domain entities, gateways, and use cases in apps/tilawa_admin/src/app/core/domain/quran-package/
- [ ] T066 [P] [US6] Implement Firebase callable/read repositories in apps/tilawa_admin/src/app/core/data/repositories/firebase-quran-package.repository.ts
- [ ] T067 [US6] Implement lossless plan update, bounded credit adjustment, and validity extension callables in functions/src/quranSessions/packages/adminPackageCallables.ts
- [ ] T068 [US6] Add package plan management UI in apps/tilawa_admin/src/app/features/quran-sessions/package-plans/
- [ ] T069 [US6] Add pending package order/payment queue and detail actions in apps/tilawa_admin/src/app/features/quran-sessions/package-orders/
- [ ] T070 [US6] Add student package detail, ledger, adjustment, extension, and kill-switch guidance in apps/tilawa_admin/src/app/features/quran-sessions/student-packages/
- [ ] T071 [P] [US6] Add Angular AR/EN strings and routes/navigation in apps/tilawa_admin/l10n/app_ar.arb, apps/tilawa_admin/l10n/app_en.arb, and apps/tilawa_admin/src/app/app.routes.ts
- [ ] T072 [P] [US6] Add callable claim/validation/idempotency/audit tests in functions/test/quranSessions/adminPackageCallables.test.ts
- [ ] T073 [P] [US6] Add facade/gateway/component tests for pending, terminal, duplicate-submit, RTL, and narrow layout in apps/tilawa_admin/src/app/features/quran-sessions/package-orders/package-orders.component.spec.ts

**Checkpoint**: Manual operations are auditable, bounded, and reversible.

---

## Phase 9: User Story 7 — Transparent Renewal (Priority: P2)

**Goal**: Remind and renew manually without deleting unexpired credits or rewriting history.

**Independent Test**: Decline renewal, use current credits until expiry, then activate a distinct next package period.

- [ ] T074 [P] [US7] Add renewal eligibility/reminder use cases in packages/quran_sessions/lib/src/domain/usecases/quran_package_renewal_usecases.dart
- [ ] T075 [US7] Implement reminder scheduling and distinct renewal-order linkage in functions/src/quranSessions/packages/packageRenewalService.ts
- [ ] T076 [US7] Add renewal CTA/history states to packages/quran_sessions/lib/src/presentation/screens/quran_package_detail_screen.dart
- [ ] T077 [P] [US7] Add decline-renewal, expiry, extension, and historical-period tests in functions/test-integration/quranPackageRenewal.integration.test.ts
- [ ] T078 [P] [US7] Add renewal widget/BLoC tests in packages/quran_sessions/test/presentation/quran_package_renewal_test.dart

**Checkpoint**: Renewal is explicit and current entitlement history is immutable.

---

## Phase 10: User Story 8 — Small Cohort Pilot (Priority: P3, Separate GO)

**Goal**: Add fixed 4–6 learner cohorts only after private-package production stability.

**Independent Test**: Enroll capacity, reject/waitlist overflow, run shared session, and record per-learner attendance/credit privately.

- [ ] T079 [P] [US8] Create cohort plan/enrollment/attendance domain model in packages/quran_sessions/lib/src/domain/entities/quran_learning_cohort.dart
- [ ] T080 [P] [US8] Define cohort callable contracts and production gate evidence in specs/042-quran-learning-packages/contracts/cohort-callable-contracts.md
- [ ] T081 [US8] Implement capacity/enrollment/waitlist/minimum-enrollment service in functions/src/quranSessions/cohorts/cohortEnrollmentService.ts
- [ ] T082 [US8] Implement shared session and per-learner attendance/credit integration in functions/src/quranSessions/cohorts/cohortSessionService.ts
- [ ] T083 [US8] Build learner/teacher cohort surfaces in packages/quran_sessions/lib/src/presentation/screens/quran_cohort_screen.dart
- [ ] T084 [US8] Build cohort admin operations in apps/tilawa_admin/src/app/features/quran-sessions/cohorts/
- [ ] T085 [P] [US8] Add capacity/concurrency/privacy/attendance/rules tests in functions/test-integration/quranCohort.integration.test.ts

**Checkpoint**: Cohorts remain disabled until separate legal, delivery, QA, and production GO.

---

## Phase 11: User Story 9 — Global and Institutional Expansion (Priority: P4, Separate GO)

**Goal**: Prepare market-scoped localization/payment and isolated institutional programs.

**Independent Test**: Enable one staging market/institution and prove audience, currency, teacher, payment, data isolation, and disabled-market denial.

- [ ] T086 [P] [US9] Define market expansion readiness matrix in specs/042-quran-learning-packages/global-expansion.md
- [ ] T087 [P] [US9] Define institution tenancy/contracts/privacy model in specs/042-quran-learning-packages/contracts/institution-program-contracts.md
- [ ] T088 [US9] Extend package catalog resolution by market/language/payment capability in functions/src/quranSessions/packages/packageCatalogResolver.ts
- [ ] T089 [US9] Implement institution-scoped authorization and projections in functions/src/quranSessions/institutions/institutionProgramService.ts
- [ ] T090 [P] [US9] Add market isolation, tenant isolation, currency, localization, and disabled-gate tests in functions/test-integration/quranPackageExpansion.integration.test.ts

**Checkpoint**: Expansion code remains non-production until market/institution gates pass.

---

## Phase 12: Release, Performance, Security, and Cross-Cutting Validation

- [ ] T091 [P] Add mobile AR/EN package strings and regenerate localization in packages/quran_sessions/l10n/
- [ ] T092 [P] Add structured package/order/credit/progress metrics without sensitive content in functions/src/quranSessions/packages/packageMetrics.ts
- [ ] T093 [P] Profile package discovery/detail/progress rebuilds and record frame/read-write evidence in specs/042-quran-learning-packages/quickstart.md
- [ ] T094 Run `melos run fix:format`, `melos run analyze`, `melos run bloc:lint`, and `melos run test` and record exact outcomes in specs/042-quran-learning-packages/quickstart.md
- [ ] T095 Run functions build/unit/integration/rules suites and admin test/build and record exact outcomes in specs/042-quran-learning-packages/quickstart.md
- [ ] T096 Execute manual AR/EN, RTL/LTR, dark/light, 200% text, accessibility, offline/error/retry, and device QA from specs/042-quran-learning-packages/quickstart.md
- [ ] T097 Execute staging purchase→payment→activation→booking→report→guardian→renewal flow and reconciliation in specs/042-quran-learning-packages/quickstart.md
- [ ] T098 Execute App Check evidence, unauthorized traffic checks, sales/booking kill switch, and <15-minute rollback drill in specs/042-quran-learning-packages/quickstart.md
- [ ] T099 Obtain legal/privacy/ops/finance/product sign-off and run closed Egypt pilot of 100 paid sessions using docs/quran_sessions/package_operations.md
- [ ] T100 Run a strict pre-release diff, code, test, UI/UX, and documentation review and record zero open P0 financial, child-safety, or credit-integrity defects in specs/042-quran-learning-packages/quickstart.md

## Dependencies & Execution Order

- Phase 1 protects existing behavior.
- Phase 2 blocks all user stories.
- US1 and US6 establish sale/operations; US2 establishes usable entitlement.
- US3 can begin after Phase 2 but must integrate before public sale.
- US4 and US5 depend on active package/session identifiers and can proceed in parallel after US1/US2 contracts stabilize.
- US7 depends on US1 and package terminal/expiry behavior.
- US8 and US9 are separate post-MVP gates and must not block Egypt private-package release.
- Phase 12 follows all stories selected for a release.

## Parallel Opportunities

- Foundational Dart types, TypeScript types, rules tests, and mapper tests can proceed in parallel.
- After Phase 2, US1 callable/domain work, US3 discovery work, and US6 admin domain scaffolding can proceed in parallel.
- After US1/US2 identifiers stabilize, US4 learning progress and US5 guardian oversight can proceed in parallel.
- Widget tests, callable unit tests, integration tests, and localized copy can run in parallel when their contracts are stable.

## Implementation Strategy

### Recommended Egypt MVP

1. Phase 1 baseline.
2. Phase 2 atomic entitlement foundation.
3. US1 sale + US6 minimum admin payment operations.
4. US2 credit-aware booking.
5. US3 compatibility/trust, US4 progress, and US5 guardian safety.
6. US7 transparent renewal.
7. Phase 12 release gates and closed pilot.
8. Stop; evaluate metrics before US8 cohorts or US9 expansion.

### Format Validation

All implementation checklist items use `- [ ] T### [P?] [US?] Description with path`; setup/foundation/release tasks intentionally omit story labels, and every user-story task includes its story label.
