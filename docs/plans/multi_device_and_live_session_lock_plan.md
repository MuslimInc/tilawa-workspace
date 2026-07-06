# Multi-Device Login & Per-Session Live Device Lock — Implementation Plan

Status: **Phase 0 implemented behind `deviceRegistryWriteEnabled` (staging ON,
production OFF); Phases 1–4 proposed / awaiting approval.**
Decision record: [ADR-008](../adr/008-multi-device-login-and-live-session-lock.md)

Phase 0 landed (additive, reversible — no login/`sessionEpoch`/`revokeRefreshTokens`
behavior change): launch flag `deviceRegistryWriteEnabled`
(`TILAWA_LAUNCH_DEVICE_REGISTRY_WRITE_ENABLED`); server schema/helpers in
`functions/src/deviceRegistry.ts`; opt-in dual-write of `users/{uid}/devices/{deviceId}`
inside `registerActiveDevice` (soft cap 5 surfaced via `deviceCapExceeded` /
`registeredDeviceCount`, never blocking); `firestore.rules` (owner-read, CF-only
write) + rules tests; client `DeviceRegistryRepository` (fetch-on-open) + flag
helper; unit/integration/rules/Flutter tests green. **Remaining before Phase 1:
deploy `firebase deploy --only functions,firestore:rules` and run staging
parity QA on a real project; do not default the flag on in production.**

Goal: allow normal multi-device login (no forced sign-out), while restricting
**live Learn Quran sessions to one active device per user per session**,
enforced server-side at the RTC-token gate, at predictable low Firebase cost.

---

## 1. Current codebase analysis

**Global single-device is enforced at the auth layer, not the session layer.**

Flow today:

```
sign-in / app open
  → registerActiveDevice (callable; txn on users/{uid})
       device changed ⇒ session.epoch += 1
                        session.activeDeviceId = thisDevice
                        getAuth().revokeRefreshTokens(uid)   ← kills all other devices
                        FCM "session_revoked" → old device
  → users/{uid}.session = { epoch, activeDeviceId, platform, deviceInfo, ... }
  → users/{uid}.notifications = { activeFcmToken, tokenUpdatedAt, platform }

any sensitive callable
  → client stamps payload.sessionEpoch (callable_session_payload_builder)
  → requireValidSessionEpoch: server epoch ≠ client epoch ⇒ "session_epoch_stale"
```

Server files:
- `functions/src/registerActiveDevice.ts` — registration txn, epoch bump,
  `revokeRefreshTokens`, `session_revoked` push, legacy `fcm_tokens` cleanup.
- `functions/src/quranSessions/sessionRegistration.ts` — pure planner
  (`planDeviceRegistration`, `assertClientSessionEpoch`, `readServerSessionEpoch`).
- `functions/src/quranSessions/sessionAuth.ts` — `requireValidSessionEpoch`,
  `requireAuthenticatedUid`, `resolveActorRole`, `requireParticipantOrAdmin`,
  `isAdmin`, `requireAdmin`.
- `functions/src/quranSessions/issueSessionRtcTokenService.ts` — the RTC join
  chokepoint (auth → joinable status → join window → participant role → mint
  Agora/LiveKit token). **This is where the live lock belongs.**

Client subsystem (`apps/tilawa/lib/features/auth/`):
- `data/datasources/active_device_remote_data_source[_impl].dart`
- `domain/usecases/register_active_device_use_case.dart`,
  `sync_device_token_use_case.dart`, `check_session_validity_use_case.dart`,
  `sign_out.dart`
- `domain/services/session_epoch_provider.dart`,
  `callable_session_payload_builder.dart`, `token_sync_cache.dart`,
  `session_revoked_notifier.dart`
- `data/services/pending_session_revoke_store.dart`, `token_sync_cache_impl.dart`
- `presentation/cubit/session_validity_cubit.dart`,
  `presentation/widgets/session_revoked_navigation_listener.dart`,
  `presentation/bloc/auth_bloc.dart` (+ `auth_event.dart`)

RTC facts:
- Both **Agora and LiveKit** are wired behind a provider abstraction
  (`callProviderResolver.ts`, `agoraTokenService.ts`, `livekitTokenService.ts`).
- LiveKit token uses `identity: uid` (no device dimension **yet**).
- Agora uses a numeric uid derived from the Firebase uid (no device dimension,
  and no reliable per-device eviction).
- **No RTDB presence, no heartbeat, no polling exists today.**

Key insight: `sessionEpoch` does two jobs — **device exclusivity** and
**client-freshness gating of money/booking writes**. Only the first must move;
the second must be *replaced with explicit guards*, not deleted.

---

## 2. `sessionEpoch` / `revokeRefreshTokens` blast radius

Server callables that currently read `sessionEpoch` / call
`requireValidSessionEpoch` (from grep of `functions/src`):

| # | Callable | File |
|---|---|---|
| 1 | `registerActiveDevice` | `registerActiveDevice.ts` |
| 2 | `issueSessionRtcToken` | `quranSessions/issueSessionRtcTokenService.ts` |
| 3 | `createSessionBooking` | `quranSessions/createSessionBooking.ts` |
| 4 | `cancelSessionBooking` | `quranSessions/cancelSessionBooking.ts` |
| 5 | `confirmBookingPayment` | `quranSessions/confirmBookingPayment.ts` |
| 6 | `getBookingPricingQuote` | `quranSessions/getBookingPricingQuote.ts` |
| 7 | `respondToBookingRequest` | `quranSessions/respondToBookingRequest.ts` |
| 8 | `completeSession` | `quranSessions/completeSession.ts` |
| 9 | `markSessionNoShow` | `quranSessions/markSessionNoShow.ts` |
| 10 | `requestSessionReschedule` | `quranSessions/requestSessionReschedule.ts` |
| 11 | `confirmSessionReschedule` | `quranSessions/confirmSessionReschedule.ts` |
| 12 | `recordCallTelemetryEvent` | `quranSessions/recordCallTelemetryEvent.ts` |
| 13 | wallet callables | `quranSessions/walletCallables.ts` |
| 14 | session report callables | `quranSessions/sessionReportCallables.ts` |
| 15 | session dispute callables | `quranSessions/sessionDisputeCallables.ts` |

Shared plumbing: `sessionAuth.ts` (`requireValidSessionEpoch`),
`sessionRegistration.ts` (`assertClientSessionEpoch`, `readServerSessionEpoch`).

Client blast radius: the entire `features/auth/` session-validity subsystem
listed in §1, plus every callable gateway that injects the epoch payload
(`callable_session_payload_builder`, `firebase_call_telemetry_gateway`, booking/
wallet/report gateways under `features/quran_sessions/data/firebase/`).

`revokeRefreshTokens(uid)` is called in exactly one place:
`registerActiveDevice.ts` on `deviceChanged`. Removing that single call is what
unblocks multi-device login — but it must be coordinated with the callable
migration so the epoch guard's *freshness* job is not silently lost.

---

## 3. Callable-by-callable migration plan

Principle: **replace, don't delete.** For each callable, the epoch check is
swapped for the explicit guard(s) that make it safe without device exclusivity.
All already run inside the Firebase Functions Admin context (authenticated) and
most already use `idempotencyService` and `sessionLifecycleGuard`.

Guard legend: **A**=Firebase Auth (`requireAuthenticatedUid`), **O**=ownership/
participant (`resolveActorRole` / `requireParticipantOrAdmin`),
**I**=idempotency key, **T**=Firestore transaction, **W**=status/time-window
validation, **L**=live device lock (new).

| Callable | Epoch's real job here | Replacement guards | Notes |
|---|---|---|---|
| `issueSessionRtcToken` | exclusivity + freshness | **A + O + W + L** | Add the live lock here (§5). Keep window checks. |
| `createSessionBooking` | freshness | **A + I + T + W** | Already idempotent; ownership = caller is student. |
| `cancelSessionBooking` | freshness | **A + O + I + T + W** | Participant-only; window/lifecycle guard. |
| `confirmBookingPayment` | freshness | **A + O + I + T** | Money path — keep idempotency + txn strict. |
| `getBookingPricingQuote` | freshness (read) | **A** | Read-only quote; drop epoch, no side effects. |
| `respondToBookingRequest` | freshness | **A + O + I + T + W** | Teacher-only actor via `resolveActorRole`. |
| `completeSession` | freshness | **A + O + I + T + W** | Also **clears `liveLocks`** on completion. |
| `markSessionNoShow` | freshness | **A + O + I + T + W** | Actor + lifecycle guard. |
| `requestSessionReschedule` | freshness | **A + O + I + T + W** | Counterparty rules already exist. |
| `confirmSessionReschedule` | freshness | **A + O + I + T + W** | `assertRescheduleCounterpartyOnly`. |
| `recordCallTelemetryEvent` | freshness | **A + O** | Low-value telemetry; participant-only, best-effort. |
| wallet callables | freshness (money) | **A + O + I + T** | Strictest — keep txn + idempotency; ownership = wallet owner. |
| session report callables | freshness | **A + O + I** | Participant-only; idempotent create. |
| session dispute callables | freshness | **A + O + I + T** | Participant/admin; audited. |
| `registerActiveDevice` | **the source** | rewritten (§4) | Stop `revokeRefreshTokens`; write device registry. |

Transition compatibility: `requireValidSessionEpoch` is replaced by a
`tolerateLegacySessionEpoch` no-op that accepts and ignores a `sessionEpoch`
field so older installed clients keep working during rollout. It is deleted only
in the final cleanup phase.

Acceptance per callable: unit test proving (a) unauthorized/non-participant is
rejected, (b) replay with same idempotency key is a no-op, (c) invalid
status/window is rejected, (d) a stale-epoch client is now *accepted* (guard no
longer device-exclusive).

---

## 4. Firestore data model

### 4.1 Device registry (replaces exclusive `activeDeviceId`)

```
users/{uid}/devices/{deviceId}
  platform:      "android" | "ios" | "web"
  fcmToken:      string          // current token for this device
  appVersion:    string
  deviceInfo:    { manufacturer, model, os, osVersion, appBuildNumber }  // sanitized allowlist (reuse SAFE_DEVICE_INFO_KEYS)
  lastSeenAt:    Timestamp       // rate-limited updates (§9)
  createdAt:     Timestamp
  revokedAt:     Timestamp|null  // set by "sign out this device"
```

- Non-exclusive: many devices may exist concurrently.
- **Soft cap = 5 devices** (`MAX_REGISTERED_DEVICES = 5`). Reaching the cap
  **never forces a logout during normal login** — registration still succeeds;
  the app surfaces the Manage Devices flow (§9) so the user can remove an old
  device. (Auto-eviction of the oldest `lastSeenAt` is a possible future
  refinement, but the decided direction is the user-driven Manage Devices flow.)
- `users/{uid}.session` retained only if we keep user-initiated "sign out other
  devices"; otherwise retired in Phase 4.
- Schema, constants, and pure builders live in
  `functions/src/deviceRegistry.ts` (`MAX_REGISTERED_DEVICES = 5`,
  `DEVICE_LAST_SEEN_MIN_INTERVAL_MS = 6h`, `buildDeviceRegistryDoc`,
  `isDeviceCapExceeded`, `shouldSkipLastSeenWrite`). No Firestore writes there —
  `registerActiveDevice` performs the upsert (Phase 0, task #3).

### 4.2 Live session lock (server-only fields on the existing session doc)

```
quran_sessions/{sessionId}
  ...existing...
  liveLocks: {                         // map keyed by uid; per-participant
    <uid>: {
      deviceId:   string,
      identity:   "<uid>#<deviceId>",  // LiveKit room identity for targeted eviction
      leaseUntil: Timestamp,           // == issued RTC token expiry
      lockEpoch:  number,              // bumps on takeover
      updatedAt:  Timestamp,
    }
  }
```

No new collection and no extra read: `issueSessionRtcToken` already fetches this
document. Lock is cleared on `completeSession` / `finalizeElapsedSessions`, and
otherwise self-expires via `leaseUntil`.

---

## 5. Cloud Function flow (`issueSessionRtcToken`, augmented)

Existing validations stay (auth → joinable status → join window → participant
role). A lock transaction is inserted **before** minting the token:

```
issueSessionRtcToken({ sessionId, deviceId, forceTakeover? })
  uid = requireAuthenticatedUid(request)
  load session; assert callProvider ∈ {agora,livekit}
  assert lifecycleStatus ∈ JOINABLE_STATUSES
  assert within join window (existing sessionJoinWindowPolicy)
  resolveActorRole(...)                         // participant or admin only

  txn(sessionRef):
     lock = session.liveLocks[uid]; now = serverTime
     if lock == null || lock.leaseUntil < now || lock.deviceId == deviceId:
        grant; evictIdentity = null
     else if forceTakeover === true:
        grant; evictIdentity = lock.identity; lockEpoch = lock.lockEpoch + 1
     else:
        throw already_active_on_other_device { activeDeviceInfo, sinceTs }
     set session.liveLocks[uid] = {
        deviceId, identity: `${uid}#${deviceId}`,
        leaseUntil: now + TOKEN_TTL, lockEpoch, updatedAt: now
     }

  // post-commit
  if evictIdentity && provider == livekit:
      RoomServiceClient.removeParticipant(room, evictIdentity)
  if evictIdentity:
      FCM "session_taken_over" → old device token (device-targeted)
  mint token: identity = `${uid}#${deviceId}` (livekit) / uid-derived (agora),
              expiry = leaseUntil
  return { token, channelId, callProvider, uid, appId }
```

- **Renewal = same call, same `deviceId`** → `lock.deviceId == deviceId` branch
  → instant re-grant, lease extended. This is the "heartbeat", but it is the
  token refresh the provider already forces → **free, no extra writes**.
- **Cleanup:** `completeSession` and `finalizeElapsedSessions`
  `FieldValue.delete()` the `liveLocks` map. Abandoned locks expire via
  `leaseUntil`. **No dedicated cron for locks.**

---

## 6. Flutter client flow

```
Join tapped:
  deviceId = stableDeviceId()            // from device registry
  issueSessionRtcToken(sessionId, deviceId)
    ok  → connect to LiveKit/Agora with token; schedule refresh at leaseUntil - margin
    err already_active_on_other_device:
        show sheet "Active on <Galaxy S23>. Switch here? Other device disconnects."
          [Switch to this device] → issueSessionRtcToken(..., forceTakeover: true)
          [Cancel]

During call:
  at leaseUntil - margin → re-issue with same deviceId (lock renew, no prompt)
  FCM session_taken_over        → leave room, show "Moved to another device"
  FCM force_disconnect_from_room→ hard leave
  FCM refresh_live_session_state→ re-fetch lifecycle status
  network drop                  → provider auto-reconnects with still-valid token; lease untouched

App killed → reopened SAME device:
  re-join → lock.deviceId matches → instant re-grant, no prompt
```

- Reuse existing `session_revoked` push/notifier plumbing, **rescoped** to the
  session (`session_taken_over`) — never a whole-app sign-out.
- New DI: `LiveSessionLockClient` (wraps `issueSessionRtcToken` with
  takeover), `DeviceRegistryRepository` (register/list/revoke devices).
- Remove epoch stamping (`callable_session_payload_builder`,
  `session_epoch_provider`) in Phase 4; keep tolerated during transition.

---

## 7. FCM routing rules

| Message | Scope | Target | Collapse key |
|---|---|---|---|
| booking created/confirmed/canceled/rescheduled | account | all `users/{uid}/devices/*` active tokens | `booking_<bookingId>` |
| session reminder | account | all active devices | `reminder_<sessionId>` |
| payment completed/failed | account | all active devices | `payment_<bookingId>` |
| teacher accepted/rejected booking | account | all active devices (student) | `booking_<bookingId>` |
| `session_taken_over` | device | old device token only | `livelock_<sessionId>_<uid>` |
| `leave_live_session` | device | specific device | `livelock_<sessionId>_<uid>` |
| `force_disconnect_from_room` | device | specific device | `livelock_<sessionId>_<uid>` |
| `refresh_live_session_state` | device | specific device | `livestate_<sessionId>_<uid>` |

Rules:
- Account-level fan-out iterates `users/{uid}/devices`, sends to each `fcmToken`.
- On `messaging/registration-token-not-registered` (or `invalid-argument`),
  **prune** that device's token (`revokedAt` or delete doc). Reuse the existing
  best-effort try/catch pattern from `sendSessionRevokedPush`.
- Collapse keys dedupe rapid repeats (e.g. reminder retries) → no spam.
- Control messages use `android.priority: high` + apns `content-available` (as
  `registerActiveDevice.ts` already does) so they wake a backgrounded client.

---

## 8. LiveKit-first / Agora fallback strategy

- **Strategic provider: LiveKit.** Token `identity = uid#deviceId` enables
  server-side **targeted eviction** via `RoomServiceClient.removeParticipant`,
  plus webhooks for authoritative presence (no RTDB, no polling).
- **Agora (transition/MVP):** keep behind the existing `callProviderResolver`
  abstraction, but **deny-only** — a second device is refused at the lock; the
  old device is not actively kicked and simply drops when its token expires. The
  Firestore lock still guarantees correctness (only one *valid* token per user
  per session at a time); only the *immediacy* of eviction differs.
- `IssueSessionRtcTokenResult.callProvider` already distinguishes providers;
  eviction path is gated on `callProvider === "livekit"`.
- Long-term: converge all live video on LiveKit; retire Agora once parity and
  cost are validated (tracked separately, ADR-002 keeps it swappable).

---

## 9. Optional Manage Devices feature (Settings → Security)

- **Fetch-on-open only** — a one-shot `getDevices` (single collection read of
  `users/{uid}/devices`); **no real-time listener.**
- Row per device: label (`manufacturer model`), platform, app version, last
  active, notification status, **"This device"** badge for the current one.
- Actions (all **server-controlled** via callables, never client Firestore
  writes):
  - **Sign out this device** → `revokeDevice(deviceId)` (marks `revokedAt`,
    prunes token; optionally per-device refresh-token revoke).
  - **Sign out all other devices** → `revokeOtherDevices()` — the explicit
    security action that *may* still call `revokeRefreshTokens(uid)` for
    everyone-but-me. This is the **only** sanctioned use of the old hammer.
- **`lastSeenAt` rate-limiting:** update at most once per N hours per device
  (compare server `lastSeenAt` before writing) to avoid write churn.

---

## 10. Cost & security analysis

**Cost**
- Per join: 1 transaction (1 read of an already-read doc + 1 write) ≈ today's cost.
- Per session/user: ~1 acquire + 0–3 renewals (only if session outlives token
  TTL) + 1 clear on completion → single-digit writes.
- **No heartbeat, no polling, no persistent listener** for enforcement.
- Presence UI (optional) from LiveKit webhooks/participant events → zero extra
  Firestore cost.
- Net **cheaper** than today after dropping `sessionEpoch` stamping/validation
  on 14 callables.

**Security**
- RTC token is **server-minted** → the lock is unforgeable; a tampered client
  cannot join without a valid token.
- `firestore.rules`: `liveLocks` and `users/{uid}/devices` are
  **Cloud-Functions-only** (deny all client writes); device read is own-user
  only. (Memory: *new collections need matching firestore.rules*.)
- `forceTakeover` authorized only for the lock's own `uid` — a user evicts only
  their own device; **never** the counterparty. Enforced by keying the lock on
  `request.auth.uid`.
- Device removal / sign-out is server-controlled callables only.
- Idempotency + transactions retained on all money/booking paths (§3).

---

## 11. Failure scenarios

| Scenario | Behavior |
|---|---|
| Open on A, then B | B → `already_active_on_other_device` + A's label → "Switch here?" prompt. |
| App killed mid-session | Lease persists to token expiry. Reopen on **A** → instant reclaim (deviceId match). Reopen on **B** → takeover prompt. |
| Network drops | Provider auto-reconnects with still-valid token; lease untouched; no server call. |
| Intentional switch | Explicit **Switch to this device** → `forceTakeover` → LiveKit `removeParticipant` + `session_taken_over` FCM to A. |
| Two devices race | Firestore txn serializes; first commit wins; second reads updated lock → takeover prompt. No race. |
| Stale lock (crash) | Auto-expires at `leaseUntil`; also cleared on completion. Same device reclaims instantly. |
| Teacher & student both join | Different uids → different lock keys → both hold locks → both live. |
| Old client (still sends `sessionEpoch`) | Server tolerates + ignores the field; call succeeds; no forced logout. |

---

## 12. Phased rollout (behind feature flags)

Flags follow the existing `AppLaunchConfig` / `TILAWA_LAUNCH_*` convention
(staging default ON, production OFF) — see the Learn Quran release-gating memory.

- **Phase 0 — Device registry (additive, no behavior change).**
  Introduce `users/{uid}/devices`; have `registerActiveDevice` **also** write it
  while still doing the old exclusive behavior. Ship `firestore.rules` for the
  new subcollection. Flag: `deviceRegistryWriteEnabled`.

- **Phase 1 — Enable multi-device login.**
  Stop `revokeRefreshTokens` on device change; stop writing exclusive
  `activeDeviceId`; server tolerates+ignores `sessionEpoch`; FCM fan-out reads
  the registry. Client stops treating `session_revoked` as global logout. Flag:
  `multiDeviceLoginEnabled`. **This is the requirement's core UX change.**

  **Phase 1 decisions (settled 2026-07-06):**
  1. **Server gate = Functions param/env** `MULTI_DEVICE_LOGIN_ENABLED` (default
     off, staging on) — version-independent, unspoofable, no per-call read; not
     a config doc. The client `multiDeviceLoginEnabled` flag gates client UX.
  2. **Soft cap: surface only, no enforcement in Phase 1.** Keep returning
     `deviceCapExceeded`; do **not** block a 6th device's login (no Manage
     Devices UI yet → would strand users). Cap UX deferred to Phase 3.
  3. **Keep "sign out other devices" as a user-initiated action.** Phase 1
     removes only the *automatic* revoke; `revokeRefreshTokens` survives for the
     explicit action (wired in Phase 3). Specific-device sign-out = registry
     `revokedAt` + FCM-token prune (Firebase auth revoke is per-user only).
     `users/{uid}.session` retained through Phase 1 for old-client epoch compat;
     retired in Phase 4.
  4. **`session_revoked` push left dormant in Phase 1** (auto-revoke stops, so
     it is no longer sent). Client stops treating it as global logout;
     repurposed as device-targeted `session_taken_over` in Phase 2.

- **Phase 2 — Live-session lock.**
  Add `liveLocks` + `forceTakeover` to `issueSessionRtcToken`; LiveKit
  `identity = uid#deviceId` + eviction; client join/switch UX + device-targeted
  control FCM. Clear locks in `completeSession`/`finalizeElapsedSessions`. Flag:
  `liveSessionDeviceLockEnabled`.

- **Phase 3 — Manage Devices screen** (optional, §9). Flag:
  `manageDevicesScreenEnabled`.

- **Phase 4 — Cleanup.**
  Delete `requireValidSessionEpoch`/`assertClientSessionEpoch`, epoch stamping,
  and the client `session_validity` subsystem; retire `users/{uid}.session`
  unless kept for "sign out other devices". Only after Phases 1–2 are default-on
  in production and old clients have aged out.

Each phase is independently revertible via its flag; production stays on the
legacy path until staging parity QA passes for that phase.

---

## 13. Required tests

**Functions (Vitest/Jest under `functions/test`)**
- `issueSessionRtcToken`: grant when no lock / expired lease / same device;
  deny on different device without takeover; takeover overwrites lock, bumps
  `lockEpoch`, evicts old identity (LiveKit), sends `session_taken_over`;
  teacher+student hold independent locks; lock cleared on `completeSession`.
- Race: two concurrent transactions → exactly one holds the lock.
- Per-migrated-callable (§3): rejects non-participant; idempotent replay is a
  no-op; invalid status/window rejected; **stale-epoch client now accepted**.
- `registerActiveDevice` rewrite: writes registry, does **not** revoke tokens,
  multi-device coexistence.
- FCM: account fan-out hits all devices; control message device-targeted; stale
  token pruned on send failure; collapse key set.
- `revokeOtherDevices`: revokes all but caller; `revokeDevice` prunes one.
- Firestore rules tests (`functions/test-rules`): client cannot write
  `liveLocks` or `users/{uid}/devices`; can read own devices only.

**Flutter (`apps/tilawa/test`, package:checks + fakes)**
- Join happy path; `already_active_on_other_device` → switch sheet →
  `forceTakeover` succeeds; same-device reopen re-grants without prompt.
- Token refresh renews lease with no prompt; `session_taken_over` leaves room
  without app sign-out.
- Multi-device login: second login does not sign out the first (fake
  auth/device registry).
- Manage Devices: fetch-on-open (no listener), sign-out-this-device,
  sign-out-others; `lastSeenAt` rate-limit respected.

---

## Decided direction (2026-07-06)

The former open questions are settled as the recommended direction. Status stays
**Proposed — awaiting approval**; no production code lands until approved.

1. **Soft cap of 5 registered devices** per user (§4.1). Normal login never
   forces a logout; the user resolves the cap later via Manage Devices (§9).
2. **Remove global `sessionEpoch` from non-RTC callables — incrementally,
   callable-by-callable** (§3), never blindly. Each removal is replaced with
   Firebase Auth + ownership checks + idempotency keys + Firestore transactions +
   status/time-window validation.
3. **LiveKit is the preferred long-term provider**, optimized around
   `identity = uid#deviceId` for targeted eviction (§8). **Agora stays behind the
   provider abstraction only for MVP/transition**, with **deny-only** eviction
   accepted where per-device eviction is not reliable.
