# Testability Violations — Quran Sessions

**Audit date:** 2026-06-23  
**Test inventory:** 67 package · 7 app · 9 CF unit test files

---

## Unmockable / hard-to-test patterns

| Issue | File | Location | Problem | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|---------|--------|----------|---------------|--------------|
| `DateTime.now()` in BLoC without inject | `my_sessions_bloc.dart` | L44 | No `now` parameter (unlike `TeacherDashboardBloc` L56) | Flaky upcoming/past tests at midnight | **P2** | Add `DateTime Function()? now` ctor param | N |
| `DateTime.now()` in entity getter | `quran_session.dart` | L56 `isUpcoming` | Side effect in getter | Hard to test time boundaries | **P2** | Pure method `isUpcomingAt(DateTime now)` | N |
| `DateTime.now()` in domain policies | `booking_integrity_validator.dart` L82; `configurable_cancellation_policy.dart` L133 | `_nowUtc()` top-level | Not injectable in use cases | Policy tests use real time (some tests do) | **P2** | `Clock` interface | N |
| `getIt` in router builders | `quran_sessions_nav.dart` | L125–150 | Widget tests need full DI | Route integration tests heavy | **P2** | Override `GetIt` in tests or pass deps | N |
| `FirebaseFirestore.instance` in module | `quran_sessions_firebase_module.dart` | L35–36 | Singleton — hard to swap | Integration tests need emulator | **P2** | Acceptable with emulator suite | N |
| Global `QuranSessionsMvpStore.instance` | `quran_sessions_mvp_store.dart` | Singleton | Mutable shared state | Test isolation risk in fake mode | **P1** | Reset between tests | N |
| Review failure swallowed | `my_sessions_bloc.dart` | L114–116 | No failure state to assert | Can't test error UX | **P1** | Emit failure state | N |

---

## Firebase / platform in wrong layer

| Issue | File | Location | Verdict |
|-------|------|----------|---------|
| Firestore in package presentation | — | None found | **Pass** ✓ |
| Firestore in app data | `firestore_*` | Correct layer | **Pass** ✓ |
| `cloud_functions` in gateway | `firebase_session_mutation_gateway.dart` | Data layer | **Pass** ✓ |
| `url_launcher` not in package | `ExternalMeetingCallProvider` injects callback | **Pass** ✓ — but not wired |

---

## Missing tests (code quality / safety)

| Target | Expected | Actual | Gap | Severity | Beta blocker |
|--------|----------|--------|-----|----------|--------------|
| `ValidateBookingEligibilityUseCase` | Dedicated unit file | **0** files — only via `booking_bloc_test.dart` mock | Core gate untested at domain level | **P1** | **Y** |
| `MySessionsBloc` join flow | Join → CallProvider | `my_sessions_bloc_test.dart` — no join test | Join path untested | **P0** | **Y** |
| `createSessionBooking` `meeting_link` | Assert field set | CF tests exist; no meeting_link assert per 033 | Contract gap | **P0** | **Y** |
| `session_firestore_mapper` | Unknown status handling | `session_firestore_mapper_test.dart` in app | Partial | **P1** | N |
| `SessionDetailScreen` widget | Join CTA visibility | No widget test file found | UI regression risk | **P1** | N |
| Fake vs Firestore session shape | Parity test | Fake sets `meetingLink`; CF does not | False confidence | **P0** | **Y** |
| Admin sessions component | Component test | None observed | Low priority Beta | **P2** | N |
| E2E book→join | Maestro/emulator | Not evidenced in repo | Manual only | **P1** | **Y** (QA) |

---

## Good testability patterns (keep)

| Pattern | File | Why good |
|---------|------|----------|
| Injectable `now` on dashboard bloc | `teacher_dashboard_bloc.dart` L56–61 | Time travel in tests |
| `CommitTimerFactory` inject | L31–37, L62 | Timer tests without real delay |
| Fake repos in `test/helpers/fakes/` | package test | Prefer fakes over mocks ✓ |
| `bloc_test` for booking | `booking_bloc_test.dart` | Event/state coverage |
| Lifecycle guard tests | `session_lifecycle_guard_test.dart` | Safety matrix covered |
| CF lifecycle unit tests | `functions/test/quranSessions/` | 9 files |

---

## `DateTime.now()` inventory (presentation — highest risk)

| File | Line | Injectable? |
|------|------|-------------|
| `my_sessions_bloc.dart` | 44 | **No** |
| `availability_override_sheet.dart` | 41–42, 175 | Widget state — acceptable |
| `reschedule_session_screen.dart` | 27 | Screen — acceptable |
| `quran_sessions_nav.dart` | 92 | Route builder — **P2** extract |
| `profile_completion_bloc_test.dart` | Uses real now with care | Documented workaround |

---

## Summary

| Severity | Count |
|----------|-------|
| P0 | 4 |
| P1 | 5 |
| P2 | 8 |
| **Total** | **17** |

**Top test debt for Beta:** eligibility use case unit tests + join bloc test + CF `meeting_link` contract + fake/Firestore parity.
