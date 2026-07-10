/**
 * Per-session live device lock — pure helpers (ADR-008 Phase 2).
 *
 * Device exclusivity for live Learn Quran sessions is enforced at the
 * RTC-token gate by a lease lock stored at
 * `quran_sessions/{sessionId}.liveLocks.{uid}`. The lock is keyed by `uid`, so
 * teacher and student each hold an independent lock and both may be live; it
 * only prevents the **same user** joining from two devices at once.
 *
 * The lease TTL equals the issued RTC token TTL, so lock renewal piggybacks on
 * the mandatory token refresh — no heartbeat, no polling, no dedicated cron.
 * Abandoned locks self-expire via `leaseUntil`; they are also cleared on
 * session completion.
 *
 * This module is schema + pure decisions only. No Firestore writes happen
 * here; `issueSessionRtcTokenService` runs the transaction and mints the token.
 */

/**
 * Lock lease TTL. Equals the RTC token TTL so renewal (same `deviceId`) extends
 * both in one call. Matches the Agora default token TTL of 3600s.
 */
export const LIVE_LOCK_LEASE_TTL_MS = 60 * 60 * 1000; // 1 hour

/**
 * LiveKit room identity for a participant device. Enables targeted eviction via
 * `RoomServiceClient.removeParticipant(room, identity)` on takeover.
 */
export function liveKitIdentity(uid: string, deviceId: string): string {
  return `${uid}#${deviceId}`;
}

/**
 * Normalized view of an existing lock, with timestamps as epoch milliseconds so
 * the decision is pure and trivially unit-testable. The service layer converts
 * Firestore `Timestamp` values to ms before calling.
 */
export interface LiveLockSnapshot {
  deviceId: string;
  identity: string;
  leaseUntilMs: number;
  lockEpoch: number;
  updatedAtMs: number;
}

export type LockDecision =
  | {
      grant: true;
      /** LiveKit identity to evict post-commit, or null when none. */
      evictIdentity: string | null;
      /** Lock epoch to write for the new lease. */
      newLockEpoch: number;
    }
  | {
      grant: false;
      reason: "already_active_on_other_device";
      activeDeviceId: string;
      activeIdentity: string;
      sinceMs: number;
    };

/**
 * Decides whether to grant a RTC token request a lease, deny it, or take over
 * an existing lease. Pure — performs no I/O.
 *
 * Grant cases:
 * - no existing lock → fresh lease (epoch 0).
 * - lease expired (`leaseUntil` in the past) → fresh lease (epoch bumps).
 * - same `deviceId` → renewal/reclaim, epoch unchanged, no eviction.
 *
 * Deny case: a different device holds a live lease and `forceTakeover` is false.
 *
 * Takeover case: a different device holds a live lease and `forceTakeover` is
 * true → grant, evict the old identity, epoch bumps.
 */
export function decideLockGrant(params: {
  lock: LiveLockSnapshot | null;
  nowMs: number;
  deviceId: string;
  forceTakeover: boolean;
}): LockDecision {
  const { lock, nowMs, deviceId, forceTakeover } = params;

  if (lock == null) {
    return { grant: true, evictIdentity: null, newLockEpoch: 0 };
  }

  const leaseExpired = lock.leaseUntilMs <= nowMs;
  if (leaseExpired) {
    return {
      grant: true,
      evictIdentity: null,
      newLockEpoch: lock.lockEpoch + 1,
    };
  }

  if (lock.deviceId === deviceId) {
    // Renewal / reclaim by the same device: extend the lease, no eviction,
    // no epoch bump (the lock holder did not change).
    return { grant: true, evictIdentity: null, newLockEpoch: lock.lockEpoch };
  }

  if (forceTakeover) {
    return {
      grant: true,
      evictIdentity: lock.identity,
      newLockEpoch: lock.lockEpoch + 1,
    };
  }

  return {
    grant: false,
    reason: "already_active_on_other_device",
    activeDeviceId: lock.deviceId,
    activeIdentity: lock.identity,
    sinceMs: lock.updatedAtMs,
  };
}

/**
 * Fields to write for a granted lease. `leaseUntilMs` is the absolute expiry
 * (now + TTL); the service converts it to a Firestore `Timestamp`. `updatedAt`
 * is a server-timestamp sentinel supplied by the caller.
 */
export interface LiveLockWriteFields {
  deviceId: string;
  identity: string;
  leaseUntilMs: number;
  lockEpoch: number;
}

/**
 * Builds the write field values for a granted lease. Pure — returns primitives;
 * the service wraps `leaseUntilMs` in `Timestamp.fromMillis` and adds
 * `updatedAt: FieldValue.serverTimestamp()`.
 */
export function buildLiveLockWriteFields(params: {
  uid: string;
  deviceId: string;
  nowMs: number;
  newLockEpoch: number;
}): LiveLockWriteFields {
  return {
    deviceId: params.deviceId,
    identity: liveKitIdentity(params.uid, params.deviceId),
    leaseUntilMs: params.nowMs + LIVE_LOCK_LEASE_TTL_MS,
    lockEpoch: params.newLockEpoch,
  };
}
