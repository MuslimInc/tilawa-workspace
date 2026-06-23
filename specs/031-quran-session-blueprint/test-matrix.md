# Test Matrix — Quran Sessions

**Coverage target:** 95–100% for `domain/lifecycle/`, `domain/policies/`, session lifecycle use cases.  
**Existing baseline:** [specs/030-quran-sessions-domain/test-matrix.md](../030-quran-sessions-domain/test-matrix.md)

---

## Coverage by layer

| Layer | Target | Current (approx) | Priority |
|-------|--------|------------------|----------|
| Lifecycle guard + transition table | 100% | ~95% | P0 |
| Policies (cancellation, compensation, reschedule, no-show) | 100% | ~70% | P0 |
| Use cases (session commands) | 95% | ~80% | P0 |
| Booking integrity validator | 100% | ~75% | P0 |
| BLoCs (booking, my sessions) | 90% | ~85% | P1 |
| CF integration | Critical paths | ~60% | P0 |
| Firestore rules | Moderation + session deny | ~50% | P0 |
| Widget tests | Happy paths | ~15% | P2 |
| E2E Maestro | 3 flows | 0% | P2 |

---

## 1. Lifecycle guard (`SessionLifecycleGuard`)

| ID | Case | From | Action | Actor | Expect | File |
|----|------|------|--------|-------|--------|------|
| LG-01 | Free book | ∅ | confirmFreeBooking | student | scheduled | guard_test |
| LG-02 | Paid path | draft | initiatePayment | student | pendingPayment | guard_test |
| LG-03 | Invalid terminal move | completed | cancelByStudent | student | throw | guard_test |
| LG-04 | Teacher cancel inProgress | inProgress | cancelByTeacher | teacher | throw | guard_test |
| LG-05 | Dispute from scheduled | scheduled | openDispute | student | throw | guard_test |
| LG-06 | Dispute from completed | completed | openDispute | student | disputed | guard_test |
| LG-07 | Refund from any | * | issueRefund | admin | refunded | guard_test |
| LG-08 | Expire pending | pendingPayment | expireReservation | system | expired | guard_test |
| LG-09 | All 22 actions × valid from | table-driven | — | — | pass | exhaustive |
| LG-10 | All invalid pairs | table-driven | — | — | throw | exhaustive |

**Goal:** Generate table-driven test from `SessionTransitionTable.all()`.

---

## 2. Policies

### Cancellation (`ConfigurableCancellationPolicy`)

| ID | Case | Input | Expect |
|----|------|-------|--------|
| CP-01 | Early student cancel | 48h before | refundFraction=1.0 |
| CP-02 | Late student cancel | 2h before | refundFraction=0.0 |
| CP-03 | Inside block window | 30m before | allowed=false |
| CP-04 | Teacher cancel | any allowed | autoCompensations non-empty |
| CP-05 | Market override | EG late=12h | uses market config |
| CP-06 | Missing config | — | code fallback |

### Compensation (`ConfigurableCompensationPolicy`)

| ID | Trigger | Expect types |
|----|---------|--------------|
| CO-01 | teacherCancel | restoreSessionCredit |
| CO-02 | teacherNoShow | credit + wallet |
| CO-03 | adminChoice | selected subset |
| CO-04 | unknown trigger | none |

### Reschedule (`ReschedulePolicy`)

| ID | Case | Expect |
|----|------|--------|
| RP-01 | First reschedule 48h before | allowed |
| RP-02 | Second reschedule | blocked |
| RP-03 | Inside min hours | blocked |

### No-show (`NoShowPolicy`)

| ID | Case | Expect |
|----|------|--------|
| NS-01 | Before grace | cannot mark |
| NS-02 | After grace no joins | teacherNoShow |
| NS-03 | Student joined only | studentNoShow |

### Booking integrity (`BookingIntegrityValidator`)

| ID | Violation | Expect |
|----|-----------|--------|
| BI-01 | Suspended teacher | fail |
| BI-02 | Slot booked | fail |
| BI-03 | Vacation day | fail |
| BI-04 | Gender mismatch | fail |
| BI-05 | Child without guardian | fail |
| BI-06 | Paid no price in market | fail |

Existing: `booking_integrity_validator_test.dart`, `bookingEligibility.test.ts`.

---

## 3. Use cases (domain unit tests)

| Use case | Test IDs | Fake deps |
|----------|----------|-----------|
| CreateSessionBookingUseCase | UC-CB-01..10 | FakeSessionCommandGateway, FakeAggregateRepo |
| CancelSessionUseCase | UC-CC-01..08 | actor student/teacher/admin |
| RequestRescheduleUseCase | UC-RR-01..06 | |
| ConfirmRescheduleUseCase | UC-CR-01..06 | atomic slot swap |
| MarkNoShowUseCase | UC-NS-01..05 | |
| CompleteSessionUseCase | UC-CO-01..04 | |
| IssueCompensationUseCase | UC-IC-01..05 | FakeCompensationGateway |
| ExpirePendingReservationsUseCase | UC-EX-01..03 | |
| GetSessionTimelineUseCase | UC-GT-01..02 | FakeAuditRepository |
| ValidateBookingEligibilityUseCase | UC-VE-01..12 | all fake repos |

**Existing files:** `cancel_session_usecase_test.dart`, `create_session_booking_usecase_test.dart`, `mark_no_show_usecase_test.dart`, `reschedule_session_usecase_test.dart`.

**Gap:** `ValidateBookingEligibilityUseCase` — **0 tests** (roadmap P0).

---

## 4. Cloud Functions integration

| ID | Callable | Cases | File |
|----|----------|-------|------|
| CF-01 | createSessionBooking | happy, slot race, blocked, idempotency | integration |
| CF-02 | cancelSessionBooking | student, teacher, unauthorized | integration |
| CF-03 | requestSessionReschedule | pending create | integration |
| CF-04 | confirmSessionReschedule | slot swap | integration |
| CF-05 | markSessionNoShow | teacher/student/both | unit + integration |
| CF-06 | completeSession | from inProgress | integration |
| CF-07 | issueSessionCompensation | pending→completed | integration |
| CF-08 | approveSessionRefund | idempotent | paymentAndIdempotency |
| CF-09 | openSessionDispute | from completed | integration |
| CF-10 | resolveSessionDispute | favor_student ledger | integration |
| CF-11 | reportSessionConcern | create report | integration |
| CF-12 | expirePendingReservations | sync session expired | integration |

Run: `cd functions && npm run test:integration`

---

## 5. Firestore rules

| ID | Rule | Expect |
|----|------|--------|
| RL-01 | Client write booking | deny |
| RL-02 | Participant read session | allow |
| RL-03 | Non-participant read | deny |
| RL-04 | Owner update accountStatus active | deny |
| RL-05 | Applicant submit application | allow |
| RL-06 | Teacher write own availability | allow |

File: `functions/test-rules/usersModeration.rules.test.ts` + session rules tests.

---

## 6. BLoC / presentation tests

| BLoC | Test IDs | Status |
|------|----------|--------|
| BookingBloc | BB-01 eligibility block, BB-02 book success, BB-03 slot fail | ✅ |
| MySessionsBloc | MS-01 load, MS-02 cancel, MS-03 review | ✅ |
| TeacherApplicationBloc | TA-01 phone validation | ✅ |
| ProfileCompletionBloc | PC-01..05 | ❌ missing |
| SessionDetailBloc | SD-01 load timeline | partial |
| TeacherDashboardBloc | TD-01 load | ✅ |
| AvailabilityCubit | AV-01 save schedule | ✅ |

---

## 7. Widget tests

| Screen | Test IDs | Priority |
|--------|----------|----------|
| BookingScreen | WS-01 eligibility error display | P1 |
| ProfileCompletionScreen | WS-02 country/city required | P0 |
| SessionDetailScreen | WS-03 join link visible | P0 |
| CancelSessionSheet | WS-04 reason validation | P1 |
| TeacherListScreen | WS-05 empty state | P2 |

---

## 8. E2E flows (Maestro / integration_test)

| ID | Flow | Steps |
|----|------|-------|
| E2E-01 | Profile gate → book free | sign in → complete profile → book → my sessions |
| E2E-02 | Teacher apply → admin approve | apply → script approve → dashboard |
| E2E-03 | Cancel with reason | book → cancel → verify status |
| E2E-04 | Teacher cancel → student notification | `[manual]` |
| E2E-05 | Dispute open → admin resolve | `[Beta]` |

---

## 9. Edge case → test mapping

Cross-reference [edge-cases-matrix.md](./edge-cases-matrix.md):

| Edge range | Primary suite |
|------------|---------------|
| E01–E13 | CF-01, UC-CB, BI-* |
| E20–E28 | CP-*, CF-02, LG-* |
| E30–E35 | RP-*, CF-03/04 |
| E40–E46 | NS-*, CF-05 |
| E50–E56 | CF-09/10, CO-* |
| E60–E65 | UC-VE, capability tests |
| E80–E85 | RL-*, mapper tests |

---

## 10. CI gates

| Gate | Command | Required for |
|------|---------|--------------|
| Dart analyze | `dart analyze` | every PR |
| Domain tests | `flutter test packages/quran_sessions/test/domain/` | every PR |
| Package tests | `flutter test packages/quran_sessions/` | every PR |
| CF unit | `cd functions && npm test` | every PR |
| CF integration | `npm run test:integration` | pre-Beta deploy |
| Rules | `npm run test:rules` | pre-Beta deploy |
| Coverage report | lcov domain/lifecycle ≥95% | release |

---

## 11. Test data fixtures

| Fixture | Location |
|---------|----------|
| Session aggregates | `test/helpers/fixtures/session_aggregate_fixtures.dart` |
| Teachers | `fixtures.dart` makeTeacher |
| Fake gateways | `test/helpers/fakes/` |
| CF emulator seeds | `functions/scripts/stagingFreeBetaSmoke.ts` |

---

## 12. Missing tests (must add before Beta)

| Priority | Test | Owner layer |
|----------|------|-------------|
| P0 | ValidateBookingEligibilityUseCase full chain | domain |
| P0 | ProfileCompletionBlocTest | presentation |
| P0 | Session detail join link widget test | presentation |
| P0 | Legacy lifecycle mapper ambiguous rows | domain |
| P1 | Reschedule BLoC E2E | presentation |
| P1 | Report concern CF + future UI | integration |
| P2 | Maestro E2E-01 | e2e |

---

## Coverage verification command

```sh
# Domain focus
cd packages/quran_sessions
flutter test test/domain/lifecycle test/domain/policies test/domain/usecases

# Full package
flutter test

# Functions
cd ../../functions && npm test && npm run test:integration
```

**Definition of done (Beta):** All P0 rows green; lifecycle lcov ≥95%; staging smoke 10/10.
