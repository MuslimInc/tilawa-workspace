# Risk Register — Quran Sessions Free Beta

**Last updated:** 2026-06-23  
**Review:** Weekly during Sprints 1–8; daily during Play rollout

**Legend:** Severity H/M/L · Probability H/M/L · Blocker Y/N

---

## Active risks

| ID | Risk | Severity | Probability | Mitigation | Owner | Blocker |
|----|------|----------|-------------|------------|-------|---------|
| R-01 | Booking flag off while UI implies live marketplace | H | H | Gate CTA copy; enable staging only with supply; US-058 | Product | Y |
| R-02 | Legacy `status` vs `lifecycleStatus` drift | H | M | US-060 backfill; dual-read in mappers; smoke #9 | Backend | Y |
| R-03 | Client-side slot race / double booking | H | M | All creates via `createSessionBooking` CF; idempotency key US-050 | Backend | Y |
| R-04 | Compensation without payment infra confuses users | M | M | Beta: credit + manual_pending only; clear UX copy | Product | N |
| R-05 | Gender/child policy bypass via incomplete profile | H | L | US-005 + CF re-validation; ProfileCompletion gate | Eng | Y |
| R-06 | Admin panel direct Firestore writes bypass audit | H | M | CF facade only; admin DoD | Admin dev | Y |
| R-07 | FCM gap → missed sessions | M | H | US-055/057 min: confirm + T-24h; drill on OPPO A98 | Mobile | Y |
| R-08 | Teacher supply < demand in Beta | M | H | US-034 seed ≥5; recruit Sprint 2; empty state | Product | Y |
| R-09 | Solo dev velocity — sprint slip | M | H | Critical path only; defer P2; MVO admin scripts | Eng lead | N |
| R-10 | `meetingLink` not shown — users cannot join | H | H | US-008 P0 Sprint 5; blocks Beta | Mobile | Y |
| R-11 | ValidateBookingEligibilityUseCase untested | H | M | US-061 Sprint 1; 12 cases | Eng | Y |
| R-12 | Teacher dashboard hardcoded `teacher_1` | M | H | US-025 Sprint 3 | Mobile | Y |
| R-13 | Report/dispute mobile UI missing | M | H | US-015/016/040/041 Sprint 6 | Mobile | Y |
| R-14 | Reschedule not wired E2E | M | M | US-054 Sprint 5; P1 not blocker if cancel works | Eng | N |
| R-15 | CF deploy regression breaks all callables | H | L | US-063 CI gate; staged deploy; partial rollback | Backend | Y |
| R-16 | Firestore rules too permissive on rollback | H | L | Avoid rules rollback unless necessary; rules tests | Backend | N |
| R-17 | OPPO/Chinese OEM FCM delivery failure | M | M | Device matrix OPPO A98; battery whitelist doc | QA | N |
| R-18 | Guardian required but no linking UI | M | M | Block child booking; document limitation; defer Production | Product | N |
| R-19 | Dispute backlog >48h SLA | M | M | Ops staffing; admin queue Sprint 6; stop condition | Ops | N |
| R-20 | Scope creep into paid features | M | M | Sprint 0 freeze; US-P* postponed | Product | N |
| R-21 | Play policy rejection (permissions/data safety) | M | L | Privacy policy update; no payment data | Release | N |
| R-22 | Staging smoke fails late (Sprint 7) | H | M | Start smoke partial in Sprint 4; emulator CI Sprint 1 | QA | Y |
| R-23 | Arabic-only strings hurt EN users | L | H | US-018 Production; partial package l10n exists | Mobile | N |
| R-24 | External meeting link invalid/teacher no-show | M | M | Teacher onboarding checklist; teacher cancel flow US-028 | Ops | N |
| R-25 | Accidental payment path in prod build | H | L | `DisabledPaymentProvider`; smoke #10; code review | Backend | Y |
| R-26 | Low-end device performance on teacher list | M | M | US-066; pagination already exists | Mobile | N |
| R-27 | Admin Angular deploy out of sync with CF | M | M | Deploy checklist; version tags together | Admin dev | N |
| R-28 | Beta tester safety incident | H | L | Report flow US-015; ops 24h response; kill switch | Ops | Y |
| R-29 | Remote Config propagation delay on kill switch | M | M | Rollback drill US-072; local flag fallback | Mobile | N |
| R-30 | Insufficient analytics — blind to funnel | L | M | `AnalyticsConstants` session events | Eng | N |

---

## Risk heat map (top blockers)

```
Impact
  H │ R-01 R-03 R-05 R-10 R-11 R-15 R-22 R-25 R-28
  M │ R-07 R-08 R-12 R-13
  L │
    └─────────────────────────────────
      L        M        H   Probability
```

---

## Mitigation timeline by sprint

| Sprint | Risks addressed |
|--------|-----------------|
| 0 | R-20 scope freeze |
| 1 | R-02, R-05, R-11, R-15, R-22 (CI) |
| 2 | R-08 teacher supply |
| 3 | R-12 dashboard UID |
| 4 | R-01, R-03 staging booking |
| 5 | R-07, R-10, R-14 |
| 6 | R-06, R-13, R-19 |
| 7 | R-22 smoke, R-29 drill |
| 8 | R-21 Play, R-28 monitoring |

---

## Escalation

| Condition | Action |
|-----------|--------|
| Any H-severity + H-probability realized | Daily standup + optional Beta delay |
| P0 incident live | [rollback-plan.md](./rollback-plan.md) layer 1–2 immediately |
| Blocker Y risk open at sprint end | Do not start dependent sprint without waiver |

---

## Waived / accepted (Beta)

| Risk | Waiver rationale |
|------|------------------|
| R-18 Guardian UI | Child booking blocked; no child marketing in Beta |
| R-23 EN l10n incomplete | Arabic-primary audience for closed Beta |
| R-14 Reschedule partial | Cancel + rebook workaround if needed |

---

## Paid Sessions risks (deferred — monitor only)

| ID | Risk | Notes |
|----|------|-------|
| P-01 | PCI scope creep | Tokenized only |
| P-02 | Refund fraud / double refund | Idempotency RF-05 |
| P-03 | PSP outage blocks paid booking | Fallback messaging |
| P-04 | Teacher payout reconciliation errors | Finance sign-off PA phase |

---

## Review log

| Date | Reviewer | Changes |
|------|----------|---------|
| 2026-06-23 | Delivery plan | Initial 30 risks |
