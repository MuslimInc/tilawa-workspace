# YAGNI Violations — Quran Sessions

**Audit date:** 2026-06-23

Premature features for **Free Beta**. Action: **keep** (hidden) · **hide** · **postpone** · **remove**

---

## In Free Beta code path today

| Feature | File | Location | Verdict | Action | Severity | Beta blocker |
|---------|------|----------|---------|--------|----------|--------------|
| Paid booking CF branch | `createSessionBooking.ts` | L71–80, L90+ | PSP disabled; branch exists | **Keep** — server blocks paid | **P2** | N |
| `financialLedgerService.ts` | `functions/src/quranSessions/` | ~225 LOC | Refund/compensation ledger | **Postpone** — no admin UI; CF only | **P2** | N |
| `issueSessionCompensation.ts` | CF | — | Compensation callable | **Postpone** — no mobile/admin caller | **P2** | N |
| `IssueCompensationUseCase` | `domain/usecases/issue_compensation_usecase.dart` | Exported in `quran_sessions.dart` L127 | Domain ready, no UI | **Keep** — tested; don't wire UI | **P2** | N |
| `approveSessionRefund.ts` | CF | — | Refund approval | **Postpone paid** | **P2** | N |
| `AgoraCallProvider` | `agora_call_provider.dart` | Throws `UnimplementedError` | V2 in-app call | **Hide** — don't register in DI | **P1** | N |
| `WebRtcCallProvider` | `web_rtc_call_provider.dart` | Same | V4 | **Hide** | **P1** | N |
| `TeacherPayoutProvider` stub | `teacher_payout_provider.dart` | Interface only | Payouts | **Keep** stub | **P2** | N |
| `DisabledPaymentProvider` | `apps/tilawa/…/disabled_payment_provider.dart` | — | Blocks paid in app | **Keep** — correct Beta guard | — | N |
| Dispute/report CFs | `sessionDisputeCallables.ts`, `sessionReportCallables.ts` | ~354 + ~240 LOC | No mobile UI | **Postpone** — safety gap but CF-ready | **P1** | N (product) |
| `pending_payment` lifecycle | `session_transition_table.dart` | Transitions defined | No paid flow | **Keep** — guard prevents illegal use | **P2** | N |
| Subscription pricing type | Entities + CF request | `pricingType: subscription` | Not used in Beta | **Keep** enum; reject at CF if selected | **P2** | N |
| Metrics aggregation | `metricsAggregationService.ts` | Called from CF | No dashboard consumer | **Keep** — low cost | **P2** | N |
| `markSessionNoShow` CF | `markSessionNoShow.ts` | ~172 LOC | No scheduled job evidenced | **Postpone** — needs cron | **P2** | N |
| Teacher application debug panel | `teacher_application_status_screen.dart` | L305–342 | Debug-only UI in release path | **Hide** behind `kDebugMode` | **P1** | N |
| Fake MVP entire module | `quran_sessions_mvp_module.dart` | 316 LOC DI | Dev/demo backend | **Keep** for `QuranSessionsBackendMode.fake` | **P2** | N |
| `amountPaidUsd` on admin detail | `session-detail.component.html` L121 | Shows USD field | Free Beta always null | **Hide** column for free markets | **P2** | N |
| Compensation policy tests | `compensation_policy_test.dart` | Domain tests | No user flow | **Keep** — documents rules | **P2** | N |

---

## Should NOT have been built yet (but harmless if gated)

| Feature | Why YAGNI | Current gate | Risk if ungated |
|---------|-----------|--------------|-----------------|
| In-app Agora/WebRTC | External meeting sufficient for Beta | Not in DI | Crash if wired |
| Full financial ledger UI | No money in Free Beta | Admin missing | Low |
| Paid eligibility branches in UI | `SessionPricingType.free` hardcoded in cancel | Partial | Wrong copy only |

---

## Remove from Free Beta scope (product, not delete code)

| Item | Recommendation |
|------|----------------|
| Teacher earnings preview | Not in code — good |
| PSP checkout UI | Not in code — `DisabledPaymentProvider` blocks |
| Payout batch jobs | CF only — postpone |

---

## Keep for Beta (not YAGNI)

| Item | File | Reason |
|------|------|--------|
| `ExternalMeetingCallProvider` | 30 LOC | **Needed now** — just wire it |
| Idempotency service | CF | Real sessions need safe retries |
| Lifecycle guard | Dart + CF | Core safety |
| Teacher application flow | Full stack | Supply onboarding |
| Weekly availability + overrides | Large but IN scope | Booking depends on it |

---

## Summary

| Action | Count |
|--------|-------|
| Keep (gated) | 8 |
| Hide | 3 |
| Postpone | 7 |
| Remove | 0 |
| **Wire (was built, not connected)** | **1** (`CallProvider` join) |
