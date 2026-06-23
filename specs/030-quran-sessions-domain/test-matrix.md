# Test Matrix: Quran Sessions Business Domain

**Coverage target**: 95–100% for `domain/lifecycle/`, `domain/policies/`,
session-related `domain/usecases/`.

---

## 1. State transitions — valid

Each row: given aggregate in `from`, actor with role, action → expect `to` +
side effects flagged.

| ID | From | Action | Actor | To | Side effects |
|----|------|--------|-------|-----|--------------|
| T-V01 | ∅ | createDraft | student | draft | — |
| T-V02 | draft | confirmFreeBooking | student | scheduled | slot hard lock, session create, notify |
| T-V03 | draft | initiatePayment | student | pendingPayment | soft lock TTL |
| T-V04 | pendingPayment | confirmBooking | system | scheduled | capture payment, hard lock |
| T-V05 | scheduled | acknowledgeSession | student | confirmed | — |
| T-V06 | scheduled | acknowledgeSession | teacher | confirmed | — |
| T-V07 | scheduled | startSession | system | inProgress | — |
| T-V08 | confirmed | startSession | teacher | inProgress | — |
| T-V09 | inProgress | completeSession | system | completed | review prompt notify |
| T-V10 | scheduled | requestReschedule | student | rescheduled | notify teacher |
| T-V11 | rescheduled | confirmReschedule | teacher | scheduled | slot swap atomic |
| T-V12 | scheduled | cancelByStudent | student | cancelledByStudent | policy refund |
| T-V13 | scheduled | cancelByTeacher | teacher | cancelledByTeacher | auto compensate |
| T-V14 | scheduled | cancelByAdmin | admin | cancelledByAdmin | admin compensation |
| T-V15 | inProgress | markIncomplete | system | incomplete | — |
| T-V16 | scheduled | markTeacherNoShow | admin | teacherNoShow | compensate |
| T-V17 | scheduled | markStudentNoShow | teacher | studentNoShow | policy |
| T-V18 | scheduled | markBothNoShow | system | bothNoShow | — |
| T-V19 | cancelledByTeacher | issueCompensation | system | compensated | gateway execute |
| T-V20 | completed | openDispute | student | disputed | manual case |
| T-V21 | disputed | issueRefund | admin | refunded | payment refund |
| T-V22 | pendingPayment | expireReservation | system | expired | release soft lock |
| T-V23 | pendingPayment | rejectBooking | system | expired | void payment |

---

## 2. State transitions — invalid

| ID | From | Action | Actor | Expected failure |
|----|------|--------|-------|------------------|
| T-I01 | completed | cancelByStudent | student | InvalidTransitionFailure |
| T-I02 | cancelledByTeacher | startSession | teacher | InvalidTransitionFailure |
| T-I03 | expired | confirmBooking | system | InvalidTransitionFailure |
| T-I04 | draft | completeSession | student | InvalidTransitionFailure |
| T-I05 | inProgress | cancelByTeacher | teacher | InvalidTransitionFailure (needs admin) |
| T-I06 | scheduled | cancelByStudent | teacher | UnauthorizedActorFailure |
| T-I07 | scheduled | cancelByAdmin | student | UnauthorizedActorFailure |
| T-I08 | terminal* | *any except remediation* | * | InvalidTransitionFailure |
| T-I09 | scheduled | cancelByStudent (no reason) | student | ReasonRequiredFailure |
| T-I10 | rescheduled | confirmReschedule (slot taken) | system | SlotUnavailableFailure |

---

## 3. Cancellation policy

| ID | Scenario | Hours until session | Actor | Expected |
|----|----------|---------------------|-------|----------|
| T-C01 | Student early cancel | 48 | student | refund 1.0, credit restored |
| T-C02 | Student late cancel | 12 | student | refund 0.0, counts against student |
| T-C03 | Student cancel exactly 24h | 24 | student | refund 1.0 (boundary) |
| T-C04 | Teacher cancel | any | teacher | full student compensate, counts against teacher |
| T-C05 | Admin cancel + full refund choice | any | admin | refund per admin choice |
| T-C06 | Cancel blocked < min notice | 0.5 | student | not allowed |
| T-C07 | Market override late refund 0.5 | 12 | student | refund 0.5 per market config |

---

## 4. Compensation policy

| ID | Trigger | Policy config | Expected actions |
|----|---------|---------------|------------------|
| T-P01 | Teacher cancel | default | restoreSessionCredit |
| T-P02 | Teacher no-show | default | restoreSessionCredit + issueWalletCredit |
| T-P03 | Admin manual | admin picks refund | processPaymentRefund |
| T-P04 | Gateway failure | any | record pending, retry idempotent |
| T-P05 | Subscription pricing | teacher cancel | extendSubscriptionPeriod |

---

## 5. Rescheduling

| ID | Scenario | Expected |
|----|----------|----------|
| T-R01 | First reschedule > 24h | allowed |
| T-R02 | Second reschedule | blocked (max 1) |
| T-R03 | Reschedule < 24h | blocked |
| T-R04 | Confirm with valid new slot | old released, new locked |
| T-R05 | Confirm with taken new slot | fail, old slot retained |
| T-R06 | Admin force reschedule | skip counterparty accept |
| T-R07 | Request expires | status expired, aggregate → scheduled |

---

## 6. Booking integrity

| ID | Scenario | Expected |
|----|----------|----------|
| T-B01 | Happy path free booking | scheduled |
| T-B02 | Double booking same slot | second fails SlotUnavailableFailure |
| T-B03 | Concurrent booking race | one wins, one fails (transaction) |
| T-B04 | Teacher suspended | BookingNotAllowedFailure |
| T-B05 | Student suspended | BookingNotAllowedFailure |
| T-B06 | Slot on vacation override | SlotUnavailableFailure |
| T-B07 | Below min notice | BookingPolicyViolationFailure |
| T-B08 | Beyond max horizon | BookingPolicyViolationFailure |
| T-B09 | Safety policy gender mismatch | EligibilityFailure |
| T-B10 | Payment succeeds, booking fails | payment void/refund (saga) |
| T-B11 | Client slot list stale | server revalidation rejects |

---

## 7. No-show

| ID | Scenario | Expected |
|----|----------|----------|
| T-N01 | Teacher never joins, student waits | teacherNoShow after grace |
| T-N02 | Student never joins | studentNoShow |
| T-N03 | Neither joins | bothNoShow |
| T-N04 | Late join within grace | attendance recorded, may stay inProgress |
| T-N05 | Session started, ends early | incomplete |
| T-N06 | Admin override no-show | audit + policy applied |

---

## 8. Audit events

| ID | Scenario | Expected audit fields |
|----|----------|----------------------|
| T-A01 | Any transition | actorId, actorRole, action, prev, new, timestamp, source |
| T-A02 | Cancel with reason | reason persisted |
| T-A03 | Admin action | admin uid in actorId, source adminPanel |
| T-A04 | System job | actorRole system, source backendJob |

---

## 9. Notifications

| ID | Event | Expected enqueue |
|----|-------|------------------|
| T-NF01 | booking confirmed | both parties |
| T-NF02 | teacher cancelled | student |
| T-NF03 | compensation issued | student |
| T-NF04 | reminder T-24h | both |
| T-NF05 | notify fails after booking ok | booking committed, notification retry |

---

## 10. Timezone edge cases

| ID | Scenario | Expected |
|----|----------|----------|
| T-Z01 | Cancel at 23:59 local, session next day | policy uses market TZ |
| T-Z02 | DST spring forward gap slot | slot not generated |
| T-Z03 | DST fall back duplicate hour | slot IDs unique by UTC instant |
| T-Z04 | Teacher TZ ≠ student TZ | stored UTC, display local |

---

## 11. Backend failure scenarios

| ID | Scenario | Expected behavior |
|----|----------|-------------------|
| T-F01 | Firestore transaction conflict | retry with backoff, then fail |
| T-F02 | CF timeout mid-transaction | idempotent retry safe |
| T-F03 | Partial write (booking without session) | transaction rollback |
| T-F04 | Compensation after cancel committed | async retry, not double-cancel |

---

## Test file layout (proposed)

```
packages/quran_sessions/test/
  domain/
    lifecycle/
      session_lifecycle_guard_test.dart      # T-V*, T-I*
      session_transition_table_test.dart
    policies/
      cancellation_policy_test.dart          # T-C*
      compensation_policy_test.dart          # T-P*
      reschedule_policy_test.dart            # T-R*
      no_show_policy_test.dart               # T-N*
      booking_integrity_validator_test.dart    # T-B*
    usecases/
      create_session_booking_usecase_test.dart
      cancel_session_usecase_test.dart
      reschedule_session_usecase_test.dart
      mark_no_show_usecase_test.dart
      complete_session_usecase_test.dart
      issue_compensation_usecase_test.dart
      session_timeline_and_expiry_usecases_test.dart
  helpers/
    fakes/
      fake_session_aggregate_repository.dart
      fake_session_command_gateway.dart
      fake_compensation_gateway.dart
      fake_session_notification_gateway.dart
      fake_audit_repository.dart
    fixtures/
      session_aggregate_fixtures.dart

functions/test/quranSessions/
  sessionLifecycleService.test.ts
  slotLockService.test.ts
  createSessionBooking.test.ts
```

---

## Coverage gate (CI)

Add to Phase 1 PR:

```yaml
# Pseudocode — enforce in melos or CI
min_coverage:
  packages/quran_sessions/lib/src/domain/lifecycle/: 95
  packages/quran_sessions/lib/src/domain/policies/: 95
```
