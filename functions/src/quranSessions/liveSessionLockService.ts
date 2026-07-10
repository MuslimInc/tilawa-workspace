import { Timestamp, FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";

import { lifecycleError } from "./lifecycleErrors";
import {
  buildLiveLockWriteFields,
  decideLockGrant,
  type LiveLockSnapshot,
} from "./liveSessionLock";

/**
 * Transaction runner for the per-session live device lock — ADR-008 Phase 2.
 *
 * `issueSessionRtcToken` calls this before minting the RTC token. The lock is
 * keyed by `uid` at `quran_sessions/{sessionId}.liveLocks.{uid}`, so teacher
 * and student each hold an independent lease. Deny-by-default; an explicit
 * `forceTakeover` evicts the caller's own previous device.
 *
 * Pure lock decisions live in `liveSessionLock.ts`; this module owns the
 * Firestore transaction and the Timestamp/FieldValue sentinels.
 */

export interface AcquireLiveLockOutcome {
  /** LiveKit identity to evict post-commit, or null when none. */
  evictIdentity: string | null;
  /** Previous lock holder's device id, for the takeover push. */
  previousDeviceId: string | null;
}

function asMillis(raw: unknown): number {
  if (raw == null) return 0;
  if (typeof (raw as { toMillis?: unknown }).toMillis === "function") {
    return (raw as { toMillis(): number }).toMillis();
  }
  return 0;
}

function readLockSnapshot(
  liveLocks: Record<string, unknown> | undefined,
  uid: string,
): LiveLockSnapshot | null {
  const raw = liveLocks?.[uid] as Record<string, unknown> | undefined;
  if (raw == null) {
    return null;
  }
  return {
    deviceId: raw.deviceId as string,
    identity: raw.identity as string,
    leaseUntilMs: asMillis(raw.leaseUntil),
    lockEpoch: raw.lockEpoch as number,
    updatedAtMs: asMillis(raw.updatedAt),
  };
}

export async function acquireLiveLock(params: {
  db: Firestore;
  sessionRef: FirebaseFirestore.DocumentReference;
  uid: string;
  deviceId: string;
  forceTakeover: boolean;
}): Promise<AcquireLiveLockOutcome> {
  const { db, sessionRef, uid, deviceId, forceTakeover } = params;

  let outcome: AcquireLiveLockOutcome = {
    evictIdentity: null,
    previousDeviceId: null,
  };

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(sessionRef);
    const fresh = freshSnap.data() ?? {};
    const liveLocks = fresh.liveLocks as Record<string, unknown> | undefined;
    const snapshot = readLockSnapshot(liveLocks, uid);

    const nowMs = Date.now();
    const decision = decideLockGrant({
      lock: snapshot,
      nowMs,
      deviceId,
      forceTakeover,
    });

    if (!decision.grant) {
      throw lifecycleError(
        "already_active_on_other_device",
        "Session is already active on another device.",
        {
          activeDeviceId: decision.activeDeviceId,
          sinceTs: decision.sinceMs,
          activeIdentity: decision.activeIdentity,
        },
      );
    }

    const writeFields = buildLiveLockWriteFields({
      uid,
      deviceId,
      nowMs,
      newLockEpoch: decision.newLockEpoch,
    });

    tx.set(
      sessionRef,
      {
        liveLocks: {
          [uid]: {
            deviceId: writeFields.deviceId,
            identity: writeFields.identity,
            leaseUntil: Timestamp.fromMillis(writeFields.leaseUntilMs),
            lockEpoch: writeFields.lockEpoch,
            updatedAt: FieldValue.serverTimestamp(),
          },
        },
      },
      { merge: true },
    );

    outcome = {
      evictIdentity: decision.evictIdentity,
      previousDeviceId: snapshot?.deviceId ?? null,
    };
  });

  return outcome;
}

/**
 * Clears the entire `liveLocks` map on session completion. Called from
 * `completeSession` / `finalizeElapsedSessions` so a finished session does not
 * keep stale leases for either participant. Safe to apply when no locks exist.
 */
export function clearAllLiveLocksField(): Record<string, unknown> {
  return {
    liveLocks: FieldValue.delete(),
  };
}
