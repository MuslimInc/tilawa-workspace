# Data Model — Wallet, Payments, Refunds

**Blueprint:** `036`  
**Style:** Backend-agnostic entities; **Firebase/Firestore as adapter note** at end  
**Aligns with:** [031/data-ownership](../031-quran-session-blueprint/data-ownership-security.md), [030 data-model](../030-quran-sessions-domain/data-model.md)

---

## Entity relationship

```mermaid
erDiagram
  User ||--o| Wallet : owns
  Wallet ||--{ WalletTransaction : ledger
  QuranBooking ||--o| BookingPaymentSnapshot : has
  QuranBooking ||--o{ PaymentIntent : may_have
  PaymentIntent ||--{ PaymentTransaction : events
  QuranBooking ||--o| RefundRecord : may_have
  QuranBooking ||--o| CompensationRecord : may_have
  RefundRecord ||--o| WalletTransaction : credits
  CompensationRecord ||--o| WalletTransaction : credits
  User ||--o{ Subscription : future
  SubscriptionPlan ||--o{ Subscription : future
```

---

## Wallet

| Field | Type | Access | Lifecycle |
|-------|------|--------|-----------|
| `walletId` | string | Owner read; admin read | Created on first credit |
| `userId` | string | Indexed | Immutable |
| `currency` | string | Read | Immutable at create |
| `status` | enum | Owner read; admin write via CF | active → frozen → active/closed |
| `availableBalance` | decimal | Owner read | CF-maintained |
| `heldBalance` | decimal | Owner read | CF-maintained |
| `version` | int | Internal | Increment on txn |
| `createdAt` | timestamp | Read | |
| `updatedAt` | timestamp | Read | |

**Indexes:** `userId` + `currency` (unique constraint via deterministic id)

**Deterministic ID:** `wallet_{userId}` (single currency launch)

---

## WalletTransaction

| Field | Type | Access | Lifecycle |
|-------|------|--------|-----------|
| `transactionId` | string | Owner read own; admin all | Immutable after posted |
| `walletId` | string | Indexed | |
| `userId` | string | Indexed | |
| `type` | enum | Read | |
| `direction` | credit/debit | Read | |
| `amount` | decimal | Read | |
| `currency` | string | Read | |
| `status` | enum | Read | pending → posted/failed/reversed |
| `balanceAfter` | decimal | Read | Set at post |
| `idempotencyKey` | string | Unique | |
| `sourceType` | enum | Read | |
| `sourceId` | string? | Read | |
| `description` | string | Read | |
| `actorId` | string | Admin read | |
| `metadata` | map | Admin read | |
| `reversalOfTransactionId` | string? | Read | |
| `createdAt` | timestamp | Indexed desc | |

**Indexes:**
- `userId` + `createdAt` DESC
- `walletId` + `createdAt` DESC
- `idempotencyKey` (unique)
- `sourceType` + `sourceId`

**Deterministic ID option:** `{idempotencyKey}` hashed if idempotency is globally unique

---

## PaymentIntent / Order

Represents PSP checkout session before capture.

| Field | Type | Access | Lifecycle |
|-------|------|--------|-----------|
| `paymentIntentId` | string | Server only | created → succeeded/canceled |
| `bookingId` | string | Indexed | |
| `aggregateId` | string | | |
| `studentId` | string | | |
| `amount` | decimal | | |
| `currency` | string | | |
| `paymentProvider` | enum | | tap/stripe |
| `paymentReference` | string | Client opaque | PSP client secret ref |
| `providerIntentId` | string | Server | PSP id |
| `status` | enum | | requires_payment_method → succeeded/canceled |
| `platformFee` | decimal | | Snapshot |
| `teacherAmount` | decimal | | Snapshot |
| `tax` | decimal | | |
| `idempotencyKey` | string | Unique | |
| `expiresAt` | timestamp | | Align BK-05 |
| `createdAt` | timestamp | | |
| `capturedAt` | timestamp? | | |

---

## PaymentTransaction

PSP event log (charges, captures, voids).

| Field | Type | Description |
|-------|------|-------------|
| `paymentTransactionId` | string | |
| `paymentIntentId` | string | Parent |
| `bookingId` | string | |
| `providerTransactionId` | string | PSP charge id |
| `eventType` | enum | authorized, captured, voided, failed |
| `amount` | decimal | |
| `currency` | string | |
| `rawEventId` | string | Webhook event id (idempotency) |
| `createdAt` | timestamp | |

---

## RefundRecord

Extends existing `quran_session_refunds` collection shape.

| Field | Type | Access | Lifecycle |
|-------|------|--------|-----------|
| `refundId` | string | Admin; owner summary | pending → executed/failed |
| `bookingId` | string | Indexed | |
| `aggregateId` | string | | |
| `sessionId` | string? | | |
| `disputeId` | string? | | |
| `amount` | decimal | | |
| `currency` | string | **Add** (today `amountUsd`) |
| `reason` | string | | |
| `status` | enum | | maps to `FinancialExecutionStatus` |
| `destination` | enum | | `wallet` (default), `card_manual` |
| `walletTransactionId` | string? | | Link when executed |
| `paymentProviderEnabled` | bool | Audit | |
| `approvedByActorId` | string | Admin | |
| `approvedByRole` | enum | | |
| `createdAt` | timestamp | | |
| `completedAt` | timestamp? | | |

**Existing CF fields preserved** for backward compatibility.

---

## CompensationRecord

Extends `quran_session_compensations`.

| Field | Type | Notes |
|-------|------|-------|
| `compensationId` | string | |
| `bookingId` | string | |
| `type` | CompensationType | `wallet_credit` default paid |
| `status` | enum | manual_pending/executed/failed |
| `policyRuleId` | string | |
| `amount` | decimal | |
| `currency` | string | |
| `walletTransactionId` | string? | |
| `disputeId` | string? | |
| `reason` | string | |
| `issuedByActorId` | string | |

---

## SubscriptionPlan (placeholder — not implemented)

| Field | Type |
|-------|------|
| `planId` | string |
| `name` | string |
| `sessionsPerPeriod` | int? |
| `price` | decimal |
| `currency` | string |
| `period` | enum month/year |
| `marketCode` | string |
| `active` | bool |

**No Firestore writes in Paid v1.**

---

## Subscription (placeholder)

| Field | Type |
|-------|------|
| `subscriptionId` | string |
| `userId` | string |
| `planId` | string |
| `status` | active/canceled/past_due |
| `currentPeriodEnd` | timestamp |

---

## BookingPaymentSnapshot

Immutable snapshot on booking at capture time (denormalized for disputes/refunds).

| Field | Type |
|-------|------|
| `pricingType` | free/paid |
| `paymentStatus` | enum |
| `paymentProvider` | enum |
| `paymentReference` | string |
| `providerTransactionId` | string? |
| `amount` | decimal |
| `currency` | string |
| `platformFee` | decimal |
| `teacherAmount` | decimal |
| `tax` | decimal |
| `capturedAt` | timestamp |
| `refundId` | string? |
| `lastCompensationId` | string? |

Stored on `quran_bookings` / session aggregate — matches existing `paymentReference`, `amountPaidUsd` migration path.

---

## Idempotency store

| Field | Type |
|-------|------|
| `operationKey` | string | e.g. `approve_refund:booking_1:idem_1` |
| `resultRef` | string | Created doc id |
| `createdAt` | timestamp |
| `ttl` | timestamp | Optional cleanup |

Existing: `buildOperationKey` in `idempotencyService.ts`

---

## Access control summary

| Collection | Client read | Client write | Admin read | CF write |
|------------|-------------|--------------|------------|----------|
| `user_wallets` | Owner | Deny | Yes | Yes |
| `wallet_transactions` | Owner | Deny | Yes | Yes |
| `payment_intents` | Deny | Deny | Yes | Yes |
| `payment_transactions` | Deny | Deny | Yes | Yes |
| `quran_session_refunds` | Owner summary | Deny | Yes | Yes |
| `quran_session_compensations` | Owner summary | Deny | Yes | Yes |
| `quran_bookings` | Participant | Deny | Yes | Yes |

---

## Firebase adapter note

Suggested collection names (adapter layer only — domain uses entity names):

| Entity | Firestore collection |
|--------|---------------------|
| Wallet | `user_wallets` |
| WalletTransaction | `wallet_transactions` |
| PaymentIntent | `quran_payment_intents` |
| PaymentTransaction | `quran_payment_transactions` |
| RefundRecord | `quran_session_refunds` (existing) |
| CompensationRecord | `quran_session_compensations` (existing) |
| Idempotency | `quran_idempotency_keys` (existing pattern) |

**Rules:** CF-only writes on financial collections; App Check on callables.

---

## Migration from Free Beta

1. Add wallet collections without backfill (no money in Beta).
2. Add `currency`, `destination`, `walletTransactionId` to refund docs when executing.
3. Migrate `amountUsd` → `amount` + `currency: EGP` dual-read period.
4. `manual_pending` refunds: admin batch execute → wallet on Phase 3.

---

## Cross-references

- [wallet-model.md](./wallet-model.md)
- [payment-flow.md](./payment-flow.md)
- `functions/src/quranSessions/financialLedgerService.ts`
