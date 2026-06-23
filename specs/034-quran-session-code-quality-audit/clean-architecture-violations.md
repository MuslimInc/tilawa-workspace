# Clean Architecture Violations — Quran Sessions

**Audit date:** 2026-06-23

Layer model: **Domain** → **Data** (app adapters) → **Presentation** (package screens/blocs)

---

## Dependency direction violations

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| `cloud_firestore` in app data | `firestore_*_repository.dart`, `session_firestore_mapper.dart` | App `data/firebase/` | Correct — not in package presentation | — | — | Keep | — |
| No Firebase in package presentation | Grep: zero matches in `packages/quran_sessions/lib/src/presentation` | — | **Compliant** ✓ | — | — | — | — |
| `getIt` in router | `quran_sessions_nav.dart` | L6–7, L125, L148 | Presentation (app router) → DI container | Route tests need full graph | **P2** | Factory params | N |
| `QuranSessionsMvpStore` in router | `quran_sessions_nav.dart` L13, L280+ | Router reads store for teacher names | App presentation → in-memory fake | Firebase mode uses different path | **P1** | `TeacherNameResolver` interface | N |
| Mapper in app not package | `session_firestore_mapper.dart` | App data layer | Firestore shape not leaked to domain entities directly | **Correct** — aggregate mapped in app | — | Keep | — |
| Domain use cases call repos only | `validate_booking_eligibility_usecase.dart` | — | **Compliant** ✓ | — | — | — | — |
| BLoC calls use cases | `booking_bloc.dart`, `session_detail_bloc.dart` | — | **Compliant** ✓ | — | — | — | — |

---

## Layer leakage (logic in wrong layer)

| Issue | File | Location | Violation | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----------|--------|----------|---------------|--------------|
| Session partition in BLoC | `my_sessions_bloc.dart` | L44–52 | Upcoming/past split by `DateTime.now()` in presentation | Minor — could be view model | **P2** | `SessionListViewModel` or use case | N |
| Scheduling merge in BLoC | `teacher_dashboard_bloc.dart` | L600–780 | Availability merge, booked-slot filter in BLoC | Domain rules mixed with UI undo | **P1** | `TeacherDashboardCoordinator` domain service | N |
| Policy string in widget | `cancel_session_sheet.dart` | L27–34 | Presentation maps policy keys | Acceptable thin mapping | **P2** | Optional l10n extension on policy | N |
| Eligibility duplicated client/server | Dart use case + `bookingEligibilityService.ts` | — | **By design** — not violation if server authoritative | Client must not be only gate | — | Document; add contract test | N |
| CF business logic in handlers | `createSessionBooking.ts` | Inline transaction | No separate domain package in functions | TS norm for Firebase | **P2** | Extract `bookingDomain/` folder | N |

---

## Boundary gaps (missing abstractions)

| Gap | Current | Should be | Severity | Beta blocker |
|-----|---------|-----------|----------|--------------|
| Join session | UI → empty BLoC handler | UI → BLoC → `JoinSessionUseCase` → `CallProvider` | **P0** | **Y** |
| Meeting URL source | Entity field unused | `SessionRepository.getMeetingLink(sessionId)` in use case | **P0** | **Y** |
| Teacher name resolution | Ad-hoc callback in `MySessionsScreen` | `GetTeacherDisplayNameUseCase` or stream | **P2** | N |
| Report/dispute | CF only | `ReportSessionUseCase` + screen (product gap) | **P1** | N (product) |

---

## Package vs app split assessment

| Layer | Package `quran_sessions` | App `tilawa/features/quran_sessions` | Verdict |
|-------|--------------------------|----------------------------------------|---------|
| Entities, use cases, policies | ✓ | — | Correct |
| BLoCs, screens, widgets | ✓ | — | Correct |
| Firestore repos | — | ✓ | Correct |
| Feature flags | — | `quran_sessions_feature_flags.dart` | Correct |
| Router | — | `quran_sessions_nav.dart` | Correct |
| Fake MVP | — | `fake_mvp_*` | Correct for dev |

---

## Admin architecture

| Layer | Location | Verdict |
|-------|----------|---------|
| Domain entities | `apps/tilawa_admin/src/app/core/domain/` | Clean |
| Repositories | `core/data/repositories/firebase-*` | Firebase isolated |
| Facades | `core/application/facades/` | Thin |
| Components | `features/quran-sessions/` | Presentation only — **compliant** |
| Missing | Reports/disputes feature folders | Product gap |

---

## Summary

| Category | P0 | P1 | P2 |
|----------|----|----|-----|
| Dependency violations | 0 | 1 | 1 |
| Layer leakage | 1 | 1 | 3 |
| Boundary gaps | 2 | 1 | 1 |
| **Total issues** | **3** | **3** | **5** |

**Overall:** Architecture is **sound** (~82% per 033). Beta blockers are **wiring gaps** (join/`CallProvider`), not fundamental layer inversion.
