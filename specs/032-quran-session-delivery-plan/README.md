# Quran Sessions — Execution & Delivery Plan

**Project:** MeMuslim / أنا مسلم — Quran Sessions (Tilawa workspace)  
**Plan ID:** `032-quran-session-delivery-plan`  
**Created:** 2026-06-23  
**Status:** Canonical delivery artifact — **no code changes implied**  
**Upstream blueprint:** [specs/031-quran-session-blueprint/](../031-quran-session-blueprint/README.md)  
**Domain spec:** [specs/030-quran-sessions-domain/](../030-quran-sessions-domain/spec.md)  
**Living tracker:** [docs/quran_sessions_roadmap.md](../../docs/quran_sessions_roadmap.md)

---

## Executive summary

Quran Sessions is MeMuslim's 1:1 Quran tutoring marketplace. The Tilawa workspace has **~60% product surface** and **~85% backend-agnostic domain** shipped, but Free Beta is blocked by: booking flag off (`quranSessionsBookingEnabled: false`), missing meeting-link UX, incomplete cancel/reschedule/report/dispute UI, FCM delivery gap, and admin reports/disputes queues.

This delivery plan translates blueprint `031` into **9 sprints (0–8)**, **5 epics**, **72 user stories**, and release/rollback/QA artifacts for a **small team or solo developer**.

| Dimension | Current | Free Beta target |
|-----------|---------|------------------|
| Booking writes | CF exists; flag off | Staging → prod with ≥5 teachers |
| Session lifecycle | Domain guard + CF shipped | E2E wired in app |
| Admin ops | Partial Angular panel | Sessions + reports + disputes |
| Payments | `DisabledPaymentProvider` | **Off** — manual_pending only |
| Notifications | Outbox schema; no FCM wire | Confirm + T-24h reminder |

**Recommendation:** **Conditional Go** for Free Beta after Sprint 7 staging smoke 10/10. **No-Go** for paid sessions until PSP + refund automation (post-Sprint 8).

---

## Plan index

| # | Document | Purpose |
|---|----------|---------|
| 1 | [README.md](./README.md) | Index, scope, Go/No-Go, metrics |
| 2 | [epics.md](./epics.md) | Five epics with goals and story map |
| 3 | [user-stories.md](./user-stories.md) | 72 implementable stories (US-001–US-072) |
| 4 | [sprint-plan.md](./sprint-plan.md) | Sprints 0–8 with goals, stories, exit criteria |
| 5 | [acceptance-criteria.md](./acceptance-criteria.md) | Given/When/Then for core flows |
| 6 | [definition-of-done.md](./definition-of-done.md) | Product, engineering, backend, QA, release DoD |
| 7 | [technical-dependencies.md](./technical-dependencies.md) | Dependency graph, services, team |
| 8 | [qa-test-plan.md](./qa-test-plan.md) | Device matrix, test layers, sign-off |
| 9 | [beta-testing-plan.md](./beta-testing-plan.md) | Internal + trusted users, metrics, stop conditions |
| 10 | [release-checklist.md](./release-checklist.md) | Staging deploy, prod gates, changelog |
| 11 | [google-play-release-plan.md](./google-play-release-plan.md) | Play rollout, notes, monitoring |
| 12 | [rollback-plan.md](./rollback-plan.md) | Flag, config, CF, rules, Play halt |
| 13 | [risk-register.md](./risk-register.md) | Risks, severity, mitigation, owners |
| 14 | [implementation-order.md](./implementation-order.md) | Dependency-aware execution sequence |

---

## Free Beta scope (explicit)

### Included

| Area | Scope |
|------|-------|
| Teachers | Verified public profiles; admin approval via `apps/tilawa_admin` + `reviewTeacherApplication` CF |
| Sessions | **Free only** (`pricingType: free`); browse, book, join via external meeting link |
| Scheduling | Teacher weekly availability + overrides; 14-day slot window; basic reschedule (1×, >24h) |
| Lifecycle | Cancel (student/teacher/admin), no-show (system job + teacher mark), complete |
| Safety | Profile gate, gender/age eligibility, report concern, open dispute (post-terminal) |
| Admin | Approve teachers, inspect sessions/bookings, reports queue, disputes queue, manual_pending ledger records |
| Compensation | Session credit / `manual_pending` records only — **no real money movement** |
| Notifications | Booking confirmation + T-24h reminder (FCM) |
| Release | Google Play internal → closed → staged rollout |

### Not included

| Area | Deferred to |
|------|-------------|
| Paid sessions, PSP checkout, `pendingPayment` UX | Paid Sessions phase |
| Teacher payouts, earnings screen, automated refunds | Paid Sessions phase |
| Subscriptions, group sessions | Future |
| In-app Agora/WebRTC calls | Production optional / Paid |
| Public reviews with moderation | Production (if moderation not ready) |
| Guardian linking flow | Production (before child marketing) |
| OTP teacher phone verification | ADR-003 deferred |
| Complex teacher ranking/search/sort | Production nice-to-have |

---

## Production scope (post–Free Beta)

Free sessions in production with monitoring, EN l10n complete, guardian flow (if child users targeted), teacher no-show UI, filter bar, Maestro smoke in CI, 7-day Beta soak metrics review, Sentry CF alerts, ops runbook signed.

**Still free-only** until Paid Sessions phase completes.

---

## Paid Sessions scope (postponed)

PSP integration (Tap/Stripe EG), `PaymentProvider` implementation, `pendingPayment` soft lock, paid booking in `createSessionBooking`, automated refund on early cancel, teacher pricing self-serve, payout batch job, admin financial ledger UI (A-12), commission calculation, PCI scope review.

All Paid stories in [user-stories.md](./user-stories.md) marked **Release: Paid Sessions — postponed**.

---

## Go / No-Go — Free Beta

| Gate | Required | Current |
|------|----------|---------|
| Blueprint `031` approved | Yes | ⬜ Sprint 0 |
| Scope frozen (this plan) | Yes | ⬜ Sprint 0 |
| State machine locked | Yes | ✅ domain shipped |
| Staging smoke 10/10 | Yes | ⬜ Sprint 7 |
| `flutter test packages/quran_sessions` green | Yes | ~green |
| `npm run test:integration` + `test:rules` green | Yes | ⬜ verify |
| ≥5 approved public teachers (EG) | Yes | ⬜ seed Sprint 2 |
| `meetingLink` visible in app | Yes | ⬜ Sprint 5 |
| Booking flag on staging | Yes | ⬜ Sprint 4 |
| FCM confirm + T-24h | Yes | ⬜ Sprint 5 |
| Admin reports + disputes tested | Yes | ⬜ Sprint 6 |
| Payment provider | **Must be off** | ✅ disabled |
| Kill switch drill | Yes | ⬜ Sprint 7 |

**Verdict:** **Conditional No-Go** today. **Conditional Go** after Sprint 7 exit criteria met.

---

## Final report metrics (track at Beta close)

| Metric | Target | Source |
|--------|--------|--------|
| Booking success rate | >95% | CF metrics / Sentry |
| Session completion rate | >80% | `quran_sessions` lifecycle |
| Teacher cancel rate | <10% | admin metrics |
| Dispute rate | <3% | disputes collection |
| Median dispute resolution | <48h | admin SLA |
| Staging smoke | 10/10 | [production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md) |
| P0 bugs open | 0 | issue tracker |
| Internal E2E flows completed | ≥20 users | beta-testing-plan |
| Test coverage (lifecycle + policies) | ≥95% | `packages/quran_sessions/test/` |

---

## Code paths (alignment baseline)

| Area | Path |
|------|------|
| Domain package | `packages/quran_sessions/` |
| App wiring | `apps/tilawa/lib/features/quran_sessions/` |
| Feature flags | `apps/tilawa/lib/features/quran_sessions/quran_sessions_feature_flags.dart` |
| Cloud Functions | `functions/src/quranSessions/` |
| Admin panel | `apps/tilawa_admin/src/app/features/quran-sessions/` |
| Firestore rules | `firestore.rules`, `docs/security/quran_sessions_firestore_rules_draft.md` |

---

## Recommended next sprint

**Sprint 0 — Blueprint review and scope freeze** (see [sprint-plan.md](./sprint-plan.md)).

Exit: stakeholders sign `031` + this plan; scope change process agreed; story priorities locked.
