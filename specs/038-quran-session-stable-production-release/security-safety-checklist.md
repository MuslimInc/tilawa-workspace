# Security & Safety Checklist — Stable Production v1

## Authentication & authorization

| Check | Status | Notes |
|-------|--------|-------|
| All session CFs require Auth | ✅ | `requireAuthenticatedUid` |
| Student cannot claim teacher/admin role | ✅ | `resolveActorRole` |
| Admin gated by custom claim | ✅ | `requireAdmin` |
| Teacher participant uses profile `userId` not doc id | ✅ (038) | `resolveTeacherProfileUserId` |
| Non-participant booking reads denied | ✅ | Firestore rules |
| Guardian can report for child | ✅ | `sessionReportCallables` |

## Firestore rules

| Collection / field | Client write | Status |
|--------------------|--------------|--------|
| `quran_bookings` | Denied | ✅ |
| `quran_sessions` (incl. provider fields) | Denied | ✅ |
| `quran_session_disputes/reports` | Denied | ✅ |
| `quran_session_operations/notifications` | Denied | ✅ |
| `users.session` / `users.notifications` | Denied (owner) | ✅ |
| Teacher trust fields | Frozen on owner update | ✅ |
| `quranSessionsProfile.accountStatus` | Frozen (owner) | ✅ |
| `quranSessionsProfile` eligibility fields | Frozen (owner) | ✅ (038) |
| `fcm_tokens` subcollection | Denied (owner write) | ✅ |

## Lifecycle & integrity

| Check | Status |
|-------|--------|
| Transition table enforced server-side | ✅ |
| Cancel min notice (student) | ✅ |
| Idempotency on mutations | ✅ |
| Group booking rejected | ✅ |
| Client cannot force agora/webrtc provider | ✅ |
| Pricing derived server-side | ✅ |
| `sessionEpoch` required on mutations (non-admin) | ✅ |

## Single-active-device

| Check | Status | Limitation |
|-------|--------|------------|
| `registerActiveDevice` bumps epoch + revokes tokens | ✅ | |
| Client cannot write epoch/FCM server fields | ✅ | |
| Stale epoch rejected on booking | ✅ | Integration test |
| Epoch readable by owner | ⚠️ | ~1h ID token window after revoke |

## App Check

| Check | Status |
|-------|--------|
| Session CFs enforce App Check | ⚠️ **Staged** — opt-in via `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` + redeploy |
| Client activates App Check in release | ✅ (CF enforcement off until ops flips env) |

**Rollout (do not skip staging):**

1. Confirm release builds send App Check tokens (Play Integrity / DeviceCheck).
2. Deploy session CFs with env **unset** (default off) — no behavior change.
3. Set `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` on **staging** only; redeploy session CFs.
4. Run manual B1–B5 / T2–T8 + Agora staging checklist on staging build.
5. If green, enable same env on production before wide Play rollout.
6. Rollback: unset env or set `false` and redeploy (same as kill-switch layer 6 latency).

**Covered callables:** `createSessionBooking`, `cancelSessionBooking`, `requestSessionReschedule`, `confirmSessionReschedule`, `completeSession`, `markSessionNoShow`, `openSessionDispute`, `resolveSessionDispute`, `reportSessionConcern`, `resolveSessionReport`, `issueSessionRtcToken`, `registerActiveDevice`.

**Not in stable batch (still `enforceAppCheck: false`):** wallet/payment callables (`getWallet`, `confirmBookingPayment`, …), teacher moderation CFs.

## Child safety / eligibility

| Check | Status |
|-------|--------|
| Server reads eligibility from user profile | ✅ |
| Client cannot change gender/DOB/location after set | ✅ (038) |
| Gender matching policy server-side | ✅ |
| Guardian approval flags | ✅ |

## Pre-release verification commands

```sh
# Rules tests (JDK 21)
cd functions && npm run test:rules

# Session auth unit tests
npm test -- test/quranSessions/sessionAuthHelpers.test.ts

# Integration (emulator)
npm run test:integration

# Flutter preflight
./scripts/quran_sessions_preflight.sh
```

## Sign-off

- [ ] Rules deployed to staging before app release
- [ ] CF deployed matching app epoch contract
- [ ] No client write path to booking/session ledgers verified
- [ ] Eligibility immutability rules test green
- [ ] Teacher auth integration scenario (profile id ≠ uid) verified
