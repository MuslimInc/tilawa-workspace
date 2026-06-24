# Phase 6 Hero Handoff — Session Detail UX Hardening

**Date:** 2026-06-24  
**Parent spec:** [038 stable production release](./README.md)  
**Prior phase:** [Phase 5 — Mobile Reschedule Respond](./final-report.md#phase-5--mobile-reschedule-respond--cf-counterparty-guard-pipeline-55)

---

## Audit — remaining open items

Sourced from [implementation-plan.md](./implementation-plan.md), [production-blockers.md](./production-blockers.md), [production-gap-analysis.md](./production-gap-analysis.md), and Phase 5 closure.

### P0 (release gates — not Phase 6 code)

| ID | Item | Status |
|----|------|--------|
| P0-4 | Manual E2E B1–B5, T2–T8 unsigned | **Open** — user QA |

### P1 (candidates for Phase 6 batch)

| ID | Item | Status | Phase 6? |
|----|------|--------|----------|
| P1-1 | App Check on session CFs | Staged (Phase 4); ops flip pending | **No** — ops deploy |
| P1-2 | RescheduleBloc / dedicated reschedule screen tests | Partially closed (detail + banner) | **No** — out of batch |
| P1-4 | Maestro book→join E2E | Open | **No** |
| P1-5 | CI wire `quran_sessions_preflight.sh` | Open | **No** |
| P1-6 | Feature-scoped Sentry breadcrumbs | Open | **No** |
| P1-7 | Legal privacy (external links + Agora) | Open | **No** — legal |
| P1-10 | Remove experimental home badge | Open | **No** — home scope |

### P2 UX / test debt (Phase 6 batch)

| Item | Source | Notes |
|------|--------|-------|
| Session detail copy: mode/provider locked at booking | implementation-plan Phase 7 | No user-facing explanation today |
| Silent timeline fetch failure | `SessionDetailBloc` swallows `GetSessionTimeline` `Left` → empty list | Users see success with missing audit trail |
| Silent pending-reschedule fetch failure | `_loadRescheduleContext` folds `Left` → `null` request | Counterparty banner may not appear after rules/index lag |
| Preflight / combined widget suite flakiness | qa-release-gates.md | `lifecycle_test_helpers` shared timers; full `flutter test` package occasionally order-dependent |
| ProGuard release APK Agora smoke | Phase 3 blocker | Device-only — parallel user QA |

### Postponed (explicit OUT OF SCOPE for Phase 6)

- Paid/wallet checkout, group sessions, WebRTC signaling
- Mobile teacher mark no-show
- Admin dispute resolve UI
- Bilateral mode/provider change (Option C)
- App Check ops enforcement flip
- Maestro automated E2E
- Home hero / discover carousel experiments (unrelated WIP on branch)

---

## Recommended Phase 6 batch (ONE cohesive scope)

**Title:** Session Detail UX Hardening — locked-at-booking copy + honest fetch failures + lifecycle test stability

**Why one batch:** All three touch `SessionDetailScreen` / `SessionDetailBloc` presentation layer; same test files; same manual E2E surface (session detail). No CF deploy required.

### In scope

1. **Locked-at-booking copy**
   - Add non-interactive info row or footnote on session detail when session is `scheduled`/`confirmed`: mode + call provider chosen at booking; link to help or static copy (Option A policy).
   - l10n EN + AR; tokens only.

2. **Silent fetch failure fix**
   - `GetSessionTimeline` failure → surface `timelineLoadFailed` flag or inline warning (not empty success).
   - `GetPendingRescheduleRequest` failure when lifecycle is `rescheduled` → inline warning or retry affordance; do not silently hide banner.
   - Preserve current behavior for `UnauthorizedFailure` if product intends "no timeline" — document in code comment + test the chosen UX.

3. **Lifecycle test stability**
   - Identify flaky test(s) in `packages/quran_sessions/test/presentation/**` using `lifecycle_test_helpers.dart` (likely `booking_bloc_test`, `my_sessions_bloc_test`, or combined preflight run).
   - Fix root cause (timer leak, missing `pump` bound, shared fake state) — no `skip` without linked issue.

### OUT OF SCOPE

- New CFs or Firestore rules changes
- Reschedule request screen / `RescheduleBloc` new tests
- App Check deploy or env flip
- Agora native join, ProGuard device smoke
- Home dashboard / hero variants
- Maestro flows
- Admin panel changes
- Legal / privacy policy updates

---

## Multi-subagent pipeline

| Step | Agent | Deliverable |
|------|-------|-------------|
| 1 | **Implementer** | Copy widget, bloc state flags, failure surfacing in `session_detail_screen.dart` |
| 2 | **Test Author** | Bloc tests for timeline/reschedule fetch failures; widget test for locked copy + warning banner; stabilize flaky lifecycle test |
| 3 | **Reviewer** | UX gate check (no mock-mute-style deception); `Either` boundaries; l10n |
| 4 | **P1 fix** (if reviewer finds should-fix) | Minimal patch only |
| 5 | **Final gate** | `dart analyze`, targeted tests, preflight; update `final-report.md` Phase 6 section |

**Refactor stage:** Skip unless reviewer flags structural debt.

---

## Acceptance criteria

- [ ] Session detail shows locked-at-booking copy for booked sessions (external/mock/agora labels correct).
- [ ] Timeline fetch failure shows user-visible degraded state (not silent empty success) — behavior documented in test name.
- [ ] Pending reschedule fetch failure when `lifecycleStatus == rescheduled` shows warning or retry — counterparty not blocked silently.
- [ ] Identified flaky lifecycle test runs **10×** locally without failure.
- [ ] No new `coverage:ignore` without justification.
- [ ] `dart analyze` clean on touched paths.
- [ ] All targeted tests pass (commands below).
- [ ] Manual: open session detail → see locked copy; airplane mode toggle → see failure UX (not blank success).

---

## Test commands

```sh
export JAVA_HOME="$(/usr/libexec/java_home -v 21)" 2>/dev/null

cd packages/quran_sessions && flutter test \
  test/presentation/blocs/session_detail_bloc_test.dart \
  test/presentation/screens/session_detail_screen_test.dart \
  test/presentation/blocs/booking_bloc_test.dart \
  test/presentation/blocs/my_sessions_bloc_test.dart

cd packages/quran_sessions && flutter test  # full package — must be green

./scripts/quran_sessions_preflight.sh
```

**Flake hunt (implementer runs before handoff):**

```sh
cd packages/quran_sessions
for i in $(seq 1 10); do flutter test test/presentation/blocs/booking_bloc_test.dart || break; done
```

---

## Success definition

**Phase 6 done = engineering ready for user manual E2E** on session detail:

- User sees why mode/provider cannot change.
- User sees honest errors when sub-fetches fail.
- CI/preflight no longer flaky on lifecycle helpers.
- **User** still runs B1–B5 bilateral reschedule + join smoke from Phase 5 checklist before Play wide release.

---

## Files likely touched

```
packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart
packages/quran_sessions/lib/src/presentation/blocs/session_detail/session_detail_bloc.dart
packages/quran_sessions/lib/src/presentation/blocs/session_detail/session_detail_state.dart
packages/quran_sessions/lib/l10n/intl_en.arb
packages/quran_sessions/lib/l10n/intl_ar.arb
packages/quran_sessions/test/presentation/blocs/session_detail_bloc_test.dart
packages/quran_sessions/test/presentation/screens/session_detail_screen_test.dart
packages/quran_sessions/test/presentation/blocs/booking_bloc_test.dart  (flake fix)
specs/038-quran-session-stable-production-release/final-report.md       (Phase 6 section — final gate)
```

---

## Handoff to parent / user

After Phase 6 pipeline: run **combined manual checklist** (Phase 5 reschedule + Phase 3 Agora if enabled + B1–B5/T2–T8) on staging release build. Engineering does not substitute for sign-off table in [docs/qa/quran_sessions_free_beta_signoff.md](../../docs/qa/quran_sessions_free_beta_signoff.md).
