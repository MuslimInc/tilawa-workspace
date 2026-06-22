# P0 production readiness — Quran sessions lifecycle

Status: **No-Go** until follow-up audit after deploy + backfill.

## Implemented (this pass)

| Blocker | Fix |
|---------|-----|
| Missing server lifecycle guard | `functions/src/quranSessions/sessionLifecycleGuard.ts` |
| Weak authorization | `functions/src/quranSessions/sessionAuth.ts` on all callables |
| Missing idempotency | `functions/src/quranSessions/idempotencyService.ts` |
| Missing `approveSessionRefund` | `functions/src/quranSessions/approveSessionRefund.ts` |
| Missing dispute flow | `openSessionDispute`, `resolveSessionDispute` |
| Compensation/refund honesty | `manual_pending` execution status when no provider |
| `markSessionNoShow` payload drift | Unified `classification` + `actorRole` contract |
| Booking/session inconsistency on create + expiry | Same `lifecycleStatus` on both docs; expiry updates session |
| Paid booking without provider | `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` gate |
| Admin refund to missing CF | Wired `approveSessionRefund` export |
| Firestore snake_case drift (Flutter read) | `parseLifecycleStatus` in mapper |

## Callable contracts (canonical)

### `markSessionNoShow`

```json
{
  "sessionId": "string",
  "classification": "teacher_no_show | student_no_show | both_no_show",
  "actorRole": "student | teacher | admin | system",
  "reason": "string?",
  "idempotencyKey": "string?"
}
```

`classification` required for admin/system. Teacher may omit → `student_no_show`.

### `approveSessionRefund` (admin)

```json
{
  "bookingId": "string",
  "reason": "string",
  "amountUsd": "number?",
  "idempotencyKey": "string?"
}
```

Response includes `refundExecutionStatus`: `manual_pending` | `executed`.

### `issueSessionCompensation` (admin)

`payment_refund` rejected — use `approveSessionRefund`.

### `openSessionDispute`

```json
{
  "bookingId": "string",
  "reason": "string",
  "evidenceMetadata": "object?",
  "idempotencyKey": "string?"
}
```

### `resolveSessionDispute` (admin)

```json
{
  "bookingId": "string",
  "disputeId": "string",
  "resolution": "favor_student | favor_teacher | with_compensation | rejected | closed",
  "reason": "string",
  "idempotencyKey": "string?"
}
```

## Idempotency strategy

- Collection: `quran_session_operations`
- Key: `{action}:{entityId}:{idempotencyKey|default}`
- Completed ops return cached result; pending ops abort retry with `aborted`

## Migration / backfill

Run after deploy:

```sh
cd functions && npm run quran-sessions:backfill-lifecycle
npm run quran-sessions:backfill-booking-session-consistency -- --dry-run
```

`backfillBookingSessionConsistency` (add script) should:

1. Find bookings where `lifecycleStatus != session.lifecycleStatus`
2. Set session `lifecycleStatus` to booking canonical value
3. Log aggregate IDs to audit collection

## Remaining No-Go items (follow-up audit)

- [ ] Deploy all new callables to production Firebase project
- [ ] Firestore security rules for `quran_session_operations`, disputes, refunds
- [ ] End-to-end admin refund/dispute smoke on staging
- [ ] Real payment provider integration + `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=true`
- [ ] App Check on session callables
- [ ] Maestro / integration tests for mobile cancel + no-show

## Go/No-Go recommendation

**No-Go** for paid sessions and automated money movement.

**Conditional No-Go** for free-session beta: deploy functions + run backfill, then re-audit auth/guard tests in staging.
