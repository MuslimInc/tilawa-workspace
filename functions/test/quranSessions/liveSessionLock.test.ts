import test from "node:test";
import assert from "node:assert/strict";

import {
  LIVE_LOCK_LEASE_TTL_MS,
  liveKitIdentity,
  decideLockGrant,
  buildLiveLockWriteFields,
  type LiveLockSnapshot,
} from "../../src/quranSessions/liveSessionLock";

const NOW = 1_000_000;

function lock(overrides: Partial<LiveLockSnapshot> = {}): LiveLockSnapshot {
  return {
    deviceId: "device_A",
    identity: "uid_1#device_A",
    leaseUntilMs: NOW + LIVE_LOCK_LEASE_TTL_MS,
    lockEpoch: 3,
    updatedAtMs: NOW - 60_000,
    ...overrides,
  };
}

test("liveKitIdentity joins uid and deviceId with '#'", () => {
  assert.equal(liveKitIdentity("uid_1", "device_A"), "uid_1#device_A");
});

test("decideLockGrant grants a fresh lease when no lock exists", () => {
  const decision = decideLockGrant({
    lock: null,
    nowMs: NOW,
    deviceId: "device_A",
    forceTakeover: false,
  });
  assert.deepEqual(decision, {
    grant: true,
    evictIdentity: null,
    newLockEpoch: 0,
  });
});

test("decideLockGrant grants over an expired lease and bumps the epoch", () => {
  const decision = decideLockGrant({
    lock: lock({ leaseUntilMs: NOW - 1 }),
    nowMs: NOW,
    deviceId: "device_B",
    forceTakeover: false,
  });
  assert.deepEqual(decision, {
    grant: true,
    evictIdentity: null,
    newLockEpoch: 4,
  });
});

test("decideLockGrant renews without eviction when the same device reclaims", () => {
  const decision = decideLockGrant({
    lock: lock(),
    nowMs: NOW,
    deviceId: "device_A",
    forceTakeover: false,
  });
  assert.deepEqual(decision, {
    grant: true,
    evictIdentity: null,
    newLockEpoch: 3,
  });
});

test("decideLockGrant denies a different device without takeover", () => {
  const decision = decideLockGrant({
    lock: lock(),
    nowMs: NOW,
    deviceId: "device_B",
    forceTakeover: false,
  });
  assert.deepEqual(decision, {
    grant: false,
    reason: "already_active_on_other_device",
    activeDeviceId: "device_A",
    activeIdentity: "uid_1#device_A",
    sinceMs: NOW - 60_000,
  });
});

test("decideLockGrant grants takeover over a different device and evicts the old identity", () => {
  const decision = decideLockGrant({
    lock: lock(),
    nowMs: NOW,
    deviceId: "device_B",
    forceTakeover: true,
  });
  assert.deepEqual(decision, {
    grant: true,
    evictIdentity: "uid_1#device_A",
    newLockEpoch: 4,
  });
});

test("buildLiveLockWriteFields sets identity, lease = now + TTL, and the given epoch", () => {
  const fields = buildLiveLockWriteFields({
    uid: "uid_1",
    deviceId: "device_B",
    nowMs: NOW,
    newLockEpoch: 4,
  });
  assert.deepEqual(fields, {
    deviceId: "device_B",
    identity: "uid_1#device_B",
    leaseUntilMs: NOW + LIVE_LOCK_LEASE_TTL_MS,
    lockEpoch: 4,
  });
});
