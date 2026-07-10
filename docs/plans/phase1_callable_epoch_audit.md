# Phase 1 — Callable Safety Audit Without `sessionEpoch`

Status: **Complete (2026-07-06). Conclusion: safe to proceed to the epoch
no-op (task P1-4 / #12). No new guards required.**

Related: [ADR-008](../adr/008-multi-device-login-and-live-session-lock.md),
[plan §3](multi_device_and_live_session_lock_plan.md).

## Purpose

Before Phase 1 makes `requireValidSessionEpoch` a no-op under
`MULTI_DEVICE_LOGIN_ENABLED`, verify every callable that currently relies on it
is still safe **without** the epoch freshness guard. The epoch was a
device-exclusivity / "is this the active device" check — **not** an
authorization or replay check. Authorization must come from Firebase Auth +
ownership/participant checks; replay safety from idempotency keys + Firestore
transactions; correctness from status/time-window validation.

## Result matrix

Guards present per callable (all bind identity to `request.auth.uid`):

| Callable | Auth | Ownership / participant | Idempotency | Status/window | Epoch-free safe? |
|---|---|---|---|---|---|
| `issueSessionRtcToken` | ✅ | `resolveActorRole` (participant/admin) | n/a (issues token, mutates no state)¹ | join window + `lifecycleStatus` | ✅ |
| `createSessionBooking` | ✅ | `studentId = requireAuthenticatedUid` (not client-supplied) | ✅ key `studentId:slotId:startsAt` | booking policy + slot lock | ✅ |
| `cancelSessionBooking` | ✅ | `resolveActorRole` | ✅ | lifecycle guard | ✅ |
| `confirmBookingPayment` | ✅ | `studentId=auth.uid`; asserts `booking.studentId === studentId` (`not_participant`) | ✅ | status `scheduled` guard | ✅ |
| `getBookingPricingQuote` | ✅ | read-only; non-sensitive market pricing | n/a (read) | n/a | ✅ |
| `respondToBookingRequest` | ✅ | `resolveActorRole` (teacher-only) | ✅ | lifecycle guard | ✅ |
| `completeSession` | ✅ | `resolveActorRole` | ✅ | lifecycle guard | ✅ |
| `markSessionNoShow` | ✅ | `resolveActorRole` | ✅ | lifecycle guard | ✅ |
| `requestSessionReschedule` | ✅ | `resolveActorRole` | ✅ | lifecycle guard | ✅ |
| `confirmSessionReschedule` | ✅ | `resolveActorRole` + `assertRescheduleCounterpartyOnly` | ✅ | lifecycle guard | ✅ |
| `recordCallTelemetryEvent` | ✅ | `requireParticipantOrAdmin` | n/a² | n/a | ✅ |
| `walletCallables` (`getWallet`) | ✅ | `targetUserId !== callerUid && !isAdmin → permission-denied` (walletCallables.ts:57) | n/a (read) | n/a | ✅ |
| `walletCallables` (mutations) | ✅ | `requireAdmin` | ✅ | — | ✅ |
| `sessionReportCallables` | ✅ | participant / `requireAdmin` | ✅ | — | ✅ |
| `sessionDisputeCallables` | ✅ | `requireParticipantOrAdmin` | ✅ | — | ✅ |

¹ `issueSessionRtcToken` mutates no persistent state today; its device
exclusivity is intentionally **re-added** in Phase 2 as the per-session
`liveLocks` lease (not via epoch).

² `recordCallTelemetryEvent` has no idempotency key, but telemetry events are
append-only and harmless to double-write; participant auth is enforced. **Only
callable without idempotency** — acceptable, noted for awareness.

## Evidence (representative)

- `confirmBookingPayment.ts:43` `studentId = requireAuthenticatedUid(request)`;
  `:101` `if (booking.studentId !== studentId) throw not_participant`.
- `createSessionBooking.ts:166` `studentId = requireAuthenticatedUid(request)`;
  idempotency key `${studentId}:${slotId}:${startsAt}` — a second device cannot
  create a booking as another user, and replays collapse.
- `walletCallables.ts:57` non-admin cannot read another user's wallet.
- `getBookingPricingQuote.ts:70-82` auth-gated read of shared market pricing;
  no per-user secret exposed.

## Conclusion

Making `requireValidSessionEpoch` a no-op under the flag **does not weaken
authorization or replay safety** for any callable — every one derives identity
from `request.auth.uid`, checks ownership/participation, and (except telemetry)
is idempotent. **P1-4 (#12) may proceed.** No code changes were required by this
audit; the epoch was already redundant for authorization.
