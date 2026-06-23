# Quran Sessions — Product + UX + Business Domain Blueprint

**Project:** MeMuslim / أنا مسلم — Quran Sessions (Tilawa workspace)  
**Blueprint ID:** `031-quran-session-blueprint`  
**Created:** 2026-06-23  
**Status:** Canonical planning artifact — **no code changes implied**  
**Audience:** Product, UX, engineering, ops, admin operators

---

## Executive summary

Quran Sessions is MeMuslim's live 1:1 Quran learning marketplace: students discover verified teachers, book time slots, join audio/video sessions, and resolve disputes through policy-driven compensation. The Tilawa workspace already ships **~60% of MVP product surface** and **~85% of backend-agnostic domain architecture**, but production readiness is blocked by **server-authoritative lifecycle wiring gaps**, **booking disabled by feature flag**, and **missing ops UX** (notifications, cancel reasons, dispute/report flows).

This blueprint is the **single cross-functional contract** for what to build, in what order, and how to verify it — without prescribing Firebase/Flutter implementation details in this folder.

| Dimension | Current state | Blueprint target |
|-----------|---------------|------------------|
| Domain lifecycle | `SessionLifecycleStatus` + guard shipped (`packages/quran_sessions/lib/src/domain/lifecycle/`) | All actors use typed transitions only |
| Booking writes | CF callables exist; flag `quranSessionsBookingEnabled: false` | Free Beta: CF-only free bookings |
| Admin ops | Partial Angular panel (`apps/tilawa_admin/.../quran-sessions/`) | Full session moderation + ledger |
| Payments | `DisabledPaymentProvider` stub | Post-Beta; config-driven |
| Notifications | Outbox schema + CF; no FCM delivery wired | Beta: booking + reminder push |

**Recommendation:** **Conditional Go for Free Beta** after P0 staging smoke (see [production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md)). **No-Go for paid sessions** until payment gateway + refund automation verified.

---

## How to use this blueprint

1. **Product / UX** — Start with [student-flow.md](./student-flow.md), [teacher-flow.md](./teacher-flow.md), [screen-inventory.md](./screen-inventory.md).
2. **Engineering** — [backend-agnostic-architecture.md](./backend-agnostic-architecture.md), [session-state-machine.md](./session-state-machine.md), [data-ownership-security.md](./data-ownership-security.md).
3. **Ops / Admin** — [admin-flow.md](./admin-flow.md), [service-blueprints.md](./service-blueprints.md).
4. **QA** — [test-matrix.md](./test-matrix.md), [edge-cases-matrix.md](./edge-cases-matrix.md).
5. **Delivery planning** — [implementation-roadmap.md](./implementation-roadmap.md), [business-rules.md](./business-rules.md).

Cross-reference prior work:
- Domain spec: [specs/030-quran-sessions-domain/spec.md](../030-quran-sessions-domain/spec.md)
- Roadmap tracker: [docs/quran_sessions_roadmap.md](../../docs/quran_sessions_roadmap.md)

---

## Blueprint index

| # | Document | Purpose |
|---|----------|---------|
| 1 | [README.md](./README.md) | Index, decisions, risks, go/no-go |
| 2 | [student-flow.md](./student-flow.md) | End-to-end student journey |
| 3 | [teacher-flow.md](./teacher-flow.md) | Teacher onboarding → session delivery |
| 4 | [admin-flow.md](./admin-flow.md) | Moderation, disputes, ledger |
| 5 | [session-state-machine.md](./session-state-machine.md) | Canonical lifecycle + transitions |
| 6 | [service-blueprints.md](./service-blueprints.md) | 8 service design flows |
| 7 | [sequence-diagrams.md](./sequence-diagrams.md) | 10 cross-system sequences |
| 8 | [edge-cases-matrix.md](./edge-cases-matrix.md) | Edge case → expected behavior |
| 9 | [business-rules.md](./business-rules.md) | Configurable policy catalog |
| 10 | [data-ownership-security.md](./data-ownership-security.md) | Ownership, rules, lifecycle |
| 11 | [backend-agnostic-architecture.md](./backend-agnostic-architecture.md) | Domain, use cases, gateways |
| 12 | [screen-inventory.md](./screen-inventory.md) | All screens by actor |
| 13 | [test-matrix.md](./test-matrix.md) | 95–100% domain coverage plan |
| 14 | [implementation-roadmap.md](./implementation-roadmap.md) | Phased delivery + gates |

---

## Major product decisions

| # | Decision | Rationale | Beta | Paid |
|---|----------|-----------|------|------|
| 1 | **Session aggregate** unifies booking + session docs | Query ergonomics + domain invariants together | ✅ | ✅ |
| 2 | **Server-authoritative writes** via command gateway | Firestore rules deny client mutation; prevents races | ✅ | ✅ |
| 3 | **Free-only Beta** (`pricingType: free`) | De-risk supply/demand before payments | ✅ | ❌ |
| 4 | **`confirmed` status optional** — auto-skip to `scheduled` in Beta | Reduce friction; enable in paid markets later | Skip | Optional |
| 5 | **Reschedule = counterparty consent** unless admin force | Trust + teacher calendar integrity | ✅ | ✅ |
| 6 | **Teacher cancel → auto-compensate student** (configurable) | Marketplace fairness | ✅ | ✅ |
| 7 | **No-show detection: system job + manual override** | Call provider webhooks deferred | Job only | + webhooks |
| 8 | **Disputes open from terminal states only** | Prevent mid-session gaming | ✅ | ✅ |

---

## Major risks

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| 1 | Booking flag off while UI implies live marketplace | **High** | Gate CTA copy; enable only with approved teacher supply |
| 2 | Legacy `status` vs `lifecycleStatus` drift | **High** | Backfill + dual-read until M3; smoke test #9 |
| 3 | Client-side slot check race (pre-CF path) | **High** | All creates via `createSessionBooking` CF + slot locks |
| 4 | Compensation without payment infra | **Medium** | Beta: session credit only; paid: manual_pending ledger |
| 5 | Gender/child policy bypass via incomplete profile | **High** | Hard gate at booking + CF re-validation |
| 6 | Admin panel direct Firestore writes | **High** | All mutations via callables (existing pattern) |
| 7 | Notification delivery gap → missed sessions | **Medium** | Beta minimum: confirm + T-24h reminder |
| 8 | Teacher supply < demand in Beta | **Medium** | Waitlist + empty state; cap bookings per teacher |

---

## Missing flows discovered (vs existing code)

Audited paths under `apps/tilawa/`, `packages/quran_sessions/`, `functions/src/quranSessions/`, `apps/tilawa_admin/`.

| Flow | Expected | Found | Gap |
|------|----------|-------|-----|
| Student report safety concern | Callable + admin queue | CF `reportSessionConcern` exists | **No mobile UI** |
| Student open dispute | Post-session dispute form | CF `openSessionDispute` | **No mobile UI** |
| Guardian approval for child student | Block booking until linked | `GuardianApprovalRequiredFailure` only | **No guardian link flow** |
| Join call from My Sessions | Tap → external link / in-app | `meetingLink` on entity | **Link not displayed** (`docs/quran_sessions_roadmap.md` P0) |
| Cancel with reason | Sheet + policy copy | `cancel_session_sheet.dart` partial | Reason required but UX incomplete |
| Reschedule UI | Request + accept flow | `reschedule_session_screen.dart` exists | **Not wired to CF gateway end-to-end** |
| Rating after complete | Prompt + submit | Review use case exists | Prompt timing undefined |
| Teacher vacation override | Block generated slots | `availability_override_sheet.dart` | Beta: teacher-only; no admin view |
| Paid booking checkout | Payment → confirm | `DisabledPaymentProvider` | **Explicitly disabled** |
| Subscription sessions | Recurring credit | Entity field only | Not implemented |
| Teacher earnings / payout | Dashboard + admin ledger\\ `TeacherPayoutProvider` stub | Post-paid |
| FCM reminders | Scheduled jobs | Outbox + `deliverSessionNotification` | **Delivery not wired to FCM** |
| Admin financial ledger UI | Refund/compensation queue | CF ledger helpers | **Admin UI partial** |

---

## What to fix before Free Beta

Priority-ordered; maps to [implementation-roadmap.md](./implementation-roadmap.md) Phase B.

1. **Enable booking safely** — approved teacher supply + `quranSessionsBookingEnabled` staging only.
2. **Display `meetingLink`** in session detail / My Sessions (`session_detail_screen.dart`).
3. **Cancel reason UX** — wire `CancelSessionUseCase` → `SessionCommandGateway` with reason validation.
4. **Staging smoke 10-check** — [production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md).
5. **Backfill lifecycle** — `lifecycleStatus` consistency script.
6. **Booking confirmation push** — minimum notification path.
7. **Session reminder T-24h** — scheduled job + FCM.
8. **Profile gate** — real auth UID everywhere (mostly done; verify teacher dashboard route).
9. **Report concern entry point** — session detail → admin queue.
10. **Admin sessions list/detail** — verify filters match ops checklist.

---

## What to postpone until paid sessions

| Item | Why defer |
|------|-----------|
| Payment capture / `pendingPayment` UX | No gateway in Beta |
| Refund automation via PSP | Manual_pending ledger sufficient for Beta disputes |
| Teacher payout / earnings screen | No money movement |
| Subscription pricing model | Requires billing infra |
| `confirmed` ack step | Optional friction |
| Agora / WebRTC in-app calls | External meeting link sufficient for Beta |
| Auto-suspend on N teacher cancels | Metrics only in Beta |
| Multi-market currency settlement | Single market (EG) first |
| OTP phone verification for teachers | ADR-003 deferred |

---

## Go / No-Go recommendation

| Gate | Free Beta | Production (free) | Paid sessions |
|------|-----------|---------------------|---------------|
| Domain lifecycle tests green | Required | Required | Required |
| CF integration tests pass | Required | Required | Required |
| Staging smoke 10/10 | Required | Required | Required |
| ≥5 approved public teachers | Required | Required | Required |
| Booking flag enabled | Staging → prod | Required | Required |
| Payment provider live | **No** | **No** | Required |
| Refund automation | Manual | Manual | Required |
| FCM confirm + reminder | Required | Required | Required |
| Admin dispute resolution tested | Required | Required | Required |

**Verdict:** **Conditional Go** for Free Beta after staging smoke + supply seed. **No-Go** for paid until payment + refund E2E on staging.

---

## Next implementation phase

See [implementation-roadmap.md](./implementation-roadmap.md). Immediate next work:

**Phase B0 — Beta unblock (2 weeks):** meeting link, cancel UX, notifications, report UI, enable booking flag on staging.

**Phase B1 — Beta hardening (2 weeks):** reschedule E2E, admin session actions QA, edge-case test sweep.

**Phase P1 — Paid prep (post-Beta):** payment provider, `pendingPayment` flow, automated refund, teacher payout ledger.

---

## Code paths referenced (audit baseline)

| Area | Path |
|------|------|
| Domain lifecycle | `packages/quran_sessions/lib/src/domain/lifecycle/` |
| Use cases | `packages/quran_sessions/lib/src/domain/usecases/` |
| Cloud Functions | `functions/src/quranSessions/` |
| App wiring | `apps/tilawa/lib/features/quran_sessions/` |
| Admin panel | `apps/tilawa_admin/src/app/features/quran-sessions/` |
| Feature flags | `apps/tilawa/lib/features/quran_sessions/quran_sessions_feature_flags.dart` |
| Prior spec | `specs/030-quran-sessions-domain/` |
