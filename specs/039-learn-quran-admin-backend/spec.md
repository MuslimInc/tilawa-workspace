# Feature Specification: Learn Quran Admin and Backend Completion

**Feature Branch**: `039-learn-quran-admin-backend`  
**Created**: 2026-07-10  
**Status**: Draft  
**Input**: User description: "Break down the remaining admin panel and backend work for the Learn Quran Quran Sessions feature into a complete Spec Kit delivery plan."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Safely manage Learn Quran rollout policy (Priority: P1)

An administrator updates global and market-level Learn Quran policy without
silently resetting an unrelated policy value or presenting a control whose
value cannot take effect. The administrator can see which controls are
editable and receives a clear success or failure outcome after saving.

**Why this priority**: Platform and market policy determine whether students
can discover, book, and join Learn Quran sessions. A misleading or lossy admin
write can affect every active market.

**Independent Test**: An administrator loads a configuration containing an
age threshold and all supported market settings, changes one supported setting,
and verifies that all untouched settings remain unchanged after reload.

**Acceptance Scenarios**:

1. **Given** a global policy with a non-default age threshold, **When** an
   administrator changes an unrelated rollout flag and saves, **Then** the
   age threshold remains unchanged.
2. **Given** video-only delivery is the only supported session mode, **When**
   an administrator opens market configuration, **Then** it is presented as a
   fixed policy rather than an editable value that cannot be applied.
3. **Given** a market setting is invalid or cannot be saved, **When** the
   administrator submits the form, **Then** the existing saved policy remains
   intact and the administrator receives an actionable error.

---

### User Story 2 - Triage and close safety reports (Priority: P1)

An administrator opens a Learn Quran safety report, records that it is under
review or closes it with a reason, and can immediately see the resulting
status and resolution record.

**Why this priority**: The current report queue exposes sensitive reports but
does not let operators complete the remediation workflow already authorized by
the service.

**Independent Test**: An administrator moves an open report to under review,
then resolves or dismisses it with a reason and verifies the updated status,
resolver, timestamp, and audit history.

**Acceptance Scenarios**:

1. **Given** an open report, **When** an administrator marks it under review,
   **Then** the report remains open to follow-up with its status updated.
2. **Given** an open or in-review report, **When** an administrator resolves
   or dismisses it with a reason, **Then** the resolution is recorded and the
   report no longer appears in the unresolved work queue.
3. **Given** a terminal resolution is submitted without a reason, **When** the
   administrator confirms the action, **Then** no status change is made and a
   validation message explains what is required.

---

### User Story 3 - Resolve session disputes from the dispute queue (Priority: P1)

An administrator can choose an allowed resolution for an open dispute, provide
the required rationale, and see the final dispute and related session outcome.

**Why this priority**: Dispute resolution can affect compensation or refunds;
leaving the admin detail read-only forces operators to use indirect workflows
and slows safety-critical handling.

**Independent Test**: An administrator resolves a disputed booking using each
permitted outcome in a test environment and verifies the dispute status,
session outcome, and any recorded financial follow-up exactly once.

**Acceptance Scenarios**:

1. **Given** an open dispute, **When** an administrator selects a valid
   resolution and supplies a reason, **Then** the dispute is closed with the
   selected outcome and an auditable resolver record.
2. **Given** a dispute that has already been resolved, **When** an
   administrator revisits its detail, **Then** resolution controls are not
   offered and the recorded outcome remains visible.
3. **Given** a duplicate submit caused by a slow connection, **When** the
   same resolution is retried, **Then** the outcome is not duplicated.

---

### User Story 4 - Release protected backend operations deliberately (Priority: P2)

An operations owner has one evidence-based procedure for enabling request
attestation in staging, observing failures, and promoting the protection to
production only after the required Learn Quran flows remain healthy.

**Why this priority**: Learn Quran callable protection is currently an
intentional deployment-time choice. A safe rollout needs observable criteria,
rollback instructions, and explicit ownership rather than an undocumented
environment change.

**Independent Test**: In staging, the owner follows the procedure with an
attested client and a non-attested request, records the results for the
critical flows, and can restore the prior state without changing data.

**Acceptance Scenarios**:

1. **Given** a staging environment, **When** request attestation is enabled
   for Learn Quran operations, **Then** critical authenticated flows continue
   to work and rejected requests are observable without exposing user data.
2. **Given** an unexpected rejection rate during the staging observation
   period, **When** the owner follows the rollback procedure, **Then** the
   prior protection state is restored without changing booking or session data.
3. **Given** the staging evidence is incomplete, **When** a production
   promotion is proposed, **Then** the rollout remains blocked.

### Edge Cases

- A policy document may predate a newly surfaced field; loading and saving must
  preserve its safe existing value instead of manufacturing an unsafe default.
- A browser retry or double-click must not create duplicate report/dispute
  outcomes or duplicate compensation/refund records.
- A report or dispute can reference a booking whose user profile is no longer
  available; the operator must still be able to review and resolve it.
- The operator can lose connectivity while submitting a resolution; the screen
  must keep the entered rationale and make the resulting status unambiguous
  after retry/reload.
- Arabic and English operators must receive equivalent action labels, validation
  messages, and status information; controls must remain usable at increased
  text scale and narrow desktop widths.
- The design must not add unbounded admin reads or load all reports/disputes
  merely to perform one detail action.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST preserve every persisted global policy value that
  an administrator does not intentionally change.
- **FR-002**: The system MUST show only supported editable market policy values;
  fixed delivery constraints MUST be communicated without exposing a no-op
  control.
- **FR-003**: The system MUST validate policy values before saving and keep the
  previously persisted policy unchanged when validation fails.
- **FR-004**: Authorized administrators MUST be able to move a safety report to
  under review, resolve it, or dismiss it using the allowed outcomes.
- **FR-005**: Resolving or dismissing a safety report MUST require a non-empty
  rationale and record the acting administrator and resolution time.
- **FR-006**: Authorized administrators MUST be able to resolve an open dispute
  using only the allowed outcomes and a non-empty rationale.
- **FR-007**: The system MUST make terminal report and dispute outcomes
  read-only and must not duplicate their financial or lifecycle effects when an
  action is retried.
- **FR-008**: All privileged policy, report, and dispute updates MUST continue
  to be server-authorized, server-validated, and audit-recorded; the admin
  interface MUST not write operational data directly.
- **FR-009**: Lists and detail views for reports and disputes MUST keep their
  existing bounded pagination behavior; resolution MUST refresh only the
  affected detail/list state.
- **FR-010**: The release procedure MUST define staging evidence, promotion
  criteria, observability signals, a rollback decision, and an accountable
  owner for request-attestation enforcement.
- **FR-011**: The administrative workflow MUST provide localized error,
  loading, empty, confirmation, and success states in Arabic and English.
- **FR-012**: The feature MUST document and test access-control boundaries so a
  non-administrator cannot perform a privileged action.

### Key Entities *(include if feature involves data)*

- **Global policy**: The platform-wide Learn Quran rollout and scheduling policy,
  including the child age threshold and market availability policy.
- **Market policy**: The country-level Learn Quran availability, booking,
  pricing, payment, and scheduling policy plus scoped city overrides.
- **Safety report**: An operator work item containing a report category,
  severity, reporter context, status, and terminal resolution metadata.
- **Session dispute**: A booking-linked disagreement with an open/terminal
  status, reason, resolver record, and possible compensation or refund outcome.
- **Administrative action record**: The auditable record connecting a privileged
  change to an actor, target, reason, time, and resulting state.
- **Attestation rollout evidence**: A dated staging result set for protected
  Learn Quran operations, including pass/fail observations and rollback status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a configuration round-trip test, 100% of unchanged persisted
  policy values retain their original values after an administrator saves an
  unrelated supported edit.
- **SC-002**: An authorized administrator can complete report triage and dispute
  resolution in no more than three operator actions after opening the detail.
- **SC-003**: 100% of terminal report/dispute attempts without a required reason
  are rejected before an outcome is recorded.
- **SC-004**: Retry tests produce exactly one terminal outcome and at most one
  associated compensation or refund record for each resolution request.
- **SC-005**: Automated authorization tests reject 100% of non-administrator
  attempts to change policy or resolve reports/disputes.
- **SC-006**: Staging attestation evidence covers all named critical Learn Quran
  calls before production enforcement is approved, with a documented rollback
  result.

## Assumptions

- The existing admin authentication and administrator claim remain the source
  of operator authorization.
- Existing server-side report and dispute resolution behavior remains the
  authoritative workflow; this feature exposes it safely rather than replacing
  it.
- Video-only delivery remains the approved Learn Quran scope for this release.
- Payment-provider and wallet expansion, device/session-management changes,
  mobile report/dispute submission changes, and new scheduling policy are out
  of scope.
- Production deployment, policy seeding, and the final decision to enforce
  request attestation remain operations-owned and require documented evidence.
