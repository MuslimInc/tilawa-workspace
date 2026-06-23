# SOLID Violations — Quran Sessions

**Audit date:** 2026-06-23

---

## S — Single Responsibility Principle

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| Teacher dashboard BLoC does 6 jobs | `teacher_dashboard_bloc.dart` | L39–822 | Loads sessions, mutates availability, manages undo timers, Friday banner, cancel, complete | Change to slot delete risks session list | **P1** | Facade or split blocs | N |
| Router file owns navigation policy | `quran_sessions_nav.dart` | L16–43, L350+ | Capability routing + GoRoute tree + `_TeacherDashboardGate` | Hard to test gates independently | **P1** | Extract `TeacherCapabilityNavigator` | N |
| `createSessionBooking` CF | `createSessionBooking.ts` | L54–229 | Eligibility + pricing + idempotency + dual write + audit + metrics | Large transaction script | **P1** | Extract `buildBookingWrites()` pure helper | N |
| `sessionDisputeCallables.ts` | same dir | ~354 LOC | Multiple dispute operations | Same | **P1** | One callable per file | N |

---

## O — Open/Closed Principle

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| Lifecycle status badge switch | `session_card.dart` | L123–150 | New `QuranSessionStatus` requires editing switch | Missed UI on new status | **P2** | Map status → style record | N |
| `legacyStatusForLifecycle` default | `sessionLifecycleService.ts` | L44–45 | `default: return "pending"` for unknown lifecycle | Silent legacy drift | **P1** | Throw on unknown status in strict mode | N |
| `parseLifecycleStatus` orElse | `session_firestore_mapper.dart` | L16–18 | Unknown Firestore value → `scheduled` | Wrong UI state | **P1** | Log + `unknown` failure type | N |
| Paid pricing branch in eligibility | `validate_booking_eligibility_usecase.dart` | L98–110 | `if (teacher.pricingType != free)` inline | OK for now; grows with PSP | **P2** | `PricingEligibilityPolicy` injectable | N (Y paid) |

---

## L — Liskov Substitution Principle

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| Stub call providers throw | `agora_call_provider.dart` | L22–33 | `joinSession` → `UnimplementedError` | Crash if mis-wired in DI | **P1** | No-op stub or fail at registration | N |
| `WebRtcCallProvider` same | `web_rtc_call_provider.dart` | L24–35 | Same | Same | **P1** | Same | N |
| `FakeMvpBookingRepository` vs Firestore | `fake_mvp_booking_repository.dart` | L67 | Fake always sets `meetingLink` | Tests pass; prod fails — behavioral divergence | **P0** | Contract test: session doc shape parity | **Y** |

---

## I — Interface Segregation Principle

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| `SessionMutationGateway` surface | `firebase_session_mutation_gateway.dart` | ~247 LOC | Single gateway for cancel, complete, reschedule, report, … | Consumers depend on full API | **P2** | Role-specific gateways if callers grow | N |
| `TeacherDashboardBloc` constructor | `teacher_dashboard_bloc.dart` | L41–56 | 11 required deps | Test setup heavy (mitigated by fakes) | **P2** | Dashboard facade use case | N |
| Admin facades | `sessions.facade.ts`, `teacher-applications.facade.ts` | — | List + detail + mutations in one facade each | Acceptable for admin MVP | **P2** | Split when reports/disputes added | N |

---

## D — Dependency Inversion Principle

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| **Good:** Presentation uses use cases | `booking_bloc.dart`, `session_detail_bloc.dart` | — | No Firestore in package presentation | Testable | — | Keep | — |
| **Good:** Boundaries for call/payment | `call_provider.dart`, `payment_provider.dart` | — | App injects implementations | Swappable | — | Wire `CallProvider` in app | **Y** |
| Firebase in app data only | `firestore_*_repository.dart` | — | Correct layer | — | — | Keep | — |
| `MySessionsBloc` missing `CallProvider` | `my_sessions_bloc.dart` | L11–22 | High-level module depends on nothing for join | Join not abstracted | **P0** | Inject `CallProvider` + `SessionRepository` | **Y** |
| `quran_sessions_nav` calls `getIt` directly | `quran_sessions_nav.dart` | L125, L148 | Presentation routing knows service locator | Hard to test routes | **P2** | Pass dependencies via route `extra` or parent | N |
| `MvpStore` singleton | `quran_sessions_mvp_store.dart` | L247+ | Global mutable state for fake backend | Fake/prod behavioral gap | **P1** | Keep for dev; document parity checklist | N |

---

## Summary

| Principle | P0 | P1 | P2 |
|-----------|----|----|-----|
| SRP | 0 | 4 | 0 |
| OCP | 1 | 2 | 2 |
| LSP | 1 | 2 | 0 |
| ISP | 0 | 0 | 3 |
| DIP | 1 | 1 | 2 |
| **Total** | **3** | **9** | **7** |
