# Quran Sessions — Current State Audit

**Product:** MeMuslim / أنا مسلم — Quran Sessions  
**Audit date:** 2026-06-23  
**Lineage:** Folder created by prior agents (8a14d307, 5c9e586b); **this pass updated** README gaps + sprint decisions + refreshed code verification (no new files)  
**Scope:** Read-only codebase audit vs `specs/031`, `specs/032`, `specs/030`  
**Method:** Specs read first; every claim verified against source (no `flutter test` / deploy run)

---

## Review roles (lenses only)

These roles frame findings. They do **not** add scope — KISS/YAGNI applies to every recommendation.

| # | Role | Lens | Reject |
|---|------|------|--------|
| 1 | **Principal Product Manager** | User value, Free Beta happiness, smallest shippable slice | Nice-to-have before first real session |
| 2 | **Principal UX Designer** | Simple flows, clear states, RTL trust | Complex UX that delays Beta |
| 3 | **Staff Flutter Engineer** | Working flows, BLoC/DI, UI Kit, testable code | Speculative abstractions in app layer |
| 4 | **Staff Backend Engineer** | Lifecycle integrity, authz, idempotency, safe CF/Firestore | Extra services without a caller |
| 5 | **QA Lead** | Critical paths, emulator/rules, meaningful tests | Fake coverage / untested safety chain |
| 6 | **Security & Safety Reviewer** | Child rules, verification, reports, privacy | Blockers that are not true launch risks |
| 7 | **Release Manager** | Staging, Play internal, rollout, rollback, flags | Production-scale ops before closed Beta |

**Principles on every finding:** KISS · DRY · YAGNI · User happiness first.

**Finding classification:**

| Class | Meaning |
|-------|---------|
| **Must fix before Free Beta** | Users cannot complete book→join or safety fails |
| **Should fix before Free Beta** | Beta works but trust/ops pain high |
| **Can improve after Beta** | Polish, not launch-critical |
| **Postpone to Production** | Explicitly out of Free Beta IN list (`032`) |
| **Postpone to Paid Sessions** | Money movement, PSP, payouts |
| **Remove from Free Beta scope** | Cut to ship faster |

---

## Executive summary

Quran Sessions has **strong domain + backend** (~80% architecture) but **incomplete end-to-end product** for Free Beta (~**56%** overall).

| Layer | % |
|-------|---|
| Domain package | 82% |
| Flutter app wiring | 68% |
| Cloud Functions | 78% |
| Admin panel | 42% |
| E2E user journeys | 48% |
| **Free Beta readiness** | **~56%** |

**What works today (verified):** browse teachers, profile gate, eligibility UI, teacher apply/status, weekly availability, teacher dashboard (auth-aware `_TeacherDashboardGate`), admin approve applications + session list, `createSessionBooking` CF with idempotency, Firestore CF-only writes, package l10n AR/EN, **67** Dart `*_test.dart` files in package + **7** app + **9** CF unit test files.

**What blocks real sessions:** no `meeting_link` on session doc at booking; join handler empty; booking + teacher-apply flags default **off**; mobile report/dispute UI missing; admin reports/disputes queues missing; eligibility use case has **0** dedicated unit tests; staging smoke 10/10 not evidenced.

**Stale doc warning:** `docs/quran_sessions_roadmap.md` (2026-06-21) still claims `student_mvp`, missing `ProfileCompletionBlocTest`, hardcoded `teacher_1`. Code has moved on — use this audit + `032` as truth.

---

## Completion % by layer

See [implementation-status.md](./implementation-status.md) for P0 story mapping (44 P0 stories from `032`).

---

## Top 10 — implemented (verified in code)

| # | Item | Evidence |
|---|------|----------|
| 1 | Profile gate + Firestore profile | `home_sessions_entry_card.dart`, `firestore_user_profile_repository.dart` |
| 2 | Real auth UID (production Firebase module) | `firebase_auth_session_provider.dart`, `requireQuranSessionsUserId` |
| 3 | Teacher list pagination + Firestore | `TeacherListBloc`, `FirestoreTeacherDataSource` |
| 4 | Booking eligibility domain + inline UI | `ValidateBookingEligibilityUseCase`, `booking_screen.dart` |
| 5 | `createSessionBooking` CF + idempotency + slot lock | `createSessionBooking.ts`, `idempotencyService.ts` |
| 6 | Firestore CF-only writes on bookings/sessions | `firestore.rules` L191–206 |
| 7 | Teacher application + admin approve | `teacher_application_screen.dart`, `reviewTeacherApplication.ts`, admin UI |
| 8 | Weekly availability + overrides | `weekly_availability_screen.dart`, `availability_override_sheet.dart` |
| 9 | Teacher dashboard auth-aware | `_TeacherDashboardGate` in `quran_sessions_nav.dart` |
| 10 | Lifecycle guards + policy unit tests | `session_lifecycle_guard.dart`, 67 package test files |

---

## Top 10 — missing or broken

| # | Item | Stories | Evidence |
|---|------|---------|----------|
| 1 | `meeting_link` not written at booking | US-052 | `createSessionBooking.ts` L177–190 — no field |
| 2 | Join handler no-op | US-008, US-031 | `my_sessions_bloc.dart` L96–99 empty `_onJoinRequested` |
| 3 | Session detail — no join/cancel/report | US-014, US-015 | `session_detail_screen.dart` — timeline only |
| 4 | Mobile report concern UI | US-015 | CF `reportSessionConcern` only |
| 5 | Admin reports queue (A-10) | US-040 | No route in `sidebar.component.html` |
| 6 | Admin disputes queue (A-11) | US-041 | CF exists; no admin route |
| 7 | `ValidateBookingEligibilityUseCase` dedicated tests | US-061 | No `validate_booking_eligibility_usecase_test.dart` |
| 8 | ≥5 verified EG teachers seeded | US-034 | Ops — no staging supply evidenced |
| 9 | Booking + teacher-apply flags default off | US-058 | `app_launch_config.dart` defaults `false` |
| 10 | Staging smoke 10/10 + Play internal | US-065, US-068 | Checklist in `032`; not evidenced in repo |

---

## Top 10 — risks

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| 1 | Student books but cannot join | 🔴 Critical | Sprint 5: US-052 + join UI |
| 2 | Eligibility logic untested (12-case matrix) | 🔴 Safety | US-061 before closed Beta |
| 3 | Safety report with no mobile entry | 🔴 Safety | US-015 + A-10 in Sprint 5 |
| 4 | `enforceAppCheck: false` on all session CFs | ⚠️ Prod | Enable before public rollout (Sprint 7) |
| 5 | FCM delivery unproven on device | 🟡 Ops | Staging device test US-055 |
| 6 | Dual `status` + `lifecycleStatus` fields | 🟡 Data | US-060 backfill before prod flag on |
| 7 | Cancel reason min 3 vs spec 20 chars | 🟡 Policy | `cancel_session_sheet.dart` L110 |
| 8 | No teacher supply → empty marketplace | 🔴 Beta | US-034 seed before flag on |
| 9 | Roadmap doc stale misleads team | 🟡 Process | Use `033` + `032` as canonical |
| 10 | Booking flag on without smoke green | 🔴 Ops | US-065 gate before cohort |

---

## Top 10 — tests missing (P0 / high value)

| # | Gap | Story | Priority |
|---|-----|-------|----------|
| 1 | `validate_booking_eligibility_usecase_test.dart` | US-061 | P0 |
| 2 | `session_detail_screen_test.dart` (join CTA) | US-062 | P0 |
| 3 | `booking_screen_test.dart` | US-062 | P1 |
| 4 | `MySessionsBloc` join / CallProvider path | US-008 | P0 |
| 5 | `SessionDetailBloc` test file | — | P1 |
| 6 | `RescheduleBloc` test file | US-011 | P1 |
| 7 | CF integration: `meeting_link` non-null assert | US-052 | P0 |
| 8 | Dedicated Firestore rules suite for quran collections | US-047 | P1 |
| 9 | Widget test for report concern sheet (not built) | US-015 | P0 |
| 10 | E2E smoke script evidence in CI artifact | US-065 | P0 |

---

## Free Beta blockers (Must fix before Free Beta)

| # | Blocker | Stories | Class |
|---|---------|---------|-------|
| 1 | `meeting_link` + join journey | US-052, US-008, US-031 | Must fix |
| 2 | Session detail actions | US-014 | Must fix |
| 3 | Booking + apply flags on staging | US-058, US-006 | Must fix |
| 4 | Teacher supply ≥5 | US-034 | Must fix |
| 5 | Eligibility unit tests | US-061 | Must fix |
| 6 | Report mobile + admin queue | US-015, US-040 | Must fix |
| 7 | Admin disputes queue | US-041 | Must fix |
| 8 | Staging smoke 10/10 | US-065 | Must fix |
| 9 | FCM confirm + T-24h on device | US-009, US-013, US-055 | Should fix (treat as blocker for closed Beta) |
| 10 | Rollback drill | US-072 | Must fix before public rollout |

**True blocker count: 10** (items 1–2 collapse to one join journey for users).

Detail: [free-beta-gap-analysis.md](./free-beta-gap-analysis.md), [go-no-go-summary.md](./go-no-go-summary.md).

---

## Paid Sessions blockers (correctly postponed)

| Item | Status | Evidence |
|------|--------|----------|
| Payment checkout UI (US-P01) | ⏸️ Postponed | No payment sheet in app |
| PSP integration Tap/Stripe (US-P02) | ⏸️ | `DisabledPaymentProvider`, `PAYMENT_PROVIDER_ENABLED=false` |
| Automated refunds (US-P03) | ⏸️ | `approveSessionRefund` blocked in Beta |
| Teacher pricing editor (US-P04) | ⏸️ | No T-12 screen |
| Earnings/payout dashboard (US-P05) | ⏸️ | No T-10 |
| Admin financial ledger UI A-12 (US-P06) | ⏸️ | No ledger route |
| Subscription packages (US-P07) | ⏸️ | Entity only |
| In-app Agora/WebRTC (US-P08) | ⏸️ | `ExternalMeetingCallProvider` sufficient for Beta |
| Paid teacher booking in CF | ✅ Blocked | Smoke #10 `payment_provider_unavailable` |

**Paid verdict: No-Go** — correct; do not unblock until Free Beta metrics pass.

---

## Continuation point

Prior agents (8a14d307, 5c9e586b) created this audit folder **2026-06-23**. This pass **refreshed** findings against live code — key deltas vs stale `docs/quran_sessions_roadmap.md`:

- `ProfileCompletionBloc` tests **exist** (`profile_completion_bloc_test.dart`, ~653 lines)
- Teacher dashboard uses **auth UID** via `_TeacherDashboardGate` (not hardcoded `teacher_1` in prod routes)
- `student_mvp` remains only in **fake MVP module** for dev (`quran_sessions_mvp_module.dart`)

**Resume from:** Sprint 5 in `specs/032-quran-session-delivery-plan/sprint-plan.md` — join + staging flags + supply + eligibility tests.

---

## Go / No-Go table

| Milestone | Verdict | Condition to flip |
|-----------|---------|-------------------|
| Free Beta — code complete | **NO-GO** | US-052 + join + session detail actions |
| Free Beta — staging validation | **CONDITIONAL** | After Sprint 5 code + US-034 seed |
| Free Beta — closed cohort (20 users) | **NO-GO** | Sprint 5–7 exit criteria |
| Free Beta — Play staged rollout | **NO-GO** | US-069 success (Sprint 8) |
| Production GA | **NO-GO** | L10n, guardian, filters deferred per `032` |
| Paid Sessions | **NO-GO** | Postponed — PSP off ✅ |

**Gates passed:** 6/17 · **Partial:** 5/17 · **Failed:** 6/17 (see [go-no-go-summary.md](./go-no-go-summary.md)).

---

## Audit artifacts (15 files)

| # | File |
|---|------|
| 1 | [README.md](./README.md) — this index |
| 2 | [implementation-status.md](./implementation-status.md) |
| 3 | [product-flow-status.md](./product-flow-status.md) |
| 4 | [student-flow-status.md](./student-flow-status.md) |
| 5 | [teacher-flow-status.md](./teacher-flow-status.md) |
| 6 | [admin-flow-status.md](./admin-flow-status.md) |
| 7 | [backend-status.md](./backend-status.md) |
| 8 | [firestore-rules-status.md](./firestore-rules-status.md) |
| 9 | [tests-status.md](./tests-status.md) |
| 10 | [ux-ui-status.md](./ux-ui-status.md) |
| 11 | [performance-status.md](./performance-status.md) |
| 12 | [security-safety-status.md](./security-safety-status.md) |
| 13 | [free-beta-gap-analysis.md](./free-beta-gap-analysis.md) |
| 14 | [recommended-next-sprint.md](./recommended-next-sprint.md) |
| 15 | [go-no-go-summary.md](./go-no-go-summary.md) |

---

## 1. Roles used

All seven roles above applied to every finding in child documents.

---

## 2. Free Beta scope (KISS / DRY / YAGNI)

**IN (from `032`):** free sessions only; external meeting link join; browse/book/cancel; teacher apply + admin approve; weekly availability; profile gate; safety eligibility; report + dispute (minimal); admin sessions + manual_pending ledger; FCM confirm + T-24h reminder; Play internal → closed → staged.

**OUT:** paid checkout, PSP, payouts, Agora/WebRTC, guardian linking UI, OTP phone verify, teacher search/sort/filter chips, public review moderation, EN-only polish as blocker.

---

## 3. What to simplify

| Item | Action | Class |
|------|--------|-------|
| Reschedule mobile E2E | Ship request-only or defer confirm UX to Sprint 6 if capacity tight | Can improve after Beta |
| Dispute compensation types | Beta: `restoreSessionCredit` + `manual_pending` only | Already scoped |
| Teacher dashboard slot toggle | Keep; drop weekly template extras | Good enough |
| Session detail | One screen with join + cancel + report — skip dispute modal v2 | Must fix (join) |
| Notifications | Confirm + T-24h only; skip 1h tier for Beta | Should fix |
| Cancel reason | Align UI min length to policy (20 chars) in one pass | Should fix |
| Admin policy editor | Use Firestore seed + scripts; no A-14 UI for Beta | Remove from Free Beta scope |

---

## 4. What to remove from beta

| Item | Reason |
|------|--------|
| Paid booking UI / `pendingPayment` UX | US-P01 — Paid Sessions |
| Teacher earnings (T-10) | Paid Sessions |
| Filter/search/sort teachers (US-017) | Production per `032` |
| Guardian linking flow | Production before child marketing |
| In-app Agora/WebRTC | Paid / Production optional |
| Admin financial ledger UI (A-12) | Paid Sessions |
| OTP teacher phone verification | ADR-003 deferred |

---

## 5. Good enough for beta

| Item | Evidence |
|------|----------|
| Domain + lifecycle guard | `session_lifecycle_guard.dart`, `sessionLifecycleGuard.ts` |
| Auth UID + profile Firestore | `firebase_auth_session_provider.dart`, `firestore_user_profile_repository.dart` |
| Teacher application + admin approve | `teacher_application_screen.dart`, `reviewTeacherApplication.ts`, admin UI |
| Weekly availability + overrides | `weekly_availability_screen.dart`, schedule repos |
| Free booking CF + idempotency | `createSessionBooking.ts`, `idempotencyService.ts` |
| Cancel CF + sheet (with reason tweak) | `cancel_session_sheet.dart`, `cancelSessionBooking.ts` |
| Package l10n (partial migration OK) | `packages/quran_sessions/l10n/` |
| `ProfileCompletionBloc` tests | `profile_completion_bloc_test.dart` (653 lines) |
| Disabled payment provider | `disabled_payment_provider.dart`, `paymentProviderStatus.ts` |
| MVO admin scripts | `functions/scripts/listPendingTeacherApplications.ts` |

---

## 6. Truly blocking (Must fix before Free Beta)

| # | Blocker | Stories | Files |
|---|---------|---------|-------|
| 1 | `meeting_link` not written at booking | US-052, US-008, US-031 | `createSessionBooking.ts` L177-190 — no field |
| 2 | Join UI no-op | US-008, US-031 | `my_sessions_bloc.dart` L96-99 empty `_onJoinRequested` |
| 3 | Session detail has no join/cancel/report | US-014, US-015 | `session_detail_screen.dart` — timeline only |
| 4 | `quranSessionsBookingEnabled` default false | US-006, US-058 | `app_launch_config.dart`, `quran_sessions_nav.dart` |
| 5 | ≥5 verified EG teachers not seeded | US-034 | Ops + `seedMarketConfigs.ts` / admin approve |
| 6 | `ValidateBookingEligibilityUseCase` 0 dedicated tests | US-061 | No `validate_booking_eligibility_usecase_test.dart` |
| 7 | Mobile report concern UI missing | US-015 | CF `reportSessionConcern` only |
| 8 | Admin reports + disputes queues missing | US-040, US-041 | No routes in `sidebar.component.html` |
| 9 | FCM delivery not E2E verified on device | US-009, US-013, US-026, US-055 | `deliverSessionNotification.ts` coded |
| 10 | Staging smoke 10/10 not evidenced | US-065 | `stagingFreeBetaSmoke.ts` exists; run pending |

**True blocker count: 10** (items 1–3 are one user journey; count separately for tracking).

---

## 7. Exact next sprint

**Sprint 5 — Session join + notifications + booking on staging** (per `032/sprint-plan.md`).

| # | Story | Deliverable |
|---|-------|-------------|
| 1 | US-052 | Add `meeting_link` to `createSessionBooking` from teacher profile or platform default |
| 2 | US-008, US-031 | Wire `ExternalMeetingCallProvider` in `MySessionsBloc` + `session_detail_screen.dart` |
| 3 | US-058 | Enable `quranSessionsBookingEnabled` + `teacherApplicationEnabled` on **staging** build only |
| 4 | US-034 | Seed ≥5 free verified teachers (EG) |
| 5 | US-061 | Add `validate_booking_eligibility_usecase_test.dart` (12 cases) |
| 6 | US-009, US-055 | FCM confirm push E2E on staging device |
| 7 | US-010 | Wire cancel from session detail; align reason min length to 20 chars |

Detail: [recommended-next-sprint.md](./recommended-next-sprint.md).

---

## 8. Smallest path to user hands + Play internal / closed testing

```
1. Staging: flags ON + seed 5 teachers + deploy CF/rules
2. Code: meeting_link + join (2–3 days)
3. Manual: one student books → sees link → opens browser (core team)
4. npm run quran-sessions:staging-smoke (10/10)
5. Signed release AAB → Play **internal** track (core team, US-068)
6. Closed track: 20 trusted users after internal pass (US-069)
```

**Do not** wait for: filter UI, EN l10n complete, reschedule E2E, disputes mobile UI, paid path, Agora.

**Minimum Play internal bar:** book → My Sessions → tap join → external URL opens; admin can approve teacher; one cancel path works.

---

## Upstream references

- Blueprint: `specs/031-quran-session-blueprint/`
- Delivery plan: `specs/032-quran-session-delivery-plan/`
- Domain: `specs/030-quran-sessions-domain/`
- Living roadmap (stale): `docs/quran_sessions_roadmap.md`
