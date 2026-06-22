# Feature Specification: Quran Sessions Business Domain

**Feature Branch**: `030-quran-sessions-domain`  
**Created**: 2026-06-22  
**Status**: Draft — awaiting approval before implementation  
**Input**: Production-ready scheduling, booking, cancellation, no-show,
compensation, refunds, notifications, and admin moderation for Quran Sessions.

**Depends on**: `packages/quran_sessions`, ADR-002 (backend-agnostic),
ADR-003 (teacher lifecycle), existing Firestore collections, admin panel
(`apps/tilawa_admin`), Cloud Functions moderation stack.

---

## Executive summary

Quran Sessions today has solid **teacher onboarding**, **availability
scheduling**, and **eligibility validation**, but the **booking/session vertical
is MVP scaffolding**: loose enums, client-side writes blocked by Firestore
rules, policies defined but unwired, no audit trail, no server-side lifecycle,
and no admin ops for live sessions.

This spec defines a **production business domain** where every
teacher/student/admin/system action is a **typed state transition**, persisted
server-side, auditable, policy-driven, and manageable from the admin panel —
without coupling the domain to Firebase.

**Do not implement screen-by-screen patches.** Build domain + server enforcement
first, then wire Flutter and admin UI.

---

## Step 1 — Audit summary (current state)

### What exists and is reusable

| Area | Status | Key paths |
|------|--------|-----------|
| Backend-agnostic package split | ✅ ADR-002 enforced | `packages/quran_sessions/` |
| Teacher application state machine | ✅ Documented + CF | ADR-003, `reviewTeacherApplication` |
| Weekly schedule + slot generation | ✅ Production-quality | `slot_generator.dart`, validators |
| Booking eligibility validation | ✅ Use case exists | `validate_booking_eligibility_usecase.dart` |
| Policy interfaces (stubs) | ⚠️ Defined, not wired | `cancellation_policy.dart`, `reschedule_policy.dart`, `payment_provider.dart` |
| Repository abstractions | ✅ 9 interfaces | `domain/repositories/` |
| Admin: applications, teachers, users | ✅ CF-backed | `apps/tilawa_admin/.../quran-sessions/` |
| Firestore collections | ⚠️ Partial schema | `quran_bookings`, `quran_sessions` |

### Critical gaps (production blockers)

1. **Rules/code conflict**: Firestore rules deny client writes to
   `quran_bookings` / `quran_sessions`; app datasources still write directly.
2. **No state machine**: `BookingStatus` (7 values) and `QuranSessionStatus`
   (6 values) have no transition guards, actor attribution, or audit.
3. **Cancel always `cancelled_by_student`**: no teacher/admin distinction.
4. **Policies unwired**: `StandardCancellationPolicy` never called from
   `CancelBookingUseCase`; `PaymentProvider.refund` never invoked.
5. **Reschedule stub**: `rescheduleBooking` reads doc, does not change slot.
6. **Race-prone booking**: client-side slot check; no atomic server validator.
7. **No audit collection**, no compensation records, no notification events.
8. **Admin panel**: no bookings/sessions UI; paths defined but unused.
9. **No booking/session Cloud Functions** (only teacher moderation CFs exist).
10. **Feature flag**: `quranSessionsBookingEnabled: false` in production.

### Current enums (to be superseded)

```dart
// quran_booking.dart — booking commercial state (partial)
enum BookingStatus { pending, confirmed, rejected, cancelled, completed, refunded }

// quran_session.dart — session operational state (partial)
enum QuranSessionStatus {
  scheduled, inProgress, completed,
  cancelledByStudent, cancelledByTeacher, noShow,
}
```

These must merge into a single **lifecycle model** with explicit transitions
(see §2).

---

## Step 2 — Business domain design

### 2.1 Core modeling decision: Session aggregate

Introduce **`QuranSessionAggregate`** as the domain aggregate root for one
bookable occurrence. It wraps:

| Sub-entity | Responsibility |
|------------|----------------|
| `SessionIdentity` | ids: `aggregateId`, `bookingId`, `sessionId` (stable after creation) |
| `SessionParticipants` | `teacherId`, `studentId`, market context |
| `SessionSlot` | `slotId`, `startsAt`, `endsAt`, timezone, reschedule history |
| `SessionCommercials` | pricing type, amount, payment reference, refund state |
| `SessionLifecycle` | current status, phase, terminal flag |
| `SessionAttendance` | join timestamps, evidence, no-show classification |
| `SessionCallConfig` | call type, meeting link / room id |

**Booking** and **Session** documents remain in Firestore for query ergonomics,
but the **domain treats them as one aggregate** mutated only through use cases
that enforce invariants together.

### 2.2 Unified lifecycle status enum

Replace ad-hoc string statuses with **`SessionLifecycleStatus`**:

```dart
enum SessionLifecycleStatus {
  // Reservation / payment
  draft,              // student started flow, slot not locked
  pendingPayment,     // slot soft-held, awaiting payment capture

  // Active lifecycle
  scheduled,          // paid/free confirmed, session doc created
  confirmed,          // both parties acknowledged (optional pre-start)
  inProgress,         // session window open, call active
  rescheduled,        // transient: slot changed, returns to scheduled

  // Terminal — cancellation
  cancelledByStudent,
  cancelledByTeacher,
  cancelledByAdmin,

  // Terminal — attendance failure
  teacherNoShow,
  studentNoShow,
  bothNoShow,
  incomplete,         // started but not completed within policy window

  // Terminal — success
  completed,

  // Terminal — dispute / remediation
  disputed,
  compensated,        // remediation applied, may coexist with refund
  refunded,
  expired,            // pendingPayment/draft timed out; slot released
}
```

**Phase grouping** (for UI and policies):

| Phase | Statuses |
|-------|----------|
| `reservation` | draft, pendingPayment |
| `active` | scheduled, confirmed, inProgress, rescheduled |
| `terminal` | all others |

Helper: `bool get isSlotBlocking =>
  phase == active || status == pendingPayment`.

### 2.3 State machine — transition table

Each transition is a **`SessionTransition`** value object:

```dart
class SessionTransition {
  const SessionTransition({
    required this.action,
    required this.from,
    required this.to,
    required this.allowedActors,
    required this.requiresReason,
    required this.requiresAdminCompensationChoice,
    this.sideEffects = const [],
  });

  final SessionAction action;
  final Set<SessionLifecycleStatus> from; // empty = create
  final SessionLifecycleStatus to;
  final Set<ActorRole> allowedActors;
  final bool requiresReason;
  final bool requiresAdminCompensationChoice;
  final List<TransitionSideEffect> sideEffects;
}
```

#### Valid transitions

| Action | From → To | Actor | Reason required | Side effects |
|--------|-----------|-------|-----------------|--------------|
| `createDraft` | ∅ → draft | student | no | — |
| `initiatePayment` | draft → pendingPayment | student | no | soft-hold slot TTL |
| `confirmBooking` | pendingPayment → scheduled | system | no | create session doc, notify both |
| `confirmFreeBooking` | draft → scheduled | student/system | no | atomic slot lock, create session |
| `acknowledgeSession` | scheduled → confirmed | student, teacher | no | optional reminder schedule |
| `startSession` | scheduled/confirmed → inProgress | system, teacher | no | open call room |
| `completeSession` | inProgress → completed | system, teacher, student | no | payout eligibility, review prompt |
| `requestReschedule` | scheduled/confirmed → rescheduled | student, teacher | yes | notify counterparty |
| `confirmReschedule` | rescheduled → scheduled | student, teacher, system | yes | release old slot, lock new |
| `adminForceReschedule` | scheduled/confirmed → scheduled | admin | yes | audit + notify |
| `cancelByStudent` | scheduled/confirmed/pendingPayment → cancelledByStudent | student | yes | apply cancellation policy |
| `cancelByTeacher` | scheduled/confirmed → cancelledByTeacher | teacher | yes | auto-compensate student |
| `cancelByAdmin` | active/reservation → cancelledByAdmin | admin | yes | admin picks compensation |
| `markTeacherNoShow` | scheduled/confirmed/inProgress → teacherNoShow | admin, system | optional | compensate student |
| `markStudentNoShow` | scheduled/confirmed/inProgress → studentNoShow | admin, system, teacher | optional | apply policy |
| `markBothNoShow` | scheduled/confirmed/inProgress → bothNoShow | system | no | evidence from join logs |
| `markIncomplete` | inProgress → incomplete | system | no | partial completion rules |
| `openDispute` | completed/cancelled*/noShow* → disputed | student, teacher, admin | yes | manual review case |
| `issueCompensation` | disputed/cancelledByTeacher/teacherNoShow → compensated | admin, system | yes | execute compensation policy |
| `issueRefund` | * → refunded | admin, system | yes | payment gateway refund |
| `expireReservation` | draft/pendingPayment → expired | system | no | release slot |
| `rejectBooking` | pendingPayment → expired | system | no | payment void |

#### Invalid transitions (must throw `InvalidTransitionFailure`)

Examples enforced in `SessionLifecycleGuard`:

- Any transition **from terminal** except `openDispute`, `issueCompensation`,
  `issueRefund` (limited remediation paths).
- `cancelByStudent` within **non-cancellable window** without admin override.
- `completeSession` when `inProgress` never entered (unless admin).
- `confirmReschedule` without atomic new-slot validation.
- Teacher cancel when session already `inProgress` (requires admin).
- Double `markTeacherNoShow` on same aggregate.

Implementation: **`SessionLifecycleGuard`** pure class + exhaustive unit tests.

### 2.4 Actor roles and authorization

```dart
enum ActorRole { student, teacher, admin, system }

class SessionActor {
  final ActorRole role;
  final String userId;
  final ActionSource source; // mobileApp, adminPanel, backendJob, webhook
}
```

Authorization lives in **use cases**, not UI. Server CFs re-validate actor
against Firestore auth + custom claims.

### 2.5 Cancellation policy (configurable)

Extend boundaries pattern:

```dart
abstract interface class CancellationPolicy {
  CancellationDecision evaluate(CancellationContext ctx);
}

class CancellationDecision {
  final bool allowed;
  final String? blockReason;
  final List<CompensationAction> autoCompensations;
  final double refundFraction; // 0.0–1.0
  final bool countsAgainstStudent;
  final bool countsAgainstTeacher;
}
```

**Configuration source** (priority order):

1. `quran_session_platform_config/global.cancellationPolicy`
2. Per-market override on `quran_session_market_configs/{country}`
3. Code default (`StandardCancellationPolicy` as fallback)

**Teacher cancellation** (always when allowed):

- Mandatory reason (min length validated).
- Session becomes non-attendable immediately.
- **Auto-compensation** for student per policy (see §2.6).
- Increment `teacherCancellationCount` on teacher metrics doc.
- Notify student immediately.

**Student cancellation**:

- Mandatory reason.
- Policy evaluates timing:
  - **Early** (> configurable hours): restore credit / full refund / free reschedule.
  - **Late** (< threshold): credit consumed, partial/no refund.
- Increment `studentCancellationCount`.
- Notify teacher.

**Admin cancellation**:

- Mandatory reason + explicit `CompensationChoice` enum from admin UI.
- Full audit event with admin uid.

### 2.6 Compensation domain (configurable)

```dart
enum CompensationType {
  restoreSessionCredit,
  grantReplacementSession,
  extendSubscriptionPeriod,
  issueWalletCredit,
  createManualReviewCase,
  processPaymentRefund,
  none,
}

class CompensationAction {
  final CompensationType type;
  final Map<String, dynamic> parameters; // typed accessors per type
  final String policyRuleId;             // traceability
}

abstract interface class CompensationPolicy {
  List<CompensationAction> forTeacherCancellation(TeacherCancelContext ctx);
  List<CompensationAction> forTeacherNoShow(NoShowContext ctx);
  List<CompensationAction> forAdminChoice(AdminCompensationContext ctx);
}

abstract interface class CompensationGateway {
  Future<Either<Failure, CompensationResult>> execute(
    CompensationAction action,
    SessionIdentity session,
  );
}
```

**Execution model**:

1. Domain computes `List<CompensationAction>` from policy.
2. Use case persists `CompensationRecord` (pending).
3. `CompensationGateway` executes (payment SDK, credit ledger, etc.).
4. On success → update record + emit audit + notification.
5. On failure → record `failed` with retry metadata; **session state already
   terminal** — compensation retried idempotently.

Future payment integration: swap `CompensationGateway` impl; domain unchanged.

### 2.7 No-show handling

```dart
enum NoShowClassification {
  teacherNoShow,
  studentNoShow,
  bothNoShow,
  lateJoin,       // sub-state recorded in attendance, may not change terminal status
  incomplete,
}

class SessionAttendance {
  final DateTime? teacherJoinedAt;
  final DateTime? studentJoinedAt;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final NoShowClassification? classification;
  final String? evidenceJson; // call provider logs, admin notes
}
```

**Detection sources** (priority):

1. Call provider webhooks (Agora/WebRTC) → system actor.
2. Scheduled job: `sessionStart + gracePeriod` with no joins → system.
3. Teacher/admin manual mark → validated by policy.
4. Admin override always available.

Each classification triggers policy + metrics update on
`quran_teacher_metrics/{teacherId}` and `quran_student_metrics/{studentId}`.

### 2.8 Rescheduling (first-class flow)

```dart
class RescheduleRequest {
  final String aggregateId;
  final String requestedByUserId;
  final ActorRole requestedByRole;
  final String reason;
  final String newSlotId;
  final RescheduleRequestStatus status; // pending, accepted, rejected, expired
}
```

**Flow**:

1. `RequestRescheduleUseCase` validates via `ReschedulePolicy` + slot availability.
2. Creates `RescheduleRequest` doc; aggregate → `rescheduled` (or stays
   `scheduled` with pending flag — pick one; recommend transient `rescheduled`).
3. Counterparty accepts OR admin forces OR auto-accept per policy.
4. `ConfirmRescheduleUseCase` runs **atomic transaction**:
   - Revalidate new slot (same checks as create booking).
   - Release old slot lock.
   - Lock new slot.
   - Update aggregate slot fields + increment `rescheduleCount`.
   - Append audit events (request + confirm).
   - Notify both parties.

Old slot released **only after** new slot lock succeeds.

### 2.9 Booking reliability (server-enforced)

**`CreateSessionBookingUseCase`** (replaces/extends `CreateBookingUseCase`):

Server-side validator (`BookingIntegrityValidator`) checks:

| Check | Source |
|-------|--------|
| Teacher active + publicly visible | `quran_teacher_profiles` |
| Teacher not suspended | application + profile status |
| Student account active | `users.quranSessionsProfile.accountStatus` |
| Student eligibility | gender/age/safety policy |
| Slot exists in generated schedule | schedule + overrides |
| Slot not booked | aggregate query / slot lock doc |
| Min notice | `schedulingPolicy.minNoticeMinutes` |
| Max horizon | `schedulingPolicy.maxHorizonDays` |
| No vacation/unavailable override | override doc |
| No concurrent double-book | transactional slot lock |
| Payment captured (if paid) | `PaymentProvider` before confirm |

Client `CreateBookingUseCase` becomes thin: calls **`SessionCommandGateway`**
(callable CF / REST) — never trusts client-generated availability alone.

**Slot lock strategy** (Firestore):

```
quran_slot_locks/{teacherId}_{slotStartUtc}
  - aggregateId, lockedAt, expiresAt, lockType: soft|hard
```

TTL on soft locks (pendingPayment); hard lock on confirmed.

### 2.10 Notifications (backend-driven, provider-agnostic)

```dart
enum SessionNotificationType {
  bookingConfirmed,
  sessionReminder,
  teacherCancelled,
  studentCancelled,
  adminCancelled,
  rescheduleRequested,
  rescheduleConfirmed,
  noShowMarked,
  compensationIssued,
  refundIssued,
}

abstract interface class SessionNotificationGateway {
  Future<void> enqueue(SessionNotificationEvent event);
}
```

**Persistence**: `quran_session_notifications/{id}` with delivery status per channel.

**Channels** (future): push, email, SMS, WhatsApp — each a separate infra
adapter reading from notification queue. Domain only enqueues typed events.

Scheduled job: `sessionReminder` at T-24h, T-1h (configurable).

### 2.11 Audit trail (mandatory)

```dart
class SessionAuditEvent {
  final String id;
  final String aggregateId;
  final String actorId;
  final ActorRole actorRole;
  final SessionAction action;
  final SessionLifecycleStatus? previousStatus;
  final SessionLifecycleStatus newStatus;
  final String? reason;
  final DateTime timestamp;
  final ActionSource source;
  final Map<String, dynamic> metadata;
}
```

**Collection**: `quran_session_events/{eventId}`  
**Append-only**. Never update/delete audit events.

Every use case that mutates lifecycle calls `AuditRepository.append(...)`.

Admin panel reads timeline ordered by `timestamp ASC`.

### 2.12 Admin panel operations

New admin routes under `/quran-sessions/`:

| Route | Capability |
|-------|------------|
| `/sessions` | List/filter sessions (status, teacher, student, date, country, city) |
| `/sessions/:id` | Detail + audit timeline + compensation history |
| `/sessions/:id/actions` | Cancel, no-show marks, compensation, refund approval |

All mutations via **callable Cloud Functions** (never direct Firestore writes):

| Callable | Purpose |
|----------|---------|
| `createSessionBooking` | Student booking (or internal) |
| `cancelSessionBooking` | Actor-aware cancel |
| `requestSessionReschedule` | Initiate reschedule |
| `confirmSessionReschedule` | Accept/force reschedule |
| `markSessionNoShow` | Teacher/student/both |
| `completeSession` | Manual complete (admin) |
| `issueSessionCompensation` | Admin compensation |
| `approveSessionRefund` | Manual refund approval |
| `moderateSessionDispute` | Dispute resolution |
| `suspendTeacherBookings` | Already partially via profile; extend with reason |
| `suspendStudentSessions` | Already via `moderateQuranSessionsUser` |

Extend existing:

- `moderateTeacherProfile` — add `acceptBookings: false` flag
- `moderateQuranSessionsUser` — already suspends student

**Metrics dashboards** (Phase 6):

- Teacher cancellation rate = cancellations / confirmed sessions (rolling 90d)
- Student no-show rate
- Dispute rate

### 2.13 Domain layer structure (new / refactored)

```
packages/quran_sessions/lib/src/domain/
  entities/
    session_aggregate.dart          # aggregate root
    session_lifecycle_status.dart
    session_audit_event.dart
    compensation_record.dart
    reschedule_request.dart
    session_attendance.dart
    teacher_metrics.dart            # denormalized read model
    student_metrics.dart
  value_objects/
    session_action.dart
    actor_role.dart
    session_slot.dart
  lifecycle/
    session_lifecycle_guard.dart    # pure transition validation
    session_transition_table.dart   # declarative transitions
  policies/
    cancellation_policy.dart        # move from boundaries, configurable
    compensation_policy.dart
    reschedule_policy.dart
    no_show_policy.dart
    booking_integrity_validator.dart
  gateways/                         # NEW — infra interfaces for commands
    session_command_gateway.dart    # create/cancel/reschedule RPC
    compensation_gateway.dart
    session_notification_gateway.dart
    audit_repository.dart           # append-only
  usecases/
    create_session_booking_usecase.dart
    cancel_session_usecase.dart
    request_reschedule_usecase.dart
    confirm_reschedule_usecase.dart
    mark_no_show_usecase.dart
    complete_session_usecase.dart
    issue_compensation_usecase.dart
    get_session_timeline_usecase.dart
    ...
  repositories/
    session_aggregate_repository.dart  # replaces split booking+session for mutations
    session_read_repository.dart       # queries unchanged
```

**Boundaries folder** retains payment/call providers; scheduling policies
**move into domain/policies** with config injection.

Presentation and existing read paths migrate gradually; **all writes** go through
new use cases + `SessionCommandGateway`.

---

## Step 3 — Firestore data model & migration

See [data-model.md](./data-model.md) for field-level schema.

### Migration path (safest)

**Phase M0 — Additive (no breaking changes)**

1. Add `lifecycleStatus` field to `quran_bookings` and `quran_sessions`.
2. Create collections: `quran_session_events`, `quran_session_compensations`,
   `quran_session_notifications`, `quran_slot_locks`, `quran_reschedule_requests`.
3. Deploy Cloud Functions; keep client writes disabled.
4. Backfill script maps legacy status → `lifecycleStatus`:
   - booking `confirmed` + session `scheduled` → `scheduled`
   - session `cancelled_by_student` → `cancelledByStudent`
   - etc.

**Phase M1 — Dual read**

1. Mappers prefer `lifecycleStatus`, fall back to legacy `status`.
2. Flutter reads work with both shapes.

**Phase M2 — Server-only writes**

1. Remove direct Firestore writes from app datasources.
2. App calls `SessionCommandGateway` → CF → Firestore transaction.

**Phase M3 — Deprecate legacy**

1. Stop writing `status` string field.
2. Remove legacy enum mapping after admin confirms backfill.

**Rollback**: legacy `status` field retained until M3 complete.

---

## Step 4 — Implementation phases

| Phase | Scope | Exit criteria |
|-------|-------|---------------|
| **1 — Domain core** | Lifecycle enum, guard, transition table, audit/compensation entities, 95%+ unit tests | All valid/invalid transitions tested; analyzer clean |
| **2 — Use cases** | Booking, cancel, reschedule, no-show, compensation use cases with fakes | Use case test matrix green |
| **3 — Backend** | CFs, Firestore transactions, slot locks, migration script, rules | Emulator integration tests; client writes removed |
| **4 — Flutter UX** | Wire blocs to `SessionCommandGateway`; cancellation reasons; policy copy | Widget + bloc tests; fake backend E2E |
| **5 — Admin panel** | Sessions list/detail, timeline, moderation actions via CF | Manual QA checklist |
| **6 — Async ops** | Notification queue, reminder jobs, metrics aggregation | Job tests + observability |

### Implementation progress snapshot (2026-06-22)

- Phase 1 delivered for lifecycle engine/value objects, plus legacy bridge:
  `QuranBooking` / `QuranSession` now expose `effectiveLifecycleStatus` with
  fallback mapping from `BookingStatus` / `QuranSessionStatus`.
- Phase 2 delivered for orchestration layer:
  `CreateSessionBookingUseCase`, `CancelSessionUseCase`,
  `RequestRescheduleUseCase`, `ConfirmRescheduleUseCase`,
  `MarkNoShowUseCase`, `CompleteSessionUseCase`,
  `IssueCompensationUseCase`, `GetSessionTimelineUseCase`,
  `ExpirePendingReservationsUseCase`.
- New domain interfaces delivered:
  `SessionAggregateRepository`, `SessionCommandGateway`,
  `CompensationGateway`, `SessionNotificationGateway`, `AuditRepository`.
- Phase 3 partial delivered:
  callable CF commands under `functions/src/quranSessions/`,
  scheduled `expirePendingReservations`, lifecycle backfill script,
  Firestore rules/indexes updates, and app booking datasource switched from
  direct writes to callable functions.

**Do not start Phase 3 until Phase 1–2 approved and merged.**

---

## Step 5 — Test matrix

See [test-matrix.md](./test-matrix.md).

**Coverage target**: 95–100% for `domain/lifecycle/`, `domain/policies/`,
`domain/usecases/` related to session lifecycle.

---

## Open decisions (need product input)

| # | Question | Default recommendation |
|---|----------|------------------------|
| 1 | Is `confirmed` status needed or skip to `scheduled` only? | Keep `confirmed` as optional post-booking ack; MVP can auto-confirm |
| 2 | Payment-before-booking vs book-then-charge? | `pendingPayment` + soft lock for paid; free skips to `scheduled` |
| 3 | Can student cancel within 1h? | Configurable per market; default block < 1h |
| 4 | Teacher cancel penalty thresholds? | Track only in Phase 6; no auto-suspend until N cancels |
| 5 | Single doc vs booking+session docs long term? | Keep dual docs for query indexes; domain aggregate unifies |

---

## Approval gate

**Implementation must not begin until this spec is reviewed and approved.**

Reply with: approved / changes needed / defer items.

After approval, Phase 1 starts with `SessionLifecycleGuard` + tests only — no UI.

---

## Related documents

- [data-model.md](./data-model.md) — Firestore collections & fields
- [plan.md](./plan.md) — task breakdown per phase
- [test-matrix.md](./test-matrix.md) — exhaustive test cases
- [ADR-002](../../docs/adr/002-quran-sessions-backend-agnostic-architecture.md)
- [ADR-003](../../docs/adr/003-teacher-application-lifecycle.md)
- [ADR-005](../../docs/adr/005-quran-sessions-lifecycle-legacy-bridge.md)
- [Firestore data model (current)](../../docs/quran_sessions_firestore_data_model.md)
