# ADR-008: Multi-Device Login & Per-Session Live Device Lock

**Status:** Proposed
**Date:** 2026-07-06
**Deciders:** Engineering team
**Related:** [ADR-002](002-quran-sessions-backend-agnostic-architecture.md),
[ADR-005](005-quran-sessions-lifecycle-legacy-bridge.md),
[ADR-007](007-learn-quran-entry-strategy.md)
**Implementation plan:** [`docs/plans/multi_device_and_live_session_lock_plan.md`](../plans/multi_device_and_live_session_lock_plan.md)

---

## Context

The app currently enforces **single active device globally, at the auth layer.**
`registerActiveDevice` runs a transaction on `users/{uid}` that, on any device
change, bumps `session.epoch`, overwrites `session.activeDeviceId`, calls
`getAuth().revokeRefreshTokens(uid)`, and pushes a `session_revoked` FCM
message to the old device. Sensitive callables then reject any client whose
`sessionEpoch` ≠ the server epoch via `requireValidSessionEpoch`
(`session_epoch_stale` → *"Session revoked on another device."*).

This means **logging in on a second device logs you out everywhere else** — for
all normal app usage (reading Quran, athkar, prayer times, bookmarks). That is
hostile to ordinary multi-device users (phone + tablet) and to teachers who
legitimately use more than one device.

The `sessionEpoch` guard is currently conflating **two unrelated jobs**:

1. **Device exclusivity** — only one device may act at a time.
2. **Client freshness** — a cheap "is this caller still current" gate used to
   protect wallet / payment / booking mutations.

The product requirement has changed:

- **Normal usage:** multi-device login is allowed; no forced sign-out.
- **Learn Quran live sessions (especially video):** the same user may be active
  from **only one device per live session at a time.**

Device exclusivity is therefore no longer a global auth concern — it is a
**narrow, per-live-session concern**.

---

## Decision

**Decouple the two jobs the `sessionEpoch` conflates, and move device
exclusivity from the global auth layer down to the RTC-token gate.**

1. **Global multi-device login is the default.**
   Stop calling `revokeRefreshTokens(uid)` on login. Replace the exclusive
   `session.activeDeviceId` with a **non-exclusive device registry** at
   `users/{uid}/devices/{deviceId}` (FCM routing + a "your devices" screen), with
   a **soft cap of 5 devices** — reaching it never forces a logout; the user
   removes an old device via the Manage Devices flow.
   "Sign out other devices" survives only as an **explicit, user-initiated
   security action**, never an automatic consequence of logging in elsewhere.

2. **`sessionEpoch` is retired as a device-exclusivity mechanism.**
   Each callable that used it is migrated **individually** (not blanket-removed)
   to explicit server-side guards it should have had anyway: Firebase Auth +
   participant/ownership checks + idempotency keys + Firestore transactions +
   status/time-window validation. See the plan for the callable-by-callable
   matrix. During transition the server **tolerates but ignores** a
   `sessionEpoch` field for backward compatibility with older clients.

3. **Live-session single-device is enforced only at the RTC-token gate.**
   `issueSessionRtcToken` acquires a **per-participant lease lock** at
   `quran_sessions/{sessionId}.liveLocks.{uid}` inside a Firestore transaction.
   The lock is keyed by `uid`, so teacher and student each hold their own lock
   and both may be live; the lock only prevents the **same user** from two
   devices. The **lease TTL equals the issued RTC token TTL**, so lock renewal
   piggybacks on the mandatory token refresh — **no heartbeat, no polling, no
   dedicated cron**. Abandoned locks self-expire; they are also cleared on
   session completion. Conflict is **deny-by-default** with an explicit
   **"Switch to this device"** (`forceTakeover`) that a user may invoke only
   against **their own** other device.

4. **LiveKit-first RTC strategy.**
   The strategic live provider is **LiveKit**, with participant
   `identity = uid#deviceId` so the server can perform **targeted eviction**
   (`RoomServiceClient.removeParticipant`) of the old device on takeover. Agora
   remains supported behind the existing provider abstraction for
   MVP/transition, but with **deny-only** semantics (it has no reliable
   per-device eviction). The RTC token is server-minted, so the lock is
   unforgeable regardless of client tampering.

5. **FCM routing is split by intent.**
   Account-level events (booking created/confirmed/canceled/rescheduled,
   reminders, payment result, teacher accept/reject) fan out to **all** the
   user's registered devices. Live-session control messages
   (`session_taken_over`, `leave_live_session`, `force_disconnect_from_room`,
   `refresh_live_session_state`) are **device-targeted**. Stale tokens are
   pruned on send failure; collapse keys prevent spam.

---

## Consequences

**Positive**

- Ordinary multi-device usage works; no surprise logouts.
- Device exclusivity is enforced exactly where it matters (paid live minutes)
  and exactly where it is unforgeable (server-minted RTC token).
- No heartbeat / polling / persistent listener for enforcement → predictable,
  low Firebase cost (roughly one transaction per token issuance, which already
  happens today), and *cheaper* than today once `sessionEpoch` stamping is
  dropped from the 14 non-RTC callables.
- Users are never signed out of the whole app to satisfy a session constraint.
- Aligns with ADR-002 (Firebase as a swappable data-layer detail) and the
  provider abstraction already in place for Agora/LiveKit.

**Negative / costs**

- Non-trivial migration: `sessionEpoch` is woven into ~15 callables and a whole
  client `auth` subsystem (`session_validity_cubit`,
  `session_revoked_navigation_listener`, `check_session_validity_use_case`,
  `pending_session_revoke_store`, `session_epoch_provider`,
  `callable_session_payload_builder`). Must be phased behind flags.
- Reliable device eviction depends on LiveKit; Agora sessions can only *deny* a
  second device, not actively kick the first (it will drop at token expiry).
- A new `users/{uid}/devices` subcollection needs matching `firestore.rules`
  (read-own, no client write) and lock fields must be Cloud-Functions-only.

**Neutral**

- `users/{uid}.session` is retained only if we keep user-initiated "sign out
  other devices"; otherwise it is retired in a later phase.

---

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Keep global single-device | Directly contradicts the multi-device requirement; hostile UX. |
| Separate `acquireLiveLock` callable | Redundant round-trip; `issueSessionRtcToken` is already the unforgeable gate — fold the lock into it. |
| Short TTL lease + heartbeat writes | Recurring writes/polling we explicitly want to avoid. Token-TTL leasing gives free renewal. |
| RTDB presence + `onDisconnect` for the lock | `onDisconnect` fires late/unreliably on network partitions; adds a second datastore; not transactional. Only viable for optional "other participant connected" UI, which the RTC provider already reports. |
| Agora-only | No reliable per-device eviction (numeric uid has no device dimension); weakens takeover to deny-only. |

---

## Recommended direction (decided 2026-07-06)

These were the ADR's open questions; they are now settled as the current
recommended direction. Status stays **Proposed** (no production code yet).

1. **Soft device cap of 5** registered devices per user — not unlimited. Normal
   login never forces a logout; when the cap is reached, the user resolves it
   later through the Manage Devices flow by removing an old device.
2. **Yes, remove global `sessionEpoch` enforcement from non-RTC callables** — but
   **incrementally, callable-by-callable**, never blindly. Each removal is
   replaced with the explicit server-side protections it should have had: Firebase
   Auth + ownership checks + idempotency keys + Firestore transactions +
   status/time-window validation.
3. **LiveKit is the preferred long-term provider** for live Quran sessions,
   optimized around `identity = uid#deviceId` for targeted eviction. **Agora is
   kept behind the provider abstraction only for MVP/transition**, with
   **deny-only** behavior accepted where reliable per-device eviction is not
   available.
