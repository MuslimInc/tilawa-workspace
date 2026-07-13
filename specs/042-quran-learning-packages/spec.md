# Feature Specification: Quran Learning Packages

**Feature Branch**: `042-quran-learning-packages`  
**Created**: 2026-07-11  
**Status**: Draft  
**Input**: Egypt-first Quran learning packages inspired by Qutor's strongest tutor-trust, trial, classroom, parent-oversight, and progress ideas. MVP: eight prepaid private sessions with one verified teacher. Groups and global expansion are phased follow-ups.

## Product Vision

Tilawa will sell a clear learning outcome, not eight unrelated bookings. A student or parent chooses a trusted teacher, completes a short compatibility meeting, prepays one package, books eight private lessons, sees an exact credit balance, and follows measurable Quran progress. Egypt launches first with EGP, manual off-app payment, manual renewal, curated teachers, and explicit cancellation rules.

## Scope

### Egypt MVP

- Egypt-only, EGP-priced package: one learner, one verified teacher, eight private video sessions.
- Short pre-purchase compatibility meeting.
- Manual off-app payment with admin confirmation/rejection; no recurring charge.
- Atomic credit reservation, consumption, restoration, expiry, and audit.
- Learning plan, structured lesson reports, homework, and end-of-package summary.
- Guardian oversight for child learners.
- Admin configuration, support adjustments, metrics, staged rollout, and rollback.

### Later Phases

- Fixed small cohorts of four to six comparable learners.
- Additional markets, currencies, payment providers, and tutor languages.
- Institution/white-label programs for schools and mosques.
- Synchronized Quran classroom and optional lesson archive.

### Explicitly Out of Scope for MVP

- Auto-renewal, proration, dunning, card-on-file billing, mixed wallet/card checkout.
- Automated teacher payouts, tax invoicing, unlimited plans, or pay-by-the-minute.
- Group sessions, child video recording, public student listings, or non-Egypt launch.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Purchase and Activate a Package (Priority: P1)

As an eligible Egypt learner or parent, I can order an eight-session package for one verified teacher, follow manual payment instructions, and receive an active entitlement after admin confirmation.

**Why this priority**: This creates the sellable product.

**Independent Test**: Submit an Egypt order, confirm it as admin, and verify exactly one active package with eight available credits.

**Acceptance Scenarios**:

1. **Given** an eligible learner and verified Egypt teacher, **When** the learner reviews the package, **Then** total EGP price, count, duration, validity, renewal, cancellation, compensation, and teacher are shown before commitment.
2. **Given** a submitted order, **When** payment awaits review, **Then** no credit is bookable and the unique reference, instructions, and pending state are visible.
3. **Given** verified payment, **When** an authorized admin confirms it, **Then** exactly one package with eight credits activates and learner, guardian, and teacher are notified.
4. **Given** invalid payment, **When** admin rejects it with a reason, **Then** no entitlement activates and the learner sees an actionable outcome.
5. **Given** a learner outside enabled Egypt coverage, **When** purchase is attempted, **Then** it is blocked without creating an order.
6. **Given** a retried confirmation, **When** it is processed again, **Then** no duplicate package or financial effect occurs.

---

### User Story 2 - Book and Account for Eight Sessions (Priority: P1)

As a package learner, I can book the package teacher and always understand my balance while cancellations and failures apply predictable credit rules.

**Why this priority**: Credit integrity is the core financial promise.

**Independent Test**: Activate eight credits, book once, verify seven remain, cancel before cutoff, and verify the balance returns to eight exactly once.

**Acceptance Scenarios**:

1. **Given** an active unexpired package, **When** an available teacher slot is booked, **Then** one credit is reserved or consumed atomically.
2. **Given** no credit, expiry, wrong teacher, or ineligible state, **When** booking is attempted, **Then** it is blocked without a credit change.
3. **Given** teacher rejection/cancellation, teacher no-show, approval expiry, slot conflict, or platform failure, **When** booking cannot fairly proceed, **Then** credit is restored exactly once.
4. **Given** learner cancellation at least 12 hours before start, **When** cancellation completes, **Then** credit is restored exactly once.
5. **Given** late learner cancellation or learner no-show, **When** policy applies, **Then** the credit stays consumed and the reason is visible.
6. **Given** concurrent final-credit attempts, **When** both submit, **Then** at most one succeeds.

---

### User Story 3 - Choose a Compatible Verified Teacher (Priority: P1)

As a learner or parent, I can compare trusted teachers and complete a short compatibility meeting before paying.

**Why this priority**: Teacher fit is the largest purchase risk.

**Independent Test**: Filter teachers, request one compatibility meeting, record a recommendation, and continue to package purchase without consuming paid credit.

**Acceptance Scenarios**:

1. **Given** discovery is enabled, **When** filters are applied, **Then** teachers can be narrowed by goal, child capability, gender, language, qualification/ijazah, availability, price, and verified feedback.
2. **Given** a profile, **When** viewed, **Then** verified evidence is distinct from self-declared claims and experience, specialties, languages, price, availability, completed sessions, and reviews are clear.
3. **Given** unused allowance for a learner-teacher pair, **When** a short meeting is requested, **Then** it uses no paid package credit.
4. **Given** the meeting completes, **When** the teacher records baseline, goal, and cadence, **Then** the learner can accept the teacher and purchase.
5. **Given** trial abuse limits are exceeded, **When** another request is made, **Then** it is blocked and reviewable by support.

---

### User Story 4 - Follow Measurable Quran Progress (Priority: P1)

As a learner, parent, or teacher, I can see the learning goal, completed material, mistakes, homework, and end result.

**Why this priority**: Outcome tracking differentiates Tilawa from generic tutoring.

**Independent Test**: Create a plan, complete a session, submit a report, and verify learner/guardian progress and homework update.

**Acceptance Scenarios**:

1. **Given** an active package, **When** a plan is agreed, **Then** it records goal, baseline, target material, cadence, and review strategy.
2. **Given** a completed session, **When** the teacher closes it, **Then** covered material, assessment, recurring mistakes, homework, attendance, and a safe note are recorded.
3. **Given** a report, **When** learner or guardian views progress, **Then** completed work, next work, homework, and balance are visible without internal moderation notes.
4. **Given** the eighth session or expiry, **When** the package closes, **Then** a baseline-to-outcome summary and next recommendation are produced.

---

### User Story 5 - Parent Oversight and Child Safety (Priority: P1)

As a verified guardian, I can oversee my child's package, schedule, attendance, progress, and safe teacher feedback without exposing private contact details.

**Why this priority**: Child safety is a launch gate.

**Independent Test**: Link a guardian, activate a child package, complete a session, and verify authorized oversight and unrelated-account denial.

**Acceptance Scenarios**:

1. **Given** a child under the configured threshold, **When** activation is attempted, **Then** a verified guardian is required.
2. **Given** a linked guardian, **When** schedule or attendance changes, **Then** the guardian is notified and sees authoritative state.
3. **Given** a completed session, **When** the guardian opens it, **Then** progress, attendance, homework, and safe feedback are visible.
4. **Given** an unrelated or unverified user, **When** child data is requested, **Then** access is denied and auditable.

---

### User Story 6 - Operate and Support Packages (Priority: P1)

As an authorized operator, I can configure the Egypt package, review payments, inspect credit history, apply bounded corrections, extend validity, and stop sales safely.

**Why this priority**: Manual payment requires controlled, reversible operations.

**Independent Test**: Configure a plan, confirm an order, apply one reasoned credit adjustment, inspect audit, and disable new sales without damaging active history.

**Acceptance Scenarios**:

1. **Given** an authorized admin, **When** configuration saves, **Then** price, count, duration, validity, cutoff, teacher eligibility, and sale state round-trip losslessly.
2. **Given** a pending payment, **When** it is confirmed/rejected, **Then** the action is authorized, reasoned where required, idempotent, audited, and authoritatively refreshed.
3. **Given** a balance exception, **When** a privileged adjustment occurs, **Then** amount is bounded and actor, reason, time, and immutable activity are recorded.
4. **Given** a launch incident, **When** sales or booking is disabled, **Then** new activity stops while history remains intact.

---

### User Story 7 - Renew Transparently (Priority: P2)

As a learner or parent, I can renew manually without losing unexpired sessions because I declined renewal.

**Why this priority**: Transparent renewal avoids competitor complaints about trapped hours and cancellation.

**Independent Test**: Decline renewal, verify current credits remain until disclosed expiry, then purchase a separate new period.

**Acceptance Scenarios**:

1. **Given** a nearing expiry/completion, **When** reminder threshold is reached, **Then** remaining credits, exact expiry, and manual renewal are shown.
2. **Given** renewal is declined, **When** the package remains valid, **Then** no unexpired credit disappears.
3. **Given** renewal payment is confirmed, **When** activation occurs, **Then** a distinct period is created and history remains unchanged.

---

### User Story 8 - Pilot Small Cohorts (Priority: P3)

As a learner, parent, teacher, or operator, I can participate in a fixed cohort after private packages are stable.

**Why this priority**: Groups improve affordability but require distinct capacity, attendance, and privacy controls.

**Independent Test**: Create four seats, enroll four paid learners, reject a fifth, run a shared session, and record per-learner attendance and credit effects.

**Acceptance Scenarios**:

1. **Given** an operator, **When** a cohort is created, **Then** teacher, level, age band, gender policy, capacity 4–6, schedule, curriculum, price, start, and minimum enrollment are defined.
2. **Given** available capacity, **When** payment is confirmed, **Then** one private seat is reserved.
3. **Given** a full cohort, **When** enrollment is attempted, **Then** it is rejected or waitlisted without oversubscription.
4. **Given** a shared session, **When** completed, **Then** attendance, consumption, homework, and progress are recorded per learner.

---

### User Story 9 - Expand by Market and Institution (Priority: P4)

As an operator, I can introduce the proven model to another market or approved institution without weakening currency, language, safety, payment, or release controls.

**Why this priority**: Global growth must follow proven operations.

**Independent Test**: Configure a non-Egypt staging market/institution and verify only its intended audience can discover and buy localized offerings.

**Acceptance Scenarios**:

1. **Given** a disabled market, **When** catalog and pricing are prepared, **Then** purchase remains impossible until explicit launch approval.
2. **Given** an enabled market, **When** discovery occurs, **Then** only eligible teachers, language, currency, payment, policy, and products appear.
3. **Given** an institution, **When** a program is configured, **Then** its admins, learners, teachers, attendance, progress, and reporting remain isolated.

### Edge Cases

- Late payment confirmation after an order/teacher offer expires.
- Teacher suspension, departure, or long-term unavailability during active packages.
- Concurrent admin payment decisions or concurrent final-credit bookings.
- Booking succeeds but session creation/notification fails.
- Reschedule moves beyond package expiry.
- Learner changes country/city or guardian link is revoked.
- Payment instructions change while an order is pending.
- Support adjustment would make credit accounting invalid.
- Connectivity failure prevents a fair lesson.
- Future cohort misses minimum enrollment or loses a learner mid-cycle.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The platform MUST offer an Egypt-only prepaid package of exactly eight private sessions with one verified teacher.
- **FR-002**: Before order submission, the platform MUST disclose EGP total, count, duration, validity, teacher, renewal, cancellation/no-show, and compensation terms.
- **FR-003**: MVP renewal MUST be manual and MUST NOT automatically charge or activate a new period.
- **FR-004**: Non-Egypt learners and non-Egypt-enabled teachers MUST be blocked from MVP purchase/fulfillment.
- **FR-005**: An order MUST snapshot displayed terms and unique payment reference.
- **FR-006**: No package credit MUST exist before authorized manual-payment confirmation.
- **FR-007**: Payment confirmation/rejection/activation MUST be idempotent and audited.
- **FR-008**: Activation MUST create eight available credits and immutable reserve/consume/restore/expire/adjust movements.
- **FR-009**: Package booking MUST authoritatively validate owner, teacher, market, state, expiry, credit, slot, and participant eligibility.
- **FR-010**: Concurrent operations MUST never overspend credits or oversell a slot.
- **FR-011**: Cancellation/failure/no-show credit rules MUST be versioned and applied at most once.
- **FR-012**: MVP default MUST restore credit for learner cancellation at least 12 hours before start and consume it for later cancellation/no-show, unless an authorized exception applies.
- **FR-013**: Teacher cancellation/no-show or platform failure MUST restore credit and permit policy-based validity extension.
- **FR-014**: Package/order/activity history MUST remain readable after terminal states and renewal.
- **FR-015**: Discovery MUST filter by goal, child capability, gender, language, qualification/ijazah, price, availability, and verified feedback.
- **FR-016**: Teacher profiles MUST distinguish platform-verified evidence from self-declared claims.
- **FR-017**: One configurable, abuse-limited compatibility meeting per learner-teacher pair MUST consume no paid credit.
- **FR-018**: Compatibility completion MUST support baseline, goal, cadence, and teacher recommendation.
- **FR-019**: Each active package MUST own a learning plan with goal, baseline, target, cadence, and review strategy.
- **FR-020**: Each completed paid session MUST support a structured lesson report and safe learner/guardian note.
- **FR-021**: Completion/expiry MUST produce an outcome summary and next recommendation.
- **FR-022**: Child activation MUST require a verified guardian under the configured age policy.
- **FR-023**: Guardians MUST see authorized package, schedule, attendance, balance, progress, and safe feedback.
- **FR-024**: Child contact details and communications MUST be protected and unsafe exchange attempts moderated/audited.
- **FR-025**: Admins MUST configure price, duration, validity, sale state, trial limit, cutoff, teacher eligibility, and extension policy losslessly.
- **FR-026**: Financial/credit/expiry/state mutations MUST be server-authorized, granular, reasoned for exceptions, and audited.
- **FR-027**: Sales and booking kill switches MUST preserve active and historical data.
- **FR-028**: All actors MUST receive localized actionable states without sensitive identifiers/notes.
- **FR-029**: Relevant actors MUST be notified for order, payment, activation, booking, schedule, session, balance, expiry, and renewal events.
- **FR-030**: Operations MUST measure conversion, payment aging, activation, credit integrity, booking, attendance, reporting, adjustment, and renewal.
- **FR-031**: Unrestricted Egypt launch MUST require staged rollout, App Check evidence, negative authorization tests, rollback drill, and explicit sign-off.
- **FR-032**: MVP MUST NOT record or archive child video.
- **FR-033**: Future cohorts MUST separately model capacity, enrollment, schedule, per-learner attendance/credit, privacy, waitlist, and minimum enrollment.
- **FR-034**: Future markets MUST scope catalog, currency, payment, legal, localization, teacher eligibility, and release gates per market.
- **FR-035**: Future institutions MUST isolate administration, learners, teachers, branding, progress, attendance, and reporting.

### Non-Functional Requirements

- **NFR-001**: Financial and credit mutations MUST be atomic, idempotent, authorized, and traceable.
- **NFR-002**: Lists, discovery, activity, and admin queues MUST be bounded/paginated with no launch-critical global scans.
- **NFR-003**: Financial state MUST refresh from authoritative data after mutations, not optimistic balances.
- **NFR-004**: Mobile UI MUST support AR/EN, RTL/LTR, compact/expanded, dark mode, text scaling, and screen readers.
- **NFR-005**: Child, payment, and moderation data MUST be minimized in logs, analytics, notifications, and client documents.
- **NFR-006**: Launch design MUST support 10,000 registered learners, 1,000 active packages, and 100 concurrent booking attempts.
- **NFR-007**: Critical failures MUST be actionable/retryable without duplicate effects.
- **NFR-008**: Diagnostics MUST trace order, package, booking, credit, and admin action without private lesson content.

### Key Entities

- **Package Plan**: Market-scoped commercial and policy definition.
- **Package Order**: Purchase request and immutable terms/payment snapshot.
- **Student Package**: Activated one-learner/one-teacher entitlement period.
- **Package Credit Movement**: Immutable accounting event.
- **Compatibility Meeting**: Limited pre-purchase fit session and recommendation.
- **Learning Plan / Lesson Report / Package Summary**: Goal, session outcome, homework, and end result.
- **Guardian Link**: Verified authority over a child learner.
- **Teacher Verification Profile**: Reviewed capabilities, evidence, languages, and child eligibility.
- **Package Operation Audit**: Privileged mutation history.
- **Cohort Plan / Enrollment**: Future group offering and per-learner participation.
- **Institution Program**: Future tenant-scoped program boundary.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of eligible pilot users submit a package order without support.
- **SC-002**: 95% of correctly paid orders activate within the published SLA with zero duplicate activations.
- **SC-003**: 100% of tested credit histories satisfy the accounting invariant and never become negative.
- **SC-004**: 100% of tested booking, cancellation, failure, no-show, expiry, and adjustment paths produce exactly the expected movement.
- **SC-005**: 80% of activated pilot packages complete at least six sessions before expiry/approved extension.
- **SC-006**: 90% of completed sessions receive a structured report within 12 hours.
- **SC-007**: 85% of guardians locate next session, balance, latest report, and homework without help.
- **SC-008**: 100% of unauthorized payment, child-data, credit, and cross-learner attempts are denied in acceptance tests.
- **SC-009**: No unexpired credit disappears merely because renewal is declined.
- **SC-010**: Sales can be disabled and rollback completed within 15 minutes without corrupting package history.
- **SC-011**: Closed Egypt pilot completes 100 paid sessions with zero open P0 financial, child-safety, or credit-integrity defects.
- **SC-012**: 70% of compatibility participants reporting a good fit proceed to purchase.
- **SC-013**: Package purchase, balance, booking, progress, and guardian surfaces maintain 99.5% crash-free sessions during staged rollout.
- **SC-014**: No non-Egypt production user can purchase before explicit market approval.

## Assumptions

- Package is prepaid, manually renewed, eight 30-minute sessions, valid 35 days from activation, with a 12-hour cancellation cutoff.
- One teacher serves the period; renewal creates a separate historical period.
- Egypt payment reuses InstaPay/Vodafone Cash/WhatsApp reference and admin confirmation foundations.
- Existing auth, market gating, profiles, booking lifecycle, slot locks, video, notifications, moderation, and admin boundaries remain authoritative.
- Closed pilot uses curated teachers and learners.
- Compatibility is a short assessment, not a free full lesson.
- Groups, recording, international PSPs, and institutions require separate production gates.

## Dependencies

- Existing Egypt manual-payment readiness gates and verified teacher operations.
- Existing Quran Sessions scheduling, lifecycle, video, notification, and admin callable boundaries.
- Human QA across learner, teacher, guardian, and admin accounts.
- Legal/privacy approval for manual payment, WhatsApp, child oversight, and video delivery.

