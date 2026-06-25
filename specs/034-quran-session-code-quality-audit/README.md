# Quran Sessions — Code Quality Audit

**Product:** MeMuslim / أنا مسلم — Quran Sessions  
**Audit date:** 2026-06-23  
**Type:** Code quality (not blueprint) — read-only review of **actual source**  
**Lineage:** `specs/031` (blueprint), `specs/032` (delivery), `specs/033` (current state)  
**Method:** Source read + grep + line counts; no `flutter test` run this pass

---

## Index

| # | Document | Issues |
|---|----------|--------|
| 1 | [clean-code-violations.md](./clean-code-violations.md) | 23 |
| 2 | [atomic-design-violations.md](./atomic-design-violations.md) | 12 findings |
| 3 | [solid-violations.md](./solid-violations.md) | 19 |
| 4 | [kiss-violations.md](./kiss-violations.md) | 14 |
| 5 | [dry-violations.md](./dry-violations.md) | 7 |
| 6 | [yagni-violations.md](./yagni-violations.md) | 18 |
| 7 | [clean-architecture-violations.md](./clean-architecture-violations.md) | 11 |
| 8 | [ui-kit-design-system-violations.md](./ui-kit-design-system-violations.md) | 26 |
| 9 | [testability-violations.md](./testability-violations.md) | 17 |
| 10 | [risk-priority-matrix.md](./risk-priority-matrix.md) | 30 ranked |
| 11 | [recommended-refactor-plan.md](./recommended-refactor-plan.md) | 4 phases |

---

## Executive summary

Quran Sessions code is **architecturally sound** for a beta: domain package, use-case-driven BLoCs, Firebase isolated to app `data/`, boundaries for call/payment, 67+ package tests, CF lifecycle guards. **Code quality does not block architecture** — it blocks **one user journey**: **join**.

| Lens | Grade | Notes |
|------|-------|-------|
| Clean Architecture | **B+** | Layer direction correct; join wiring gap |
| SOLID | **B** | God bloc/screen; DIP good except join |
| Clean Code | **B−** | Large files; one empty handler (critical) |
| KISS | **B−** | Dual backend + dashboard undo complexity OK but heavy |
| DRY | **B+** | Few real duplicates; lifecycle Dart/TS intentional |
| YAGNI | **A−** | Paid/ledger/dispute mostly gated; stubs not registered |
| UI Kit | **C+** | Booking/availability good; sessions list raw Material |
| Testability | **B−** | Strong lifecycle tests; eligibility + join gaps |
| Atomic Design | **C** | Large screens; good widget extractions exist |
| **Free Beta (code lens)** | **NO-GO** | Join path incomplete |

**Overall code quality:** ~**72%** — shippable after **Phase 1** (~1 sprint) fixes, not a rewrite.

---

## Issue counts by severity

| Severity | Count (deduped across lenses) | Free Beta blockers |
|----------|-------------------------------|-------------------|
| **P0** | 8 | 6 |
| **P1** | 24 | 1 (eligibility tests) |
| **P2** | 38 | 0 |
| **Total tracked** | **~70** | **6–7** |

*Same root cause (e.g. join) appears in multiple lenses — matrix [risk-priority-matrix.md](./risk-priority-matrix.md) dedupes to 30 IDs.*

---

## Top 10 — Clean Code

| # | Issue | File:lines |
|---|-------|------------|
| 1 | Empty join handler | `my_sessions_bloc.dart:96–99` |
| 2 | `TeacherDashboardBloc` ~822 LOC | `teacher_dashboard_bloc.dart` |
| 3 | `TeacherDashboardScreen` ~1011 LOC | `teacher_dashboard_screen.dart` |
| 4 | `ProfileCompletionScreen` ~723 LOC | `profile_completion_screen.dart` |
| 5 | `WeeklyAvailabilityScreen` ~876 LOC | `weekly_availability_screen.dart` |
| 6 | Review failure swallowed | `my_sessions_bloc.dart:114–116` |
| 7 | Session detail no join UI | `session_detail_screen.dart:37–75` |
| 8 | Router god file ~464 LOC | `quran_sessions_nav.dart` |
| 9 | Timeline raw enum names | `session_detail_screen.dart:63` |
| 10 | Hardcoded cancel pricing `free` | `my_sessions_screen.dart:178` |

---

## Top 10 — Atomic Design

| # | Issue | File |
|---|-------|------|
| 1 | Dashboard screen should be 4–5 organisms | `teacher_dashboard_screen.dart` |
| 2 | Missing `SessionJoinActions` molecule | (not extracted) |
| 3 | Missing `SessionTimelineTile` | `session_detail_screen.dart` |
| 4 | `SessionCard` is good shared molecule | `session_card.dart` ✓ |
| 5 | Weekly availability should split override flow | `weekly_availability_screen.dart` |
| 6 | Profile wizard needs step organisms | `profile_completion_screen.dart` |
| 7 | Admin filter bar duplicated | `sessions.component.html`, `teacher-applications.component.html` |
| 8 | `SessionCard` uses `Card` not `TilawaCard` | `session_card.dart:38` |
| 9 | Debug panel organism in prod screen | `teacher_application_status_screen.dart:305–342` |
| 10 | `QuranSessionsStudentEmptyState` well-factored | `quran_sessions_student_empty_state.dart` ✓ |

---

## Top 10 — SOLID

| # | Issue | Principle |
|---|-------|-----------|
| 1 | `TeacherDashboardBloc` 6 responsibilities | SRP |
| 2 | Join not behind `CallProvider` in bloc | DIP |
| 3 | Fake booking always has `meetingLink`; CF does not | LSP |
| 4 | Agora/WebRTC throw if miswired | LSP |
| 5 | `legacyStatusForLifecycle` default `"pending"` | OCP |
| 6 | `parseLifecycleStatus` → `scheduled` fallback | OCP |
| 7 | Router mixes routes + gates + nav policy | SRP |
| 8 | `createSessionBooking` monolithic transaction | SRP |
| 9 | Presentation → use cases (booking, detail) | DIP ✓ |
| 10 | `SessionMutationGateway` wide interface | ISP (minor) |

---

## Top 10 — KISS

| # | Issue | Simpler path |
|---|-------|--------------|
| 1 | Join: noop handler vs wire 30-line `ExternalMeetingCallProvider` | Wire provider |
| 2 | Dual fake + firebase DI modules | Fake test-only |
| 3 | Optimistic slot delete + 5s timer | Direct server block |
| 4 | Legacy + lifecycle dual-write | Lifecycle-only writes |
| 5 | Parallel Dart/TS transition tables | Codegen later |
| 6 | Policy describe → string → switch | Enum messages |
| 7 | `quran_sessions_failure.dart` monolith | Split files |
| 8 | Untyped reschedule `extra` map | Typed route args |
| 9 | `bloc_concurrency` on cancel/join | Keep — justified |
| 10 | Idempotency in CF | Keep — justified |

---

## Top 10 — DRY

| # | Duplication | Files |
|---|-------------|-------|
| 1 | Specialization ID lists | `teacher_application_screen.dart`, `complete_teacher_public_profile_screen.dart` |
| 2 | Lifecycle parse (3 places) | Dart mapper, legacy mapper, TS service |
| 3 | Admin filter HTML | sessions + teacher-applications components |
| 4 | Admin loading/error template | same |
| 5 | Firestore datetime readers | `session_firestore_mapper`, `firestore_exception_mapper` |
| 6 | Client/server eligibility | Intentional — do not merge |
| 7 | Cancel sheet | Already shared ✓ |
| 8 | `SessionCard` | Already shared ✓ |
| 9 | Friday banner widget | Extracted ✓ |
| 10 | MVP vs Firebase repos | Do not merge implementations |

---

## Top 10 — YAGNI

| # | Feature | Verdict |
|---|---------|---------|
| 1 | `ExternalMeetingCallProvider` built but unwired | **Wire** (not YAGNI — needed) |
| 2 | Agora/WebRTC providers | Hide — not in DI |
| 3 | `financialLedgerService.ts` | Postpone paid |
| 4 | `IssueCompensationUseCase` | Keep; no UI |
| 5 | Report/dispute CFs | Postpone UI |
| 6 | Paid CF branch | Keep; server-gated |
| 7 | `DisabledPaymentProvider` | Keep |
| 8 | Metrics aggregation | Keep; low cost |
| 9 | Debug panel on application status | Hide `kDebugMode` |
| 10 | Fake MVP module | Keep for dev flavor |

---

## Top 10 — Clean Architecture

| # | Finding | Verdict |
|---|---------|---------|
| 1 | No Firebase in package presentation | ✓ Pass |
| 2 | Firestore mappers in app data | ✓ Pass |
| 3 | BLoCs use use cases | ✓ Pass |
| 4 | Join missing use case + provider wire | ✗ P0 |
| 5 | `getIt` in router | P2 leak |
| 6 | MvpStore in router for names | P1 leak |
| 7 | Eligibility client + server | By design |
| 8 | Scheduling logic in dashboard BLoC | P1 leak |
| 9 | Admin facades clean | ✓ Pass |
| 10 | Package/app split | ✓ Pass |

---

## Top 10 — UI Kit / Design System

| # | Issue | File |
|---|-------|------|
| 1 | No join on session detail | `session_detail_screen.dart` |
| 2 | Raw `ElevatedButton` retry | `my_sessions_screen.dart:77` |
| 3 | Raw buttons on `SessionCard` | `session_card.dart:84–96` |
| 4 | `Card` vs `TilawaCard` | `session_card.dart:38` |
| 5 | Amber debug `Colors.*` | `teacher_application_status_screen.dart` |
| 6 | Hardcoded `EdgeInsets` in sessions | `my_sessions_screen.dart` |
| 7 | Avatar hex colors | `teacher_initials_avatar.dart:75–81` |
| 8 | Cancel sheet raw buttons | `cancel_session_sheet.dart` |
| 9 | Booking screen `TilawaButton` | ✓ `booking_screen.dart` |
| 10 | Weekly availability `TilawaCard` | ✓ `weekly_availability_screen.dart:751` |

---

## Top 10 — Testability

| # | Issue | File |
|---|-------|------|
| 1 | No `ValidateBookingEligibilityUseCase` unit file | domain use cases |
| 2 | No join test in `MySessionsBloc` | `my_sessions_bloc_test.dart` |
| 3 | CF no `meeting_link` assert | `createSessionBooking` tests |
| 4 | Fake vs CF session shape mismatch | `fake_mvp_booking_repository.dart:67` |
| 5 | `MySessionsBloc` no injectable `now` | vs dashboard bloc L56 |
| 6 | Review failure not assertable | `my_sessions_bloc.dart:114` |
| 7 | `getIt` in routes | `quran_sessions_nav.dart` |
| 8 | Global MvpStore singleton | `quran_sessions_mvp_store.dart` |
| 9 | Lifecycle guard well tested | ✓ |
| 10 | 67 package + 9 CF tests | ✓ baseline |

---

## Free Beta blockers (code quality lens)

| # | Blocker | Evidence | Sprint |
|---|---------|----------|--------|
| 1 | Join handler empty | `my_sessions_bloc.dart:96–99` | 5 |
| 2 | `meeting_link` not written at create | `createSessionBooking.ts:177–190` | 5 |
| 3 | `CallProvider` not in app DI | `quran_sessions_firebase_module.dart` — no registration | 5 |
| 4 | Session detail missing join | `session_detail_screen.dart` — no link/CTA | 5 |
| 5 | Fake/CF parity on meeting URL | Fake sets link; CF does not | 5 |
| 6 | Eligibility use case untested | 0 dedicated `*_test.dart` | 5 |

*Feature flags default off (`quran_sessions_feature_flags.dart`) — product/config blocker, not code structure.*

---

## Good enough for Beta

| Area | Why OK |
|------|--------|
| Domain + lifecycle guard + transition tests | Safety chain tested |
| `BookingBloc` + eligibility use case structure | Correct layering |
| `createSessionBooking` idempotency + slot lock | CF quality good |
| Firebase only in app `data/` | Clean arch held |
| Package AR/EN l10n | Core strings present |
| `TilawaButton` on booking / teacher apply | Critical flows styled |
| `SessionCard` shared molecule | Reuse across student/teacher |
| `ExternalMeetingCallProvider` | Simple join — ready to wire |
| Admin list + application review | Thin facades, works for ops |
| YAGNI gating on paid (`DisabledPaymentProvider`, CF assert) | Paid path blocked server-side |
| 67 package tests | Above average for feature size |

---

## Postpone list

| Item | When | Lens |
|------|------|------|
| Split `TeacherDashboardScreen` / bloc | After Beta | Atomic, SRP |
| UI Kit pass on sessions list | Sprint 7 | UI Kit |
| Admin shared filter component | Sprint 7 | DRY |
| Legacy `status` field removal | Production | KISS |
| Dart/TS lifecycle codegen | Production | DRY |
| Financial ledger admin UI | Paid | YAGNI |
| Agora / WebRTC in-app call | V2+ | YAGNI |
| App Check on callables | Production | Security |
| `quran_sessions_failure` file split | After Beta | KISS |
| Consolidate fake backend to tests only | After Beta | KISS |

---

## Recommended next refactor sprint

**Sprint 5 — Phase 1 only** ([recommended-refactor-plan.md](./recommended-refactor-plan.md)):

1. CF: populate `meetingLink` on session doc at create (teacher URL source TBD).
2. DI: register `ExternalMeetingCallProvider` + `url_launcher`.
3. Bloc: implement `_onJoinRequested` → fetch link → launch.
4. UI: join CTA on `SessionDetailScreen` when link present.
5. Tests: eligibility use case, join bloc, CF meeting field contract.

**Estimated effort:** 3–5 dev-days. **Not** a large refactor — wiring + tests.

---

## Go / No-Go — Free Beta (code quality lens)

| Verdict | **NO-GO** |
|---------|-----------|
| Reason | Join journey broken at 3 layers: CF data, bloc handler, detail UI. `CallProvider` exists but not connected. |
| After Phase 1 | **Conditional GO** — architecture supports Beta; remaining P1/P2 is polish and safety UI (reports). |
| Paid sessions | **NO-GO** (unchanged) — ledger, PSP, cancel pricing hardcode; correct for scope. |

---

## Code hotspots (quick reference)

| File | LOC | Role |
|------|-----|------|
| `teacher_dashboard_screen.dart` | ~1011 | Largest screen |
| `teacher_dashboard_bloc.dart` | ~822 | Largest bloc |
| `weekly_availability_screen.dart` | ~876 | Schedule UI |
| `profile_completion_screen.dart` | ~723 | Student gate |
| `quran_sessions_nav.dart` | ~464 | App routes |
| `createSessionBooking.ts` | ~229 | Booking CF |
| `sessionDisputeCallables.ts` | ~354 | Largest CF module |
| `quran_sessions_failure.dart` | ~430 | Failure types |

---

## Alignment with 033

This audit **confirms** 033 product findings from a **maintainability** angle:

- Join no-op + missing `meeting_link` = **P0 code debt**, not just missing feature tick.
- Architecture % (~82%) vs journey % (~48%) gap = **wiring/UI**, not domain rewrite.
- Eligibility test gap = **real regression risk** independent of UX.

Use **034** for sprint planning code tasks; **033** for product Go/No-Go and ops.
