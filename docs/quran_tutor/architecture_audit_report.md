# QuranTutor Architecture & Performance Audit

**Date:** 2026-06-26  
**Scope:** `packages/quran_sessions/`, `apps/tilawa/lib/features/quran_sessions/`, RTC join wiring touched by session detail flow.

---

## Executive summary

QuranTutor booking/approval/cancel/join flows are **mostly clean**. Central lifecycle rules live in `SessionTransitionTable`, server mutations go through gateways/use cases, and booking mode resolution is domain + app launch policy.

This pass fixed **real boundary violations** (cancel policy in presentation, duplicate cancel rules, BLoC→repository shortcuts, dashboard accept mapping in BLoC) and one **single-pass** dashboard partition. No product behavior change except **My Sessions cancel** now correctly respects min-notice policy (aligned with session detail).

---

## 1. Architecture violations found

| Severity | Issue | Location |
|----------|-------|----------|
| **High** | Cancel eligibility business rules in presentation layer | `presentation/session_join/session_detail_cancel_policy.dart` (removed) |
| **High** | Duplicate student cancel rules in widget; missing min-notice check | `my_sessions_screen.dart` `_canStudentCancelSession` |
| **Medium** | `SessionDetailBloc` loaded aggregate + resolved actor role via repositories | `session_detail_bloc.dart` |
| **Medium** | `BookingBloc` called `TeacherProfileRepository` directly | `booking_bloc.dart` |
| **Medium** | Accept-booking optimistic update manually constructed `QuranSession` in BLoC | `teacher_dashboard_bloc.dart` |
| **Low** | `session_join_ui_state.dart` duplicated cancelled-status switch | used private `_isCancelled` instead of domain extension |
| **Acceptable** | `resolveSessionJoinUiState` in presentation — maps domain lifecycle + join window to UI enum | `session_join_ui_state.dart` |
| **Acceptable** | `booking_rejection_reason_display.dart` — display sanitization only | presentation |
| **Acceptable** | `quran_sessions_launch_policy.dart` — client hints; server authoritative | app feature layer |
| **Acceptable** | `AvailabilityCubit` uses `ScheduleRepository` — availability CRUD, out of tutor booking scope | not changed |
| **Acceptable** | `JoinSessionUseCase` uses repositories — domain layer | correct layer |

No Firestore schema knowledge or raw queries in presentation BLoCs/screens.

---

## 2. What moved from → to

| From | To |
|------|-----|
| `presentation/session_join/session_detail_cancel_policy.dart` | `domain/policies/session_cancel_eligibility_policy.dart` |
| `my_sessions_screen.dart` inline cancel checks | `canStudentCancelQuranSession()` (domain) |
| `SessionDetailBloc` → `SessionAggregateRepository.getById` | `GetSessionAggregateUseCase` |
| `SessionDetailBloc` → `_resolveActorRole` + `TeacherProfileRepository` | `ResolveSessionActorRoleUseCase` |
| `BookingBloc` → `TeacherProfileRepository` | `GetTeacherProfileByIdUseCase` |
| `TeacherDashboardBloc` inline `QuranSession(...)` on accept | `mapAcceptedBookingToScheduledSession()` in `domain/mappers/quran_session_lifecycle_mapper.dart` |
| Cancelled lifecycle check in join UI resolver | `SessionLifecycleStatus.isCancelled` extension |

---

## 3. SOLID issues found / fixed

| Principle | Finding | Action |
|-----------|---------|--------|
| **SRP** | Cancel policy mixed with presentation join folder | Moved to domain policy |
| **SRP** | Teacher dashboard accept handler owned mapping + orchestration | Extracted mapper |
| **DIP** | BLoCs depended on concrete repositories | Injected use cases |
| **OCP** | Status transitions already declarative in `SessionTransitionTable` | No change needed |
| **ISP** | `SessionDetailBloc` optional deps for report/dispute/reschedule | Pre-existing; acceptable for feature-flagged wiring |
| **LSP** | N/A | — |

**Remaining (acceptable):** `SessionDetailBloc` still optional-falls back to `SessionRepository` when `GetSessionDetailUseCase` absent (test harness only; production DI always registers use case).

---

## 4. Data structures improved

| Area | Before | After |
|------|--------|-------|
| Teacher dashboard session partition | Two `.where()` scans over `allUpcoming` | Single `for` loop → `pendingBookingRequests` + `upcomingSessions` |
| Pending slot deletes | Already `Map<String, PendingSlotDelete>` by slot id | Unchanged (good) |
| Dashboard accept update | `.where().map(manual ctor).toList()` | `.where().map(mapAcceptedBookingToScheduledSession)` |

---

## 5. Remaining O(n) scans and why acceptable

| Scan | Complexity | Why OK |
|------|------------|--------|
| `my_sessions_screen._findSession` linear upcoming list | O(n), n ≪ 50 | Single-user upcoming sessions bounded by query |
| Dashboard list filter on cancel/accept/reject | O(n) per action | One booking id; typical n < 20 |
| `pendingDeletes.containsKey(slotId)` in slot lists | O(1) lookup | Map-backed |
| Teacher availability sort after edit | O(n log n) | n = 14-day horizon slots; user-triggered |
| `SessionLifecycleStatus.values.firstWhere` in mapper | O(statuses) | ~20 enum values; parse-once per DTO |
| `bloc.stream.firstWhere` in screens/tests | Async wait, not hot-path list scan | UI reload coordination only |

No nested `.where().firstWhere()` in production list builders.

---

## 6. Tests added / updated

| File | Change |
|------|--------|
| `test/domain/policies/session_cancel_eligibility_policy_test.dart` | Moved from presentation; added list-card notice test |
| `test/domain/mappers/quran_session_lifecycle_mapper_test.dart` | **New** — accept mapping |
| `test/presentation/blocs/session_detail_bloc_test.dart` | Use case wiring |
| `test/presentation/blocs/booking_bloc_test.dart` | `GetTeacherProfileByIdUseCase` |
| `test/presentation/screens/booking_screen_test.dart` | Same |
| `test/presentation/screens/session_detail_screen_test.dart` | Same |

Existing join UI, tutor approval, dashboard reject/cancel tests unchanged in intent.

---

## 7. Verification commands

```sh
melos run fix:format
dart analyze packages/quran_sessions apps/tilawa/lib/features/quran_sessions
flutter test packages/quran_sessions
flutter test apps/tilawa/test/features/quran_sessions
```

---

## 8. Behaviorally equivalent confirmation

- Booking mode (`autoConfirm` vs `requiresTutorApproval`): unchanged; still resolved via `quran_tutor_booking_mode.dart` + `quran_sessions_launch_policy.dart`; server authoritative on create.
- Tutor accept/reject/cancel: unchanged server paths; dashboard optimistic lists use same field mapping via domain mapper.
- Join flow: unchanged; `JoinSessionUseCase` + `SessionJoinWindowPolicy` + RTC module wiring intact.
- **Intentional alignment:** My Sessions cancel button now hides inside min-notice window (matches session detail). Previously showed cancel when detail would block — bug fix from deduplicating policy.

---

## Areas reviewed but not refactored

- `resolveSessionJoinUiState` — presentation view-model; delegates to domain policies.
- `GetTeacherDashboardUseCase` orchestrating multiple repos — application layer; correct.
- `TeacherDashboardBloc` availability/slot delete logic — uses domain services (`SchedulingPolicyResolver`, use cases); large but in scope for scheduling UX.
- Firebase/data mappers in `apps/tilawa/.../data/firebase/` — data layer; no presentation leakage found.
