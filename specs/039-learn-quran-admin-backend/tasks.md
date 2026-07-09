# Tasks: Learn Quran Admin and Backend Completion

**Input**: Design documents from specs/039-learn-quran-admin-backend/
**Prerequisites**: plan.md, spec.md, research.md, data-model.md,
contracts/admin-callable-contracts.md, and quickstart.md.

**Tests**: Tests are mandatory for privileged policy writes, report/dispute
resolution, mappers, gateway/use-case validation, authorization, and the
affected admin presentation states.

## Phase 1: Setup and Baseline

**Purpose**: Establish current behavior and protect the verified boundaries
before adding UI actions.

- [X] T001 [P] Add baseline round-trip regression cases in apps/tilawa_admin/src/app/features/quran-sessions/global-settings/global-settings.component.spec.ts.
- [X] T002 [P] Verify the market validator contract and add child-age validation coverage in functions/test/quranSessions/updatePlatformConfig.test.ts and functions/test/quranSessions/updateMarketPricingConfig.test.ts.
- [X] T003 [P] Add report/dispute terminal-resolution coverage gaps to functions/test-integration/sessionReports.integration.test.ts and functions/test-integration/resolveSessionDispute.integration.test.ts.
- [X] T004 Record initial Admin/Functions test outcomes in specs/039-learn-quran-admin-backend/quickstart.md.

**Checkpoint**: Current behavior, including the policy-round-trip risk and
server-owned terminal effects, is represented by executable tests.

## Phase 2: Shared Moderation Boundary

**Purpose**: Give admin report and dispute screens one typed, server-authorized
write boundary; complete this before either resolution screen.

- [X] T005 Extend report-resolution types and detail fields in apps/tilawa_admin/src/app/core/domain/entities/session-report-summary.entity.ts.
- [X] T006 [P] Extend the moderation contract with report resolution in apps/tilawa_admin/src/app/core/domain/repositories/session-moderation.gateway.ts.
- [X] T007 [P] Implement the report-resolution callable adapter and normalized callable errors in apps/tilawa_admin/src/app/core/data/repositories/firebase-session-moderation.gateway.ts.
- [X] T008 Add report and dispute resolution use cases with trim/required-input validation in apps/tilawa_admin/src/app/core/domain/usecases/session-moderation.usecases.ts.
- [X] T009 [P] Add use-case/gateway success, validation, and callable-error tests in apps/tilawa_admin/src/app/core/domain/usecases/session-moderation.usecases.spec.ts.
- [X] T010 [P] Add report resolution mapper/detail regression coverage in apps/tilawa_admin/src/app/core/data/mappers/session-report.mapper.spec.ts.
- [X] T011 Verify the existing SESSION_MODERATION_GATEWAY registration remains the only runtime write binding in apps/tilawa_admin/src/app/app.config.ts.

**Checkpoint**: Admin mutations traverse typed use cases and a Firebase callable
adapter; no feature component writes Firestore directly.

## Phase 3: User Story 1 — Safe Rollout Configuration (Priority: P1)

**Goal**: Every displayed editable global/market policy value has a lossless,
validated server contract, and unsupported market session mode is no longer a
misleading editable control.

**Independent Test**: Change an unrelated global setting with a non-default age
threshold, reload it, and verify that threshold is retained; inspect market
policy and verify only supported editable values are submitted.

- [X] T012 [P] [US1] Add childAgeThreshold to the global configuration model and read normalization in apps/tilawa_admin/src/app/features/quran-sessions/global-settings/global-settings.facade.ts.
- [X] T013 [US1] Add a validated child-age form control and lossless save payload in apps/tilawa_admin/src/app/features/quran-sessions/global-settings/global-settings.component.ts.
- [X] T014 [US1] Render the child-age control with loading/error-safe behavior in apps/tilawa_admin/src/app/features/quran-sessions/global-settings/global-settings.component.html.
- [X] T015 [P] [US1] Remove the editable market sessionMode form control and payload mapping in apps/tilawa_admin/src/app/features/quran-sessions/market-pricing/market-pricing.component.ts.
- [X] T016 [US1] Replace the market delivery-mode selector with fixed video-only guidance in apps/tilawa_admin/src/app/features/quran-sessions/market-pricing/market-pricing.component.html.
- [X] T017 [P] [US1] Add Arabic and English strings for age-policy validation and fixed video-only guidance in apps/tilawa_admin/l10n/app_ar.arb and apps/tilawa_admin/l10n/app_en.arb.
- [X] T018 [P] [US1] Test global configuration round-trip, invalid age handling, and unchanged-field preservation in apps/tilawa_admin/src/app/features/quran-sessions/global-settings/global-settings.component.spec.ts.
- [X] T019 [P] [US1] Test market payload omission of sessionMode and fixed-mode rendering in apps/tilawa_admin/src/app/features/quran-sessions/market-pricing/market-pricing.component.spec.ts.
- [X] T020 [US1] Add backend regression coverage that valid global age values are accepted and invalid values fail in functions/test/quranSessions/updatePlatformConfig.test.ts.
- [X] T021 [US1] Verify videoOnly remains the only accepted platform session mode in functions/test/quranSessions/updatePlatformConfig.test.ts.

**Checkpoint**: A save cannot reset a known age threshold and no visible market
control claims to change a field the backend does not accept.

## Phase 4: User Story 2 — Report Triage and Closure (Priority: P1)

**Goal**: Administrators can set a report under review or close it with the
required rationale and immediately see authoritative state.

**Independent Test**: Resolve an open report from its detail, reload it, and
verify the terminal state, reason, resolver, time, and audit record; verify a
non-admin and missing-reason attempt fail.

- [X] T022 [US2] Extend report detail view-model mapping for resolution reason, resolver, and resolved time in apps/tilawa_admin/src/app/core/application/facades/session-reports.facade.ts.
- [X] T023 [US2] Add pending-action, action-error, and refresh behavior to the report facade in apps/tilawa_admin/src/app/core/application/facades/session-reports.facade.ts.
- [X] T024 [US2] Add report-resolution controls, terminal read-only state, confirmation/reason capture, and accessible status feedback in apps/tilawa_admin/src/app/features/quran-sessions/session-report-detail/session-report-detail.component.ts.
- [X] T025 [US2] Render the report action panel, terminal metadata, and localized loading/error states in apps/tilawa_admin/src/app/features/quran-sessions/session-report-detail/session-report-detail.component.html.
- [X] T026 [P] [US2] Add Arabic and English report action, confirmation, validation, and terminal metadata strings in apps/tilawa_admin/l10n/app_ar.arb and apps/tilawa_admin/l10n/app_en.arb.
- [X] T027 [P] [US2] Test facade transitions, failure retention, refresh, and terminal-state behavior in apps/tilawa_admin/src/app/core/application/facades/session-reports.facade.spec.ts.
- [X] T028 [P] [US2] Test report detail rendering, required reason, duplicate-submit prevention, RTL, and terminal read-only behavior in apps/tilawa_admin/src/app/features/quran-sessions/session-report-detail/session-report-detail.component.spec.ts.
- [X] T029 [US2] Verify admin/non-admin resolution, mandatory terminal reason, idempotency, and audit output in functions/test-integration/sessionReports.integration.test.ts.

**Checkpoint**: Report triage is fully operable from the queue without a direct
data write or an ambiguous terminal result.

## Phase 5: User Story 3 — Dispute Resolution (Priority: P1)

**Goal**: Administrators resolve open disputes from their detail with allowed
outcomes, required rationale, and server-owned lifecycle/financial effects.

**Independent Test**: Resolve each allowed outcome in isolated data and verify
the dispute/booking terminal state and at most one associated financial record.

- [X] T030 [US3] Inject the existing resolve-dispute use case and add pending-action, action-error, and refresh behavior in apps/tilawa_admin/src/app/core/application/facades/session-disputes.facade.ts.
- [X] T031 [US3] Add dispute-resolution selection, required-reason handling, confirmation, and terminal-state guards in apps/tilawa_admin/src/app/features/quran-sessions/session-dispute-detail/session-dispute-detail.component.ts.
- [X] T032 [US3] Render allowed outcome controls, explanatory effect copy, terminal metadata, and accessible errors in apps/tilawa_admin/src/app/features/quran-sessions/session-dispute-detail/session-dispute-detail.component.html.
- [X] T033 [P] [US3] Add Arabic and English dispute outcome, confirmation, validation, and effect-warning strings in apps/tilawa_admin/l10n/app_ar.arb and apps/tilawa_admin/l10n/app_en.arb.
- [X] T034 [P] [US3] Test facade success, server failure, pending state, and terminal refresh in apps/tilawa_admin/src/app/core/application/facades/session-disputes.facade.spec.ts.
- [X] T035 [P] [US3] Test dispute detail required rationale, duplicate-submit prevention, RTL, and resolved read-only behavior in apps/tilawa_admin/src/app/features/quran-sessions/session-dispute-detail/session-dispute-detail.component.spec.ts.
- [X] T036 [US3] Verify every permitted dispute outcome, authorization rejection, lifecycle guard, and idempotent financial effect in functions/test-integration/resolveSessionDispute.integration.test.ts.

**Checkpoint**: An operator can resolve a dispute safely from its own work item;
the server remains sole owner of compensation/refund and lifecycle changes.

## Phase 6: User Story 4 — App Check Release Gate (Priority: P2)

**Goal**: Request-attestation enforcement has reproducible staging evidence,
clear promotion criteria, and a no-data-mutation rollback.

**Independent Test**: In staging, validate named critical flows from attested
clients, observe rejected non-attested traffic, and restore the prior setting
when the gate fails.

- [X] T037 [P] [US4] Add the Learn Quran App Check evidence table, owner, success criteria, and rollback decision to docs/quran-sessions/production-readiness-checklist.md.
- [X] T038 [P] [US4] Add the operator runbook for staged enforcement, observable rejection handling, and rollback to docs/quran_sessions_admin_ops_checklist.md.
- [X] T039 [US4] Align callable-option documentation and unit expectations for the deployment-controlled default in functions/src/quranSessions/sessionCallableOptions.ts and functions/test/quranSessions/sessionCallableOptions.test.ts.
- [ ] T040 [US4] Execute the staging evidence procedure in specs/039-learn-quran-admin-backend/quickstart.md and attach dated results before any production enforcement request. *(Gate prepared 2026-07-10; execution blocked on ops: staging deploy + soak calendar time. See quickstart "Staging evidence status".)*

**Checkpoint**: Production App Check promotion has a named owner, passing staged
evidence, and a reversible path; it is not enabled by an undocumented toggle.

## Phase 7: Polish and Cross-Cutting Validation

**Purpose**: Verify design-system, data-boundary, documentation, and release
quality across all stories.

- [ ] T041 [P] Update admin configuration ownership and supported-field documentation in docs/quran_sessions_admin_configuration.md.
- [ ] T042 [P] Verify no admin Quran Sessions component introduces direct Firestore writes in apps/tilawa_admin/src/app/features/quran-sessions/.
- [ ] T043 [P] Run the admin tests and production build from apps/tilawa_admin/package.json.
- [ ] T044 [P] Run function build, unit tests, integration tests, and rules tests from functions/package.json.
- [ ] T045 [P] Perform manual Arabic/English, RTL, narrow-width, loading, failure, retry, and terminal-state QA using specs/039-learn-quran-admin-backend/quickstart.md.
- [ ] T046 Record performance/read-write impact, test evidence, known risks, and rollback outcome in specs/039-learn-quran-admin-backend/quickstart.md.

## Dependencies and Execution Order

- Phase 1 protects baseline behavior.
- Phase 2 is the shared privileged-write boundary and blocks US2/US3.
- US1 can proceed after Phase 1 and in parallel with Phase 2.
- US2 and US3 can proceed in parallel after Phase 2.
- US4 is operations/documentation work and can proceed after Phase 1; production
  promotion remains blocked until US1–US3 critical-flow tests pass.
- Phase 7 follows every desired story.

## Parallel Opportunities

- T001–T003, T005–T007, T012/T015/T017, T018/T019, T026–T028, T033–T035,
  T037–T038, and T041–T045 may run in parallel when their prerequisite phase is
  complete.
- US1 can be delivered independently before moderation UI work.
- US2 and US3 share the Phase 2 boundary but otherwise touch separate facades
  and detail components.

## Implementation Strategy

1. Establish the regression baseline and typed moderation boundary.
2. Deliver US1 and validate configuration round-trip before exposing further
   operational controls.
3. Deliver report triage, then dispute resolution, each with independent
   component/integration tests.
4. Complete the App Check evidence gate and documentation.
5. Run the full validation suite, manual QA, and rollback review before asking
   for deployment approval.
