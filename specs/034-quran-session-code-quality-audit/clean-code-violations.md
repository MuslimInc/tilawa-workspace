# Clean Code Violations — Quran Sessions

**Audit date:** 2026-06-23  
**Scope:** `packages/quran_sessions/`, `apps/tilawa/lib/features/quran_sessions/`, `functions/src/quranSessions/`, `apps/tilawa_admin/…/quran-sessions/`

Format: Issue | File | Location | Why | Impact | Severity | Suggested fix | Free Beta blocker

---

## P0 — Must fix for real sessions

| Issue | File | Location | Why | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----|--------|----------|---------------|--------------|
| Empty join handler | `packages/quran_sessions/lib/src/presentation/blocs/my_sessions/my_sessions_bloc.dart` | L96–99 | `_onJoinRequested` body is `{}` — event wired from UI but swallowed | Join CTA does nothing; dead code path confuses QA | **P0** | Inject `CallProvider`; load `meetingLink`; launch URL; emit join failure state | **Y** |
| Session detail has no join / link | `packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart` | L37–75 | Screen shows status + timeline only; no `meetingLink`, no CTA | Student/teacher cannot join from detail (US-008) | **P0** | Add join row when `lifecycleStatus` joinable + link non-null | **Y** |
| CF omits `meeting_link` on session doc | `functions/src/quranSessions/createSessionBooking.ts` | L177–190 | `tx.set(sessionRef, …)` writes lifecycle fields but no `meetingLink` / `meeting_link` | Join has nothing to open even after handler fixed | **P0** | Resolve teacher external URL at create; persist on session doc | **Y** |
| `CallProvider` not registered in app DI | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_firebase_module.dart` | L34–99 | `ExternalMeetingCallProvider` exists + tested but never wired into `GetIt` or `MySessionsBloc` | Join plumbing incomplete end-to-end | **P0** | Register provider; pass to bloc constructor | **Y** |

---

## P1 — High maintainability / trust risk

| Issue | File | Location | Why | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----|--------|----------|---------------|--------------|
| God BLoC | `packages/quran_sessions/lib/src/presentation/blocs/teacher_dashboard/teacher_dashboard_bloc.dart` | L39–822 (~822 LOC) | Single class: sessions, availability CRUD, undo timers, Friday banner, cancel/complete | Hard to reason about; high regression risk on slot delete | **P1** | Split: `TeacherSessionsBloc` + `TeacherAvailabilityBloc` or extract slot-delete coordinator | N |
| God screen | `packages/quran_sessions/lib/src/presentation/screens/teacher_dashboard_screen.dart` | ~1011 LOC | Build method + many private widgets in one file | Review fatigue; hard to test widgets in isolation | **P1** | Extract organisms: session list, availability panel, banner | N |
| God screen | `packages/quran_sessions/lib/src/presentation/screens/profile_completion_screen.dart` | ~723 LOC | Multi-step form + validation UI in one stateful widget | Same | **P1** | Step widgets per section | N |
| God screen | `packages/quran_sessions/lib/src/presentation/screens/weekly_availability_screen.dart` | ~876 LOC | Schedule + overrides + vacation in one screen | Same | **P1** | Split override/vacation into routed sub-screens | N |
| Mega failure type | `packages/quran_sessions/lib/src/domain/failures/quran_sessions_failure.dart` | ~430 LOC | Dozens of failure classes in one library | Navigation noise; merge conflicts | **P1** | Group by subdomain files (`booking_failures.dart`, …) | N |
| Silent review failure | `packages/quran_sessions/lib/src/presentation/blocs/my_sessions/my_sessions_bloc.dart` | L114–116 | `result.fold((_) => null, …)` swallows review errors | User thinks review saved | **P1** | Emit `reviewFailure` on left branch | N |
| Router god file | `apps/tilawa/lib/features/quran_sessions/router/quran_sessions_nav.dart` | ~464 LOC | Routes + `_TeacherDashboardGate` + capability navigation + teacher name resolver | Mixed concerns; hard to find route | **P1** | Split `quran_sessions_routes.dart` / `quran_sessions_gates.dart` | N |
| Timeline shows raw enum names | `packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart` | L61–63 | `Text(event.action.name)` — not localized | Poor UX for AR users | **P1** | Map `SessionAction` → l10n keys | N |
| Hardcoded cancel pricing | `packages/quran_sessions/lib/src/presentation/screens/my_sessions_screen.dart` | L178 | `pricingType: SessionPricingType.free` always | Wrong policy copy when paid enabled later | **P1** | Pass `session.pricingType` from entity | N (Y for paid) |
| `throw StateError` after fold | `packages/quran_sessions/lib/src/domain/usecases/validate_booking_eligibility_usecase.dart` | L44, L67, L89 | `fold((_) => throw StateError(''), …)` | Unreachable in theory; crashes if invariant breaks | **P1** | Early return with `Left` or use `getOrElse` pattern | N |
| CF handler size | `functions/src/quranSessions/sessionDisputeCallables.ts` | ~354 LOC | Multiple callables + validation in one module | Hard to test in isolation | **P1** | One export per file | N |
| CF handler size | `functions/src/quranSessions/sessionLifecycleGuard.ts` | ~351 LOC | Large transition matrix inline | Duplication risk vs Dart `session_transition_table.dart` | **P1** | Shared JSON schema or codegen (post-beta) | N |

---

## P2 — Polish / tech debt

| Issue | File | Location | Why | Impact | Severity | Suggested fix | Beta blocker |
|-------|------|----------|-----|--------|----------|---------------|--------------|
| Long method chain in load | `packages/quran_sessions/lib/src/presentation/blocs/my_sessions/my_sessions_bloc.dart` | L44–52 | Upcoming/past split + sort inline in handler | Minor SRP breach | **P2** | Extract `partitionSessionsByNow(sessions, now)` pure fn | N |
| Magic horizon 14 days | `apps/tilawa/lib/features/quran_sessions/router/quran_sessions_nav.dart` | L97 | `Duration(days: 14)` in route builder | Drifts from market config | **P2** | Use `SchedulingPolicyResolver` or config | N |
| Magic min reason length | `packages/quran_sessions/lib/src/presentation/widgets/cancel_session_sheet.dart` | L110 | `reason.length < 3` | Undocumented rule | **P2** | Named constant + l10n if shown | N |
| Commit delay magic number | `packages/quran_sessions/lib/src/presentation/blocs/teacher_dashboard/teacher_dashboard_bloc.dart` | L57, L110 | `_commitDelay = Duration(seconds: 5)` | Undocumented UX constant | **P2** | Config or documented constant | N |
| Admin inline Tailwind duplication | `apps/tilawa_admin/…/sessions/sessions.component.html` | L7–63 | Filter grid markup copy-pasted | Drift between list screens | **P2** | Shared `FilterBarComponent` | N |
| Admin hardcoded English | `apps/tilawa_admin/…/sessions/sessions.component.html` | L68–72 | "Loading sessions…", button labels | i18n gap (admin EN-only OK for beta) | **P2** | i18n when admin localizes | N |
| `enforceAppCheck: false` | `functions/src/quranSessions/createSessionBooking.ts` | L55 | Callable without App Check | Security posture note | **P2** | Enable on staging before prod | N (Y prod) |

---

## Summary counts

| Severity | Count |
|----------|-------|
| P0 | 4 |
| P1 | 12 |
| P2 | 7 |
| **Total** | **23** |
