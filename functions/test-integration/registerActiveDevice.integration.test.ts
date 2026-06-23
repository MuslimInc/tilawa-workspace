import test from "node:test";
import assert from "node:assert/strict";
import { mock } from "node:test";

import { registerActiveDevice } from "../src/registerActiveDevice";
import * as adminAuth from "firebase-admin/auth";
import * as adminMessaging from "firebase-admin/messaging";
import { clearFirestore, db } from "./support/emulator";

interface CallableLike {
  run(req: {
    data: unknown;
    auth?: { uid: string };
  }): Promise<{ epoch: number; activeDeviceId: string }>;
}

const callable = registerActiveDevice as unknown as CallableLike;

test.beforeEach(() => {
  mock.method(adminAuth, "getAuth", () => ({
    revokeRefreshTokens: async () => {},
  }));
  mock.method(adminMessaging, "getMessaging", () => ({
    send: async () => "msg-id",
  }));
});

test.afterEach(async () => {
  mock.restoreAll();
  await clearFirestore();
});

test("integration: registerActiveDevice bumps epoch on new device", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 1, activeDeviceId: "device-a" },
    notifications: { activeFcmToken: "tok-a", platform: "android" },
  });
  await db().collection("users").doc("user_1").collection("fcm_tokens").doc("legacy").set({
    token: "legacy",
    platform: "android",
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-b",
      fcmToken: "tok-b",
      platform: "ios",
      appVersion: "2.0.0",
    },
  });

  assert.equal(result.epoch, 2);
  assert.equal(result.activeDeviceId, "device-b");

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("session.epoch"), 2);
  assert.equal(snap.get("session.activeDeviceId"), "device-b");
  assert.equal(snap.get("notifications.activeFcmToken"), "tok-b");
  assert.equal(snap.get("session.appVersion"), "2.0.0");

  const legacy = await db()
    .collection("users")
    .doc("user_1")
    .collection("fcm_tokens")
    .get();
  assert.equal(legacy.empty, true);
});

test("integration: registerActiveDevice keeps epoch on same device refresh", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 3, activeDeviceId: "device-a" },
    notifications: { activeFcmToken: "tok-old", platform: "android" },
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-a",
      fcmToken: "tok-new",
      platform: "android",
    },
  });

  assert.equal(result.epoch, 3);
  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("notifications.activeFcmToken"), "tok-new");
});

test("integration: registerActiveDevice signOut clears active token", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 2, activeDeviceId: "device-a" },
    notifications: { activeFcmToken: "tok-a", platform: "android" },
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "",
      fcmToken: "",
      platform: "android",
      signOut: true,
    },
  });

  assert.equal(result.epoch, 2);
  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("notifications.activeFcmToken"), undefined);
});
