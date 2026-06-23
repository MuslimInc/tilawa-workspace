import test from "node:test";
import assert from "node:assert/strict";

import {
  assertClientSessionEpoch,
  planDeviceRegistration,
  readServerSessionEpoch,
} from "../src/quranSessions/sessionRegistration";

test("planDeviceRegistration bumps epoch on new device", () => {
  const plan = planDeviceRegistration(
    { epoch: 2, activeDeviceId: "device-a" },
    {
      deviceId: "device-b",
      fcmToken: "token-b",
      platform: "android",
    },
  );

  assert.equal(plan.deviceChanged, true);
  assert.equal(plan.nextEpoch, 3);
  assert.equal(plan.nextActiveDeviceId, "device-b");
  assert.equal(plan.clearTokenOnly, false);
});

test("planDeviceRegistration keeps epoch on same device token refresh", () => {
  const plan = planDeviceRegistration(
    { epoch: 4, activeDeviceId: "device-a" },
    {
      deviceId: "device-a",
      fcmToken: "token-new",
      platform: "ios",
    },
  );

  assert.equal(plan.deviceChanged, false);
  assert.equal(plan.nextEpoch, 4);
});

test("planDeviceRegistration signOut clears token only", () => {
  const plan = planDeviceRegistration(
    { epoch: 1, activeDeviceId: "device-a" },
    {
      deviceId: "",
      fcmToken: "",
      platform: "android",
      signOut: true,
    },
  );

  assert.equal(plan.clearTokenOnly, true);
  assert.equal(plan.nextEpoch, 1);
});

test("readServerSessionEpoch defaults missing session to zero", () => {
  assert.equal(readServerSessionEpoch(undefined), 0);
  assert.equal(readServerSessionEpoch({ session: { epoch: 5 } }), 5);
});

test("assertClientSessionEpoch rejects stale epoch", () => {
  assert.throws(
    () => assertClientSessionEpoch(1, 2),
    /session_epoch_stale/,
  );
});

test("assertClientSessionEpoch accepts matching epoch", () => {
  assert.doesNotThrow(() => assertClientSessionEpoch(2, 2));
});
