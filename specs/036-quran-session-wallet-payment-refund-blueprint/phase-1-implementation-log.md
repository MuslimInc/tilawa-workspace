# Phase 1 Implementation Log — Wallet Foundation

**Blueprint:** `036`  
**Date:** 2026-06-23  
**Constraint:** Paid sessions remain **OFF** (`PAYMENT_PROVIDER_ENABLED=false`, `DisabledPaymentProvider` unchanged)

---

## Implemented

### 1-1 Schema (`user_wallets`, `wallet_transactions`)

- Collections per [data-model.md](./data-model.md)
- Deterministic wallet id: `wallet_{userId}`
- Transaction docs keyed by sanitized `idempotencyKey`
- Fields: balance, held, status, currency (EGP), audit fields on transactions
- Composite index: `wallet_transactions` — `userId` + `createdAt` DESC

### 1-2 Callables

| Callable | Access | Purpose |
|----------|--------|---------|
| `getWallet` | Owner or admin | Wallet doc + recent transactions |
| `postWalletCredit` | Admin only | Manual credit (no admin UI yet) |

Files: `functions/src/quranSessions/walletService.ts`, `walletCallables.ts`  
Exported from `functions/src/index.ts`

### 1-3 Idempotency

- `postWalletCreditInTransaction` dedupes on `idempotencyKey` (posted txn replay)
- Admin callable wraps `runIdempotentOperation` (`post_wallet_credit:{userId}:{clientKey}`)
- Refund/comp keys: `wallet_credit:refund:{refundId}`, `wallet_credit:comp:{compensationId}`

### 1-4 Refund / compensation link

- `financialLedgerService.ts`: when `financialExecutionStatus() === "executed"`, posts wallet credit and sets `walletTransactionId` on refund/compensation docs
- **Current env:** provider off → status stays `manual_pending` → **no wallet write** (safe for Free Beta)
- Added `amount`, `currency`, `destination`, `walletTransactionId` on refund/compensation records

### 1-5 Firestore rules

- `user_wallets`: owner read, admin read, **client write deny**
- `wallet_transactions`: same
- Rules tests added: `functions/test-rules/wallet.rules.test.ts`

### 1-6 Admin read-only wallet

- Route: `/quran-sessions/wallets`, `/quran-sessions/wallets/:userId`
- Sidebar: Wallets
- Pattern: facade + `FirebaseWalletReadRepository` (mirrors session-reports)

### 1-7 Flutter read-only wallet

- Route: `/sessions/wallet` (entry from Quran Sessions home app bar)
- Package: entity, repository, use case, `WalletBloc`, `WalletScreen`
- Firestore read via `FirestoreWalletDataSource` in host app

### Phase 0 automatable

- Created [manual-e2e-runbook.md](../035-quran-session-staging-validation-sprint/manual-e2e-runbook.md)
- `seed:staging-teachers:apply` — **ran successfully** (5 teachers)

---

## Deferred (by design)

| Item | Phase |
|------|-------|
| PSP / `DisabledPaymentProvider` replacement | 2 |
| Wallet debit at checkout | 2+ |
| Admin issue-credit UI | 4 |
| Auto refund on cancel | 3 |
| Subscriptions, teacher payouts, mixed payment, card refund | Postponed |
| `resolveSessionDispute` financial UI enable | 3–4 |

---

## Test results

| Suite | Result | Notes |
|-------|--------|-------|
| `functions` `npm test` | **53/53 pass** | Includes 4 new `walletService.test.ts` |
| `functions` `npm run test:rules` | **Blocked** | firebase-tools requires Java ≥21 on this machine |
| `packages/quran_sessions` wallet widget test | **1/1 pass** | `wallet_screen_test.dart` |
| `flutter gen-l10n` (quran_sessions) | OK | Wallet strings |
| `dart analyze` (wallet paths) | OK | tilawa quran_sessions integration clean |
| `apps/tilawa_admin` build | Not run | User should `ng build` before deploy |

### Rules tests (manual unblock)

```sh
# Install JDK 21+, then:
cd functions && npm run test:rules
```

---

## Deploy checklist (staging)

```sh
cd functions && npm run build
firebase deploy --only functions:getWallet,functions:postWalletCredit
firebase deploy --only firestore:rules,firestore:indexes
```

Post-deploy: run wallet W1–W4 in [manual-e2e-runbook.md](../035-quran-session-staging-validation-sprint/manual-e2e-runbook.md).

---

## Go / No-Go for Phase 2

| Criterion | Status |
|-----------|--------|
| Wallet CF + idempotency unit tests green | ✅ |
| Rules deny client writes | ✅ (code); emulator ⬜ blocked on Java |
| Admin can view test user wallet | ✅ (code); needs staging deploy + manual |
| Flutter wallet read screen | ✅ |
| Refund execute → wallet link (when provider on) | ✅ (code path; inactive while provider off) |
| Phase 0 manual 16-step E2E | ⬜ **User still required** |
| Smoke 12/12 on staging | ⬜ re-run after deploy |

**Verdict:** **Conditional GO for Phase 2 planning** — code complete; staging deploy + manual E2E + rules emulator on JDK 21 before PSP sandbox work.

**Reminder:** Paid sessions still **OFF**. Do not set `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=true` until Phase 6 gates.

---

## Files touched (summary)

**Cloud Functions:** `walletService.ts`, `walletCallables.ts`, `financialLedgerService.ts`, `approveSessionRefund.ts`, `issueSessionCompensation.ts`, `sessionDisputeCallables.ts`, `index.ts`  
**Rules / indexes:** `firestore.rules`, `firestore.indexes.json`  
**Admin:** `user-wallets/*`, wallet repository/facade/use case, routes, sidebar, paths  
**Flutter:** `packages/quran_sessions` wallet domain/data/presentation + l10n; `apps/tilawa` Firestore datasource, routes, DI  
**Tests:** `walletService.test.ts`, `wallet.rules.test.ts`, `wallet_screen_test.dart`  
**Docs:** this log, `manual-e2e-runbook.md`
