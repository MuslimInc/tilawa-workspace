import test from "node:test";
import assert from "node:assert/strict";

import { requireValidSessionEpoch } from "../src/quranSessions/sessionAuth";
import { planDeviceRegistration } from "../src/quranSessions/sessionRegistration";
import { clearFirestore, db } from "./support/emulator";

test("integration: stale session epoch is rejected by callable guard", async () => {
  await clearFirestore();
  await db().collection("users").doc("student1").set({
    session: { epoch: 2, activeDeviceId: "device-b" },
    notifications: { activeFcmToken: "tok-b", platform: "android" },
  });

  await assert.rejects(
    () =>
      requireValidSessionEpoch(
        { data: { sessionEpoch: 1 } } as never,
        "student1",
        db(),
      ),
    (error: { code?: string }) => error.code === "failed-precondition",
  );
});

test("integration: matching session epoch passes callable guard", async () => {
  await clearFirestore();
  await db().collection("users").doc("student1").set({
    session: { epoch: 1, activeDeviceId: "device-a" },
  });

  await assert.doesNotReject(() =>
    requireValidSessionEpoch(
      { data: { sessionEpoch: 1 } } as never,
      "student1",
      db(),
    ),
  );
});

test("integration: device B registration supersedes device A epoch", async () => {
  const first = planDeviceRegistration(null, {
    deviceId: "device-a",
    fcmToken: "tok-a",
    platform: "android",
    registrationMode: "explicit_sign_in",
  });
  const second = planDeviceRegistration(
    { epoch: first.nextEpoch, activeDeviceId: first.nextActiveDeviceId },
    {
      deviceId: "device-b",
      fcmToken: "tok-b",
      platform: "ios",
      registrationMode: "explicit_sign_in",
    },
  );

  assert.equal(first.nextEpoch, 1);
  assert.equal(second.nextEpoch, 2);
  assert.equal(second.nextActiveDeviceId, "device-b");
  assert.equal(second.deviceChanged, true);
});
