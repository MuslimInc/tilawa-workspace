# Spec 038 — Quran Sessions Stable Production Release

**Status:** P0 remediated + test closure — Conditional Go for staging/closed testing  
**Date:** 2026-06-24  
**Prior milestone:** [037-quran-session-free-beta-closure](../037-quran-session-free-beta-closure/)

## Purpose

Move Quran Sessions from **experimental Free Beta** to **stable production v1** for individual free 1:1 sessions (external meeting + mock voice/video). This spec documents an honest gap analysis, P0 blockers, release scope, and implementation plan — then tracks surgical fixes only.

## Out of scope (stable v1)

- Paid sessions, wallet checkout, payouts, subscriptions
- Group sessions
- Marketplace ranking / advanced reviews
- Agora / WebRTC SDK integration
- Bilateral session mode/provider change (post-beta)
- Mobile reschedule confirm UI (admin-only confirm remains)

## Documents

| File | Contents |
|------|----------|
| [production-gap-analysis.md](./production-gap-analysis.md) | Evidence-based audit by area |
| [production-blockers.md](./production-blockers.md) | P0 / P1 / postponed items |
| [release-scope.md](./release-scope.md) | What ships in stable v1 |
| [admin-ops-requirements.md](./admin-ops-requirements.md) | Admin panel readiness |
| [security-safety-checklist.md](./security-safety-checklist.md) | CF authz, rules, safety |
| [qa-release-gates.md](./qa-release-gates.md) | Manual + automated gates |
| [monitoring-rollback-plan.md](./monitoring-rollback-plan.md) | Kill switches, observability |
| [google-play-release-checklist.md](./google-play-release-checklist.md) | Play production readiness |
| [implementation-plan.md](./implementation-plan.md) | Priority-ordered work |
| [final-report.md](./final-report.md) | Closure report, test matrix, Go/No-Go |

## Stable production acceptance criteria

- [ ] Full student → teacher → admin flow verified on staging (manual)
- [ ] Teacher approval → dashboard without app restart
- [ ] Free individual booking works when flag enabled
- [ ] Join safe; non-participants blocked (rules + client)
- [ ] Stale devices blocked on mutations (epoch CF)
- [ ] Reports/disputes visible to admin queues
- [ ] Mode/provider locked at booking (Option A); admin override path documented
- [ ] No paid/group paths exposed in production build
- [ ] Notifications target active device (FCM + outbox)
- [ ] Rules block protected-field mutation (eligibility, session, trust)
- [ ] Critical automated tests pass (`quran_sessions_preflight.sh`)
- [ ] Feature-flag rollback wired (`quranSessionsEnabled`, booking flag)
- [ ] Google Play checklist complete

## Verdict (2026-06-24)

**Conditional Go** — engineering strong for closed/staging individual free sessions; **not** unconditional production Go until manual E2E sign-off (B1–B5, T2–T8), App Check rollout, and legal privacy verify for external meeting links.

See [production-blockers.md](./production-blockers.md) for P0 status after this milestone's code changes.
