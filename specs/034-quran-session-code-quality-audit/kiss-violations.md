# KISS Violations — Quran Sessions

**Audit date:** 2026-06-23

Over-complexity vs simpler alternatives. Severity: **P0** launch risk · **P1** maintainability · **P2** nice-to-have.

---

| Issue | File | Location | Complexity | Simpler alternative | Severity | Beta blocker |
|-------|------|----------|------------|---------------------|----------|--------------|
| Optimistic slot delete with 5s undo timer | `teacher_dashboard_bloc.dart` | L57, L110–116, L400+ | Timer factory, pending delete map, re-fetch on commit | Direct `blockGeneratedSlot` on tap + snackbar undo (server idempotent) | **P1** | N |
| Dual backend modules (fake + firebase) | `injection.dart` L88–93; `quran_sessions_mvp_module.dart` | Full fake stack ~316 LOC DI | Two parallel repo sets | Single interface; fake only in `test/` and dev flavor | **P1** | N |
| Legacy + lifecycle status dual-write | `createSessionBooking.ts` L172, L187; Dart `quran_session.dart` L54 | Every write sets both | Two fields forever | Beta: write lifecycle only; read fallback in mapper (already exists) | **P2** | N |
| `TeacherDashboardBloc._applyAvailability` | `teacher_dashboard_bloc.dart` | Multiple private helpers ~200 LOC | Re-merges slots, pending deletes, booked filter | Pure function `mergeAvailabilityState(current, slots)` | **P2** | N |
| `session_transition_table.dart` + CF guard | Dart ~295 LOC; TS ~351 LOC | Parallel transition matrices | One source of truth | JSON artifact generated to Dart + TS (post-beta) | **P2** | N |
| `ConfigurableCancellationPolicy.describe` → string key → switch | `cancel_session_sheet.dart` L13–34 | Stringly-typed policy keys | Enum `CancellationPolicyMessage` | **P2** | N |
| `quran_sessions_failure.dart` monolith | ~430 LOC | 40+ failure classes | Sealed hierarchy per subdomain | **P2** | N |
| Reschedule route `extra` map | `quran_sessions_nav.dart` L190–170 | Untyped `Map<String, String>` | Typed `RescheduleRouteArgs` (go_router_builder) | **P2** | N |
| Metrics + ledger in booking CF path | `createSessionBooking.ts` L14; `metricsAggregationService.ts` | Side effects in transaction | Async post-commit queue only | **P2** | N |
| Join: empty handler instead of not showing CTA | `my_sessions_bloc.dart` L96–99; `session_card.dart` L91–96 | UI shows join; handler noop | Hide join until wired OR implement minimal `url_launcher` | **P0** | **Y** |
| `ExternalMeetingCallProvider` (30 LOC) unused while stubs exist | `external_meeting_call_provider.dart` | Simplest join path ready | Wire it — don't build Agora first | **P0** | **Y** |
| Profile completion 723-line single screen | `profile_completion_screen.dart` | Multi-step in one `build` | `PageView` with 3 step widgets | **P1** | N |
| Admin 8-field filter grid per page | `sessions.component.html` L7–53 | 8 inputs inline | Shared filter component with config | **P2** | N |
| `FakeMvpSessionLifecycleStack` | `fake_mvp_session_lifecycle.dart` | ~307 LOC simulating CF | Use emulator + CF for integration tests | **P2** | N |

---

## Acceptable complexity (do not simplify for Beta)

| Area | File | Why OK |
|------|------|--------|
| `bloc_concurrency` transformers | `my_sessions_bloc.dart` L18–21 | Correct race handling for cancel/join |
| `BookingBloc` eligibility-then-slots | `booking_bloc.dart` L62–108 | Clear sequential gate; domain rules in use case |
| `idempotencyService.ts` | CF | Required for safe retries |
| `session_lifecycle_guard.dart` + tests | Domain | Safety-critical; complexity justified |
| `TeacherDashboardBloc` injectable `now` | L56–61 | Good test seam — extend to `MySessionsBloc` |

---

## Summary

| Severity | Count |
|----------|-------|
| P0 | 2 |
| P1 | 3 |
| P2 | 9 |
| **Total** | **14** |
