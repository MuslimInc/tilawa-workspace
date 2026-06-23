# Free Beta staging readiness — Quran sessions

Production remains **No-Go** until staging smoke passes and deploy is verified.

## Deploy (staging / production — manual)

From repo root:

```sh
# 1. Cloud Functions (all quran session callables)
cd functions && npm run build
firebase deploy --only functions:createSessionBooking,functions:cancelSessionBooking,functions:requestSessionReschedule,functions:confirmSessionReschedule,functions:markSessionNoShow,functions:completeSession,functions:issueSessionCompensation,functions:approveSessionRefund,functions:openSessionDispute,functions:resolveSessionDispute,functions:reportSessionConcern,functions:resolveSessionReport,functions:expirePendingReservations

# Or full functions deploy:
firebase deploy --only functions

# 2. Firestore security rules (account moderation hardening)
firebase deploy --only firestore:rules
```

## Backfill (after deploy)

```sh
cd functions

# Dry-run booking/session lifecycle mismatches
npm run quran-sessions:backfill-booking-session-consistency -- --dry-run

# Apply
npm run quran-sessions:backfill-booking-session-consistency -- --apply

# Legacy lifecycle status backfill (if not already run)
npm run quran-sessions:backfill-lifecycle
```

## Local verification (CI / pre-deploy)

```sh
cd functions
npm install
npm run build
npm test
npm run test:integration   # requires JDK 21+ for Firestore emulator
npm run test:rules           # Firestore rules unit tests
```

## Staging smoke checklist

Run against staging Firebase project with test accounts (student, teacher, admin).

| # | Check | Pass criteria |
|---|-------|---------------|
| 1 | Unauthorized cancel | Non-participant receives `permission-denied` / `not_participant` |
| 2 | Blocked user self-unblock | Client `users/{uid}` update of `accountStatus` → `active` **denied** by rules |
| 3 | Blocked user booking | `createSessionBooking` returns `account_blocked` |
| 4 | Booking idempotency | Same `idempotencyKey` twice → same `bookingId`, one booking doc |
| 5 | Slot lock | Different idempotency key, same slot → `already-exists` |
| 6 | Duplicate refund | `approveSessionRefund` same key twice → one refund ledger doc |
| 7 | Dispute refund ledger | `resolveSessionDispute` `favor_student` → `quran_session_refunds` with `manual_pending` |
| 8 | Dispute compensation ledger | `resolveSessionDispute` `with_compensation` → compensation doc `manual_pending` |
| 9 | Expiry sync | Expired `pending_payment` booking → session `lifecycleStatus` also `expired` |
| 10 | Paid teacher blocked | Paid teacher booking → `payment_provider_unavailable` (not silent success) |

## P0 fixes in this pass

- `financialLedgerService.ts` — shared `issueRefundRecord` / `issueCompensationRecord`
- `resolveSessionDispute` — financial resolutions use ledger helpers + notifications
- `createSessionBooking` — `idempotencyKey` + `runIdempotentOperation`
- `firestore.rules` — `quranSessionsProfile.accountStatus` / `restrictionReason` owner-immutable
- Flutter gateway sends deterministic `idempotencyKey`
- Integration + rules tests

## Free Beta Go/No-Go

| Gate | Status |
|------|--------|
| P0 code complete | ✅ (this pass) |
| Emulator tests pass locally | Run `npm run test:integration` + `npm run test:rules` |
| Staging deploy | ⬜ Manual |
| Staging smoke (10 checks) | ⬜ Manual |
| Backfill run on staging data | ⬜ Manual |

**Recommendation:** **Conditional No-Go** — code ready for staging deploy + smoke. **No-Go** for production until staging smoke passes.
