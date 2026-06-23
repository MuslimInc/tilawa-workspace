# Phase 2 Implementation Log — PSP Pay-Per-Session (Sandbox)

**Blueprint:** `036`  
**Date:** 2026-06-23  
**Constraint:** Production paid remains **OFF** by default; sandbox only when flags explicit.

---

## Implemented

### 2-1 PSP selection (doc)

- [psp-selection-gate.md](./psp-selection-gate.md) — Tap vs Stripe EG, recommendation (Tap primary), sign-off checklist.

### 2-2 Payment provider abstraction (CF)

| File | Purpose |
|------|---------|
| `functions/src/quranSessions/payment/types.ts` | `PaymentProvider` interface, snapshot types |
| `functions/src/quranSessions/payment/disabledPaymentProvider.ts` | Default when env false |
| `functions/src/quranSessions/payment/sandboxPaymentProvider.ts` | Staging test double |
| `functions/src/quranSessions/payment/paymentProviderRegistry.ts` | `resolvePaymentProvider()` |
| `functions/src/quranSessions/payment/envGate.ts` | `isPaymentProviderEnabled()` runtime |

### 2-3 Paid booking path

- `createSessionBooking.ts`: paid + provider on → `pending_payment`, `paymentStatus: pending`, creates `quran_payment_intents` doc, returns `paymentReference` + `clientConfirmToken`.
- Provider off: `payment_provider_unavailable` unchanged.

### 2-4 confirmBookingPayment

- Callable `confirmBookingPayment` — idempotent via `confirm_booking_payment` operation key → `scheduled`, `BookingPaymentSnapshot`, `quran_payment_transactions` capture row, hard slot lock, notification.

### 2-5 Data model

| Collection | Rules |
|------------|-------|
| `quran_payment_intents` | Admin read; CF write only |
| `quran_payment_transactions` | Admin read; CF write only |
| Booking `paymentSnapshot` | Denormalized on `quran_bookings` at capture |

No new composite indexes required (lookup by doc id).

### 2-6 Flutter (staging flag)

| Item | Detail |
|------|--------|
| `SandboxPaymentProvider` | `apps/tilawa/.../sandbox_payment_provider.dart` |
| DI | Registered when `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED=true` |
| Default | `DisabledPaymentProvider` |
| `PaymentCheckoutSheet` | Sandbox confirm button + refund-to-wallet notice |
| `SessionBookingOutcome` | Carries `clientConfirmToken` from CF response |
| `BookingPaymentRequired` | Bloc state → checkout sheet |

### 2-7 Smoke extension

- Default: `no paid booking exposed` when provider off.
- Optional: `STAGING_SMOKE_PAID_SANDBOX=true` **and** `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=true` → `sandbox paid book and confirm`.

---

## Flags / env vars

| Flag / env | Default | Effect |
|------------|---------|--------|
| `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` | **false** | CF paid path gate |
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | **false** | App sandbox provider + checkout |
| `STAGING_SMOKE_PAID_SANDBOX` | unset | Optional smoke paid E2E |

**Staging paid E2E requires both CF and app flags true.**

---

## Test results

| Suite | Count |
|-------|-------|
| `functions` `npm test` | **58/58** pass |
| `sandboxPaymentProvider.test.ts` | 4 tests (intent create, token reject, idempotent precheck, exports) |
| `paymentAndIdempotency.test.ts` | 3 tests (unchanged behavior provider off) |
| `packages/quran_sessions` booking bloc | **7/7** |
| `apps/tilawa` sandbox provider | **2/2** |

---

## Deferred (by design)

| Item | Phase |
|------|-------|
| Real Tap/Stripe SDK | After PSP sign-off |
| Wallet checkout | 4 |
| Auto refund-to-wallet | 3 |
| Webhook HTTP endpoint (PSP) | With real PSP |
| `allowPaidBooking` market config UI | 6 |

---

## Go/No-Go for Phase 3 (refund-to-wallet automation)

| Criterion | Status |
|-----------|--------|
| Sandbox paid book→confirm on staging (manual + smoke opt-in) | ⚠️ Needs staging run with flags |
| CF tests green | ✅ 58/58 |
| Provider default false in prod | ✅ |
| PSP selection doc + owner sign-off | ⚠️ Checklist open |
| Legal refund-to-wallet copy | ⚠️ Draft in checkout; legal review pending |
| No P0 financial bugs in sandbox path | ✅ (unit level) |

**Verdict:** **CONDITIONAL GO** for Phase 3 engineering — start refund-to-wallet CF wiring in staging. **NO-GO** for real PSP or prod paid until PSP gate + Phase 6 gates.

---

## User sign-off before real PSP

1. [psp-selection-gate.md](./psp-selection-gate.md) checklist (legal, finance, security, executive).
2. Sandbox staging E2E recording (book → checkout → join).
3. Legal approval of refund-to-wallet checkout copy.
4. Prod PSP keys in Secret Manager (not in repo).
5. Webhook URL + monitoring runbook.

---

## Rollback

Set `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=false` and `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED=false` — paid bookings blocked; Free Beta unchanged.
