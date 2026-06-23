# Test Matrix — Payments, Wallet, Refunds

**Blueprint:** `036`  
**Layers:** Domain (Dart), Cloud Functions (Node), Firestore rules emulator, Admin (Angular), Flutter presentation  
**Aligns with:** [031/test-matrix.md](../031-quran-session-blueprint/test-matrix.md), [032/qa-test-plan.md](../032-quran-session-delivery-plan/qa-test-plan.md)

---

## Coverage goals

| Layer | Target | Gate |
|-------|--------|------|
| Domain policies (cancel refund fraction) | 100% branch | `flutter test packages/quran_sessions` |
| CF financial + idempotency | 100% critical paths | `npm test` + integration |
| Firestore rules | Financial collections deny client write | emulator suite |
| Staging smoke | Extend 12 → 20+ checks | `quran-sessions:staging-smoke` |
| Flutter checkout/wallet UI | Happy + failure paths | widget tests |
| Admin financial | Queue + approve E2E | manual + optional Playwright |

---

## Domain unit tests (Dart)

| ID | Scenario | Assert |
|----|----------|--------|
| D-01 | Free booking — no payment reference | `pricingType: free`, no pending payment |
| D-02 | Paid booking requires payment reference | Validation failure if missing when paid |
| D-03 | Student early cancel — full refund fraction | `refundFraction: 1.0` |
| D-04 | Student late cancel — zero refund | `refundFraction: 0` |
| D-05 | Teacher cancel — compensation wallet action | `issueWalletCredit` in action list |
| D-06 | Teacher no-show — wallet credit policy | CP-noShow rule |
| D-07 | `expirePendingReservations` with payment ref | Calls void payment gateway |
| D-08 | Payment failure mapping | `GatewayFailure` → UI message |
| D-09 | Lifecycle: `pendingPayment` → `scheduled` only via confirm | Guard table |
| D-10 | `issueRefund` from disputed | Transition to `refunded` |
| D-11 | Idempotent compensation retry | Same policy result |
| D-12 | Disabled payment provider charge | `Left(GatewayFailure)` |

**Path:** `packages/quran_sessions/test/domain/`, `test/presentation/blocs/booking/`

---

## Cloud Functions unit tests (Node)

| ID | Scenario | Assert |
|----|----------|--------|
| CF-01 | `assertPaidBookingAllowed('free')` passes | No throw |
| CF-02 | `assertPaidBookingAllowed('paid')` when provider off | `payment_provider_unavailable` |
| CF-03 | `financialExecutionStatus()` manual_pending when off | Existing test ✅ |
| CF-04 | `buildOperationKey` deterministic | Existing test ✅ |
| CF-05 | `issueRefundRecord` creates refund doc + lifecycle | Mock txn |
| CF-06 | `issueCompensationRecord` wallet_credit type | Doc fields |
| CF-07 | Duplicate refund idempotency | Single refund doc |
| CF-08 | `resolveSessionDispute` with_refund branch | refundId set |
| CF-09 | `resolveSessionDispute` with_compensation | compensationId set |
| CF-10 | Webhook handler — valid signature | 200 + scheduled |
| CF-11 | Webhook handler — invalid signature | 401 |
| CF-12 | Webhook replay — same eventId | No double capture |
| CF-13 | Wallet debit insufficient balance | Reject txn |
| CF-14 | Wallet credit idempotency | Same transactionId |
| CF-15 | Admin reversal — paired entries | Debit + link |
| CF-16 | `expirePendingReservations` pending_payment | expired + void |

**Path:** `functions/test/quranSessions/`, `functions/test-integration/`

---

## Integration tests

| ID | Scenario | Environment |
|----|----------|-------------|
| INT-01 | Free booking E2E | Emulator / staging |
| INT-02 | Paid booking blocked provider off | Staging smoke #10 ✅ |
| INT-03 | Paid booking sandbox capture | PSP sandbox only |
| INT-04 | Cancel paid → wallet credit | Emulator wallet |
| INT-05 | Dispute resolve refund → wallet balance | Integration |
| INT-06 | Dispute resolve compensation | Integration |
| INT-07 | TTL expire pending payment | Job + void |
| INT-08 | Concurrent book same slot | One wins |
| INT-09 | `manual_pending` → execute wallet | Admin callable |
| INT-10 | Chargeback webhook → alert flag | Mock PSP |

**Path:** `functions/test-integration/resolveSessionDispute.integration.test.ts` (extend)

---

## Firestore rules emulator

| ID | Rule | Expect |
|----|------|--------|
| R-01 | Student read own wallet | Allow |
| R-02 | Student write wallet | Deny |
| R-03 | Student write wallet_transaction | Deny |
| R-04 | Admin read refunds | Allow with claim |
| R-05 | Participant write booking payment fields | Deny |
| R-06 | Unauthenticated read wallet | Deny |
| R-07 | Teacher read student wallet | Deny |

**Path:** `firestore.rules` + emulator test suite (add financial collections)

---

## Staging smoke extension (post-Paid prep)

| # | Check | Free Beta |
|---|-------|-----------|
| 1–12 | Existing free beta smoke | ✅ 035 |
| 13 | Paid teacher → `payment_provider_unavailable` | ✅ #10 |
| 14 | Wallet read returns 0 or 404 for new user | Paid prep |
| 15 | Sandbox paid book → scheduled | Paid prep |
| 16 | Sandbox webhook idempotency | Paid prep |
| 17 | Cancel → wallet credit balance | Paid prep |
| 18 | Admin approve manual_pending refund | Paid prep |
| 19 | Dispute resolve financial | Paid prep |
| 20 | Freeze wallet blocks debit | Paid prep |

---

## Flutter widget / bloc tests

| ID | Screen / component | Scenario |
|----|-------------------|----------|
| FL-01 | Checkout sheet | Shows price + refund policy link |
| FL-02 | Checkout sheet | PSP success → navigates to My Sessions |
| FL-03 | Checkout sheet | Decline → error state |
| FL-04 | `pendingPayment` UI | Countdown visible |
| FL-05 | Wallet screen | Balance + transaction list |
| FL-06 | Wallet empty state | Copy correct |
| FL-07 | Cancel sheet paid | Shows wallet credit amount |
| FL-08 | `payment_failure_mapper` | All failure types |
| FL-09 | Free teacher | No checkout; direct confirm |
| FL-10 | Feature flag off paid | No paid UI |

**Path:** `packages/quran_sessions/test/presentation/`

---

## Admin tests

| ID | Scenario | Method |
|----|----------|--------|
| A-01 | Disputes list loads | `ng build` + manual |
| A-02 | Resolve dispute opens confirm modal | Manual |
| A-03 | Refund queue filters manual_pending | Manual |
| A-04 | Approve refund calls facade | Unit test facade |
| A-05 | Wallet detail shows transactions | Manual |
| A-06 | Issue credit form validation | Unit |
| A-07 | Freeze wallet toggle | Manual staging |
| A-08 | Export CSV downloads | Manual |
| A-09 | No direct balance edit control | UX review |
| A-10 | Payment snapshot on session detail | Manual |

**Path:** `apps/tilawa_admin` — mirror `session-disputes` test patterns when added

---

## Regression / Free Beta guards

| ID | Scenario | Must pass always |
|----|----------|------------------|
| RG-01 | Free session book on staging | ✅ |
| RG-02 | Paid path blocked when flag off | ✅ |
| RG-03 | No wallet debit on free cancel | ✅ |
| RG-04 | Admin dispute read-only in Beta build | Until Phase 4 flag |
| RG-05 | `DisabledPaymentProvider` in prod default | ✅ |

---

## Test data fixtures

| Fixture | Purpose |
|---------|---------|
| `staging_teacher_paid` | Paid pricing teacher (blocked smoke) |
| `student_with_wallet_credit` | Refund E2E |
| `pending_payment_booking` | TTL expire |
| `manual_pending_refund` | Admin execute |
| PSP sandbox cards | Decline + success |

---

## Traceability

| Blueprint doc | Test IDs |
|---------------|----------|
| [payment-flow.md](./payment-flow.md) | CF-10–12, INT-03, FL-01–04 |
| [wallet-model.md](./wallet-model.md) | CF-13–15, INT-04, R-01–03 |
| [refund-to-wallet-policy.md](./refund-to-wallet-policy.md) | D-03–06, INT-04, FL-07 |
| [booking-payment-state-machine.md](./booking-payment-state-machine.md) | D-09, CF-05–09, INT-07 |
| [admin-operations.md](./admin-operations.md) | A-01–10, INT-09 |

---

## CI recommendation

```text
PR gate:
  - dart analyze (quran_sessions)
  - flutter test packages/quran_sessions/test/domain
  - npm test functions/test/quranSessions
  - npm run quran-sessions:staging-smoke (nightly)

Paid feature branch additional:
  - PSP sandbox integration (scheduled)
  - rules emulator financial suite
```
