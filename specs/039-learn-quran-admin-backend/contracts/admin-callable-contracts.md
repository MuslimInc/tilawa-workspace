# Admin Callable Contracts

The implementation consumes these existing contracts. It does not replace them
with direct Firestore writes.

## `updatePlatformConfig`

**Caller**: administrator only.  
**Purpose**: writes global policy and an audit event.

The admin must round-trip every supported global value, including
`childAgeThreshold`. `sessionMode` is only `videoOnly`; booking mode is
`requiresTutorApproval` or `autoConfirm`.

## `updateMarketPricingConfig`

**Caller**: administrator only.  
**Purpose**: writes one market's supported policy, city price overrides, and an
audit event.

The request accepts availability, price/currency, scheduling/eligibility,
payment values, and city overrides. It does **not** accept a market
`sessionMode`; the UI must not imply otherwise.

## `resolveSessionReport`

**Caller**: administrator only.

```text
reportId: string
resolution: under_review | resolved | dismissed
reason?: string
idempotencyKey?: string
```

`reportId` and an allowed resolution are required. `resolved` and `dismissed`
require a non-empty reason. The response reports the resulting status and the
server records audit/terminal metadata where applicable.

## `resolveSessionDispute`

**Caller**: administrator only.

```text
bookingId: string
disputeId: string
resolution: favor_student | favor_teacher | with_compensation | rejected | closed
reason: string
idempotencyKey?: string
```

The server requires an existing disputed booking and a reason. It owns related
lifecycle, audit, notification, and refund/compensation effects; the client
reloads authoritative state after success.

## App Check options

`QURAN_SESSIONS_ENFORCE_APP_CHECK` controls callable enforcement at deployment
time. It is not an admin setting. Production enforcement requires completed
staging evidence and a documented rollback result.

