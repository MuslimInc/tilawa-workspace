# Quran Sessions — Backend Enforcement Summary

**Last updated:** 2026-07-03  
**Scope:** Cloud Functions + Firestore admin config (production rules, not MVP)

---

## 1. Cloud Functions implementation

| Area | Files | Notes |
|------|-------|-------|
| Booking creation | `functions/src/quranSessions/createSessionBooking.ts` | Idempotency, slot lock, fee snapshot, market policy, allowed actions denorm |
| Eligibility | `functions/src/quranSessions/bookingEligibilityService.ts` | Child age + `canTeachChildren`, whitelist, gender toggle, min notice, max upcoming, **policy config validation** |
| Market policy loader | `functions/src/quranSessions/sessionPolicyResolver.ts` | Versioned market docs + platform defaults + `assertBookingPolicyConfigured` |
| Allowed actions | `sessionAllowedActionsService.ts`, `aggregateWriteService.ts` | Q-SR-02 denorm on **every** lifecycle write via `writeAggregateLifecycle` |
| Idempotency | `functions/src/quranSessions/idempotencyService.ts` | 24h dedupe window (Q-BK-04) |
| Join window | `sessionJoinWindowPolicy.ts`, `issueSessionRtcTokenService.ts` | 15m before `startsAt` until `endsAt` |
| In-progress | `sessionInProgressTransitionPolicy.ts`, `callTelemetryService.ts` | Join-driven `in_progress` (Q-SL-03) |
| Expiry jobs | `expirePendingReservations.ts` | 15m payment hold + tutor approval SLA |
| Video-only | `callProviderResolver.ts`, booking eligibility | Rejects non-`videoCall` when `sessionMode=videoOnly` |
| Scheduling constants | `platformSchedulingPolicy.ts` | Mirrors Dart `PlatformSchedulingPolicy` |

Lifecycle mutators that recompute allowed actions (via `writeAggregateLifecycle` + `timingSource`):

- `createSessionBooking` (on create)
- `respondToBookingRequest`, `cancelSessionBooking`
- `expirePendingReservations`, `confirmBookingPayment`
- `requestSessionReschedule`, `confirmSessionReschedule`
- `completeSession`, `markSessionNoShow`
- `callTelemetryService` (join → `in_progress`)
- `sessionDisputeCallables`, `financialLedgerService`

---

## 2. Admin config schema

See `admin-config-seed.md` for seed commands and required fields.

### Platform — `quran_session_platform_config/global`

| Field | Type | Purpose |
|-------|------|---------|
| `quranTutorBookingMode` | `autoConfirm` \| `requiresTutorApproval` | Default booking path (Q-BK-01) |
| `sessionMode` | `videoOnly` \| `freeBeta` | Call modality ceiling (Q-VC-01) |
| `enabledCallProviders` | `string[]` | RTC provider rollout (Q-VC-02) |
| `childAgeThreshold` | `number` | Child safety |
| `genderMatchingEnabled` | `boolean` | Global gender ceiling |

**Deprecated (ignored):** `requireGuardianApprovalForChildren` — guardian approval removed 2026-07-04.

### Market — `quran_session_market_configs/{countryCode}`

| Field | Type | Purpose |
|-------|------|---------|
| `isEnabled` | `boolean` | Market rollout (Q-AD-02) |
| `minSessionPrice` | `number` | Authoritative session fee (Q-FE-01) |
| `currencyCode` | `string` | Fee currency |
| `cities[]` | array | Per-city enable + price override |
| `quranTutorBookingMode` | enum | Market booking override |
| `teacherWhitelist` | `string[]` | Soft-launch teacher IDs |
| `genderMatchingEnabled` | `boolean` | Market gender toggle (Q-BK-05) |
| `tutorApprovalSlaHours` | `number` | Default 24h (Q-TA-01) |
| `minBookingNoticeMinutes` | `number` | Min lead time |
| `maxConcurrentUpcomingPerStudent` | `number` | Cap concurrent bookings |
| `joinWindowLeadMinutes` | `number` | Join prefetch window |
| `activePolicyVersion` | `string` | Points to version doc (Q-AD-01) |
| `policyEffectiveFrom` | `timestamp` | Version effective date |

### Booking denormalization (written by CF)

| Field | Purpose |
|-------|---------|
| `feeSnapshot` | `{ amount, currencyCode, pricingType, policyVersion, capturedAt }` |
| `paymentExpiresAt` | 15m pending payment TTL |
| `approvalExpiresAt` | Tutor approval SLA expiry |
| `allowedActionsStudent` / `allowedActionsTeacher` | Q-SR-02 action lists (refreshed on lifecycle transitions) |
| `allowedActionsUpdatedAt` | ISO timestamp of last recompute |
| `joinWindowLeadMs` | Per-booking join window |
| `lifecycleStatus` + `status` | Dual-write during migration (Q-SL-01) |

---

## 3. Firestore migration / indexes

- **Dual-write:** CF continues writing `lifecycleStatus` + legacy `status` via `legacyStatusForLifecycle`.
- **Backfill:** See `lifecycle-backfill-checklist.md`.
- **New index:** `quran_bookings` composite `(lifecycleStatus ASC, paymentExpiresAt ASC)`.
- **Existing index:** `(lifecycleStatus ASC, approvalExpiresAt ASC)`.

---

## 4. Flutter wiring

| Change | File |
|--------|------|
| Parse server allowed actions | `session_firestore_mapper.dart` |
| Prefer server actions in detail UI | `session_detail_state.dart` |
| Fake backend blocked in staging/prod | `quran_sessions_backend_config.dart` |
| Video-only hides external meeting URL | `complete_teacher_public_profile_screen.dart` |
| Teacher pending requests above upcoming | `get_teacher_dashboard_usecase.dart` + `teacher_dashboard_screen.dart` |

---

## 5. Remaining blockers before production launch

1. **Paid booking** — payment provider disabled; wallet/checkout not production-ready.
2. **Lifecycle backfill** — legacy `status`-only docs must be backfilled before dropping dual-write.
3. **App Check** — enforce on production callables after staging soak (`app-check-staging-plan.md`).
4. **Admin Panel UI** — policy editor still missing; use `admin-config-seed.md`.
5. **Reschedule pending denorm** — `hasPendingReschedule` not yet stored for allowed-actions recompute.

---

## 6. Test commands

```sh
cd functions && npm test
cd functions && npm run test:integration
cd packages/quran_sessions && dart test test/domain/policies/
cd packages/quran_sessions && dart test test/presentation/screens/complete_teacher_public_profile_screen_test.dart
cd apps/tilawa && flutter test test/features/quran_sessions/quran_sessions_launch_policy_test.dart
```

Key test files:

- `functions/test/quranSessions/allowedActionsTransition.test.ts`
- `functions/test/quranSessions/sessionPolicyResolver.test.ts`
- `functions/test-integration/productionFlow.integration.test.ts`
