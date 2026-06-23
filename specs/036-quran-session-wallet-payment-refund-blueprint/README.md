# Quran Sessions — Paid Sessions + User Wallet Design Blueprint

**Blueprint ID:** `036-quran-session-wallet-payment-refund-blueprint`  
**Created:** 2026-06-23  
**Status:** Design artifact — **no code changes implied; not ready to ship**  
**Audience:** Product, finance, legal, engineering, admin ops  
**Prerequisite specs:** [031](../031-quran-session-blueprint/README.md) (domain contract), [032](../032-quran-session-delivery-plan/README.md) (delivery plan), [033](../033-quran-session-current-state-audit/README.md) (audit), [034](../034-quran-session-code-quality-audit/) (quality), [035](../035-quran-session-staging-validation-sprint/report.md) (Free Beta status)

---

## Executive summary

This blueprint defines how MeMuslim / Tilawa will move from **Free Beta** (free sessions only, `manual_pending` refund/compensation records) to **Paid v1**: pay-per-session checkout, in-app **wallet** as the default refund destination, and admin-operable financial ledger — without enabling paid sessions in production until explicit Go/No-Go gates pass.

**KISS / YAGNI recommendation:** Ship Paid v1 as **pay-per-session + card capture + refund-to-wallet + wallet checkout**. Postpone subscriptions, mixed payment, automatic card reversal, teacher payout automation, and tax automation until wallet + PSP flows are proven on staging.

| Dimension | Free Beta (today) | Paid v1 (target) | Post–Paid v1 |
|-----------|-------------------|------------------|--------------|
| Booking pricing | `pricingType: free` only | `paid` per session | Subscriptions, packages |
| Payment capture | `DisabledPaymentProvider`; CF throws `payment_provider_unavailable` | PSP charge at booking | Wallet + card mixed (optional) |
| Refunds | `quran_session_refunds` with `status: manual_pending` | Wallet credit (ledger) | Card reversal (legal/ops only) |
| Compensation | `wallet_credit` type exists in CF; no wallet entity | Same → wallet ledger | Auto policy execution |
| Teacher payout | None | Manual off-platform | Batch payout job |
| Admin financial UI | Disputes read-only (035); no resolve | Wallet view, credit issue, refund approve | Full ledger export |

**This blueprint does not authorize enabling paid sessions.** Implementation requires separate finance/legal sign-off and feature flags.

---

## Scope

### In scope (design)

- Payment options A (card/PSP), B (wallet), C (mixed) — with C marked optional/postponed
- Wallet aggregate + immutable transaction ledger
- Refund-to-wallet default policy; card reversal as exceptional/manual
- Booking ↔ payment state machine aligned with [031 session-state-machine](../031-quran-session-blueprint/session-state-machine.md)
- Admin financial operations (no direct balance edits)
- Data model entities, indexes, idempotency keys
- Security/compliance checklist (questions flagged, not claims)
- Test matrix and phased implementation roadmap

### Out of scope (design only — explicitly postponed)

- Subscription billing (see [subscription-model.md](./subscription-model.md) YAGNI)
- Teacher automated payout / commission settlement
- Multi-currency settlement beyond single launch market (EG-first per 031)
- PCI card storage in Firestore
- Production PSP selection (Tap vs Stripe EG — decision gate in roadmap Phase 2)
- In-app Agora calls (031/032 V2)

### Aligned with current code (read-only baseline)

| Area | Current state |
|------|---------------|
| Lifecycle | `pendingPayment`, `refunded`, `compensated` in `SessionLifecycleStatus` |
| Payment gate | `functions/src/quranSessions/paymentProviderStatus.ts` — `PAYMENT_PROVIDER_ENABLED=false` |
| Ledger | `financialLedgerService.ts` — `quran_session_refunds`, `quran_session_compensations` |
| Compensation types | `wallet_credit`, `restore_credit`, `replacement_session`, `extend_subscription`, `manual_review` |
| Mobile | `DisabledPaymentProvider` in `apps/tilawa/.../disabled_payment_provider.dart` |
| Smoke | Staging smoke #10 verifies `payment_provider_unavailable` for paid path |

---

## Document index

| # | File | Purpose |
|---|------|---------|
| 1 | [README.md](./README.md) | Index, decisions, UX summary, Go/No-Go answers |
| 2 | [payment-flow.md](./payment-flow.md) | Checkout options, payment fields, lifecycle relation |
| 3 | [wallet-model.md](./wallet-model.md) | Ledger, balances, transaction types |
| 4 | [refund-to-wallet-policy.md](./refund-to-wallet-policy.md) | When wallet vs card; transparency |
| 5 | [subscription-model.md](./subscription-model.md) | Four models + YAGNI recommendation |
| 6 | [booking-payment-state-machine.md](./booking-payment-state-machine.md) | States, transitions, side effects |
| 7 | [admin-operations.md](./admin-operations.md) | Ops workflows, no balance tampering |
| 8 | [data-model.md](./data-model.md) | Entities, access, indexes, idempotency |
| 9 | [security-compliance-checklist.md](./security-compliance-checklist.md) | PSP, Play, legal, fraud — review flags |
| 10 | [test-matrix.md](./test-matrix.md) | Unit, integration, emulator, admin, Flutter |
| 11 | [implementation-roadmap.md](./implementation-roadmap.md) | Phases 0–6, gates, risks |

---

## Product decisions (locked for this blueprint)

| # | Decision | Rationale |
|---|----------|-----------|
| D-01 | Refunds credit **in-app wallet**, not automatic card reversal | Faster UX, lower PSP fees, reusable for Quran + eligible MeMuslim services |
| D-02 | Wallet balance = sum of immutable ledger entries; **no direct balance field edits** | Auditability, dispute resolution |
| D-03 | Paid v1 = **pay-per-session** only | YAGNI; subscriptions deferred |
| D-04 | Free Beta unchanged until Paid v1 gates pass | 035: smoke 12/12 backend; manual E2E pending |
| D-05 | `manual_pending` execution status remains until wallet + PSP wired | Matches `financialExecutionStatus()` today |
| D-06 | Teacher payout **manual** in Paid v1 | No payout automation until volume justifies |
| D-07 | Mixed pay (wallet + card) **postponed** | Complexity; wallet-only-after-refund first |
| D-08 | All financial writes **server-authoritative** (CF) | Same pattern as booking lifecycle (031) |
| D-09 | Currency launch market: **EGP** (configurable via market config) | Aligns with 031 single-market-first |
| D-10 | Card data never stored in Firestore | PCI scope minimization |

---

## UX requirements (by actor)

Cross-reference [031 student-flow](../031-quran-session-blueprint/student-flow.md), [031 teacher-flow](../031-quran-session-blueprint/teacher-flow.md), [031 admin-flow](../031-quran-session-blueprint/admin-flow.md).

### Student

| Screen / moment | Free Beta | Paid v1 |
|-----------------|-----------|---------|
| Teacher profile / slot picker | Price hidden or "Free session" | Session price + currency from teacher/market config |
| Checkout | Confirm free booking | Payment sheet (PSP) or "Pay with wallet" if balance ≥ price |
| `pendingPayment` | N/A | Countdown TTL (BK-05: 15 min default); abandon → slot released |
| My Sessions / detail | No payment row | Payment status chip: `paid`, `refunded`, `compensated` |
| Wallet (new) | Hidden or "Coming soon" | Balance, transaction history, credit source labels |
| Cancel | Policy copy (no money) | Refund fraction copy + "Credits to your Tilawa wallet" |
| Dispute outcome | Notification only | Wallet credit notification with amount + booking link |
| Errors | `payment_provider_unavailable` if misconfigured | Decline, timeout, insufficient wallet — mapped via `payment_failure_mapper.dart` pattern |

### Teacher

| Screen / moment | Free Beta | Paid v1 |
|-----------------|-----------|---------|
| Pricing editor | Disabled / free only | Session rate within market min/max (US-P04 postponed UI; config exists) |
| Dashboard earnings | Hidden | "Earnings pending manual payout" read-only summary (no bank details in app) |
| Cancel / no-show | Compensation policy copy | Same; student receives wallet credit per policy |

### Admin

| Screen / moment | Free Beta (035) | Paid v1 |
|-----------------|-----------------|---------|
| Disputes queue | Read-only list + detail | Resolve → refund or compensation (CF `resolveSessionDispute`) |
| Refunds / compensations | Firestore only | Queue: `manual_pending` → approve → wallet credit |
| User wallet | N/A | View balance (computed), transactions, freeze, issue credit (audited) |
| Session detail | Booking + lifecycle | + payment snapshot, refund/compensation IDs |
| Export | N/A | CSV export of ledger entries (date range, actor) |

---

## Cross-references

| Topic | Spec |
|-------|------|
| Session lifecycle | [031/session-state-machine.md](../031-quran-session-blueprint/session-state-machine.md) |
| Business rules RF-*, CN-* | [031/business-rules.md](../031-quran-session-blueprint/business-rules.md) |
| Postponed paid stories US-P01–P08 | [032/user-stories.md](../032-quran-session-delivery-plan/user-stories.md) |
| Free Beta gaps | [033/free-beta-gap-analysis.md](../033-quran-session-current-state-audit/free-beta-gap-analysis.md) |
| Staging validation | [035/report.md](../035-quran-session-staging-validation-sprint/report.md) |

---

## Final output — design answers

### 1. Recommended payment model

**Pay-per-session** with single PSP charge at booking confirmation (`draft` → `pendingPayment` → capture → `scheduled`). Wallet as **secondary** funding source only after Phase 4 (wallet checkout), not at Paid v1 launch unless balance already exists from prior refunds.

### 2. Recommended wallet model

**Single user wallet per MeMuslim account** with **append-only `WalletTransaction` ledger**, computed `availableBalance`, optional `heldBalance` for in-flight bookings. No negative balance. All mutations via server callables with idempotency keys. See [wallet-model.md](./wallet-model.md).

### 3. Refund-to-wallet policy

**Default:** all eligible refunds and marketplace compensations credit wallet in app currency. **Exception:** card reversal only via admin + finance approval for legal/regulatory cases. Clear pre-checkout and refund copy. See [refund-to-wallet-policy.md](./refund-to-wallet-policy.md).

### 4. Subscription needed now?

**No.** Entity fields and compensation type `extend_subscription` exist as forward placeholders. Paid v1 does not require subscription infrastructure. See [subscription-model.md](./subscription-model.md).

### 5. Build first

1. Complete Free Beta gates (035 manual E2E, seed teachers)  
2. Wallet ledger + admin view (Phase 1)  
3. PSP sandbox + `pendingPayment` E2E (Phase 2)  
4. Refund-to-wallet automation linked to cancellation/dispute (Phase 3)

### 6. Postpone

- Subscriptions (student, teacher package, platform)  
- Mixed wallet + card split checkout  
- Automatic PSP card refunds on cancel  
- Teacher payout automation  
- Multi-market tax engine  
- Wallet spend on non–Quran-Sessions services (design hook only)

### 7. Main risks

| Risk | Severity |
|------|----------|
| Enabling paid before Free Beta stable | High |
| Wallet balance disputes without clear ledger UX | High |
| Play policy / digital goods classification | Medium |
| Chargeback on card pay with wallet-only refund policy | Medium |
| Admin misuse of credit issue | Medium |
| PSP outage during `pendingPayment` TTL | Medium |
| Scope creep into subscriptions | Medium |

### 8. Compliance questions (owner / legal review)

- Wallet = stored value or promotional credit under EG law?  
- Refund policy disclosure at checkout (wallet-only default)  
- Minors: guardian wallet ownership  
- Tax/VAT on session fees  
- Play Billing vs external PSP for digital services  
- Data retention for payment audit trail  
- Chargeback handling when refund is wallet-only  

Full checklist: [security-compliance-checklist.md](./security-compliance-checklist.md).

### 9. Test requirements

Domain policy tests, CF integration (idempotency, webhook replay), Firestore rules emulator, staging smoke extension, Flutter widget tests for checkout/wallet, admin E2E for financial queues. Matrix: [test-matrix.md](./test-matrix.md).

### 10. Go / No-Go summary

| Milestone | Verdict |
|-----------|---------|
| **Free Beta** | **CONDITIONAL GO** (035): backend smoke pass; manual 16-step E2E + seed pending |
| **Paid v1 staging** | **NO-GO** until Phases 0–3 complete + wallet E2E |
| **Paid v1 production** | **NO-GO** until Phase 6 gates: PSP prod, legal copy signed, admin financial training, extended smoke, rollback drill |
| **This blueprint** | **DESIGN COMPLETE** — implementation not authorized |

---

## Implementation pointer

Phased delivery: [implementation-roadmap.md](./implementation-roadmap.md). Do not set `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=true` or ship paid UI until Phase 6 Go/No-Go.
