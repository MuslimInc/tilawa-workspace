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
  }): Promise<{
    status: string;
    sessionEpoch?: number;
    epoch?: number;
    activeDeviceId?: string;
  }>;
}

const callable = registerActiveDevice as unknown as CallableLike;

test.beforeEach(() => {
  db();
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

test("integration: explicit sign-in registers first active device", async () => {
  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-a",
      fcmToken: "tok-a",
      platform: "android",
      registrationMode: "explicit_sign_in",
      appVersion: "2.0.0",
    },
  });

  assert.equal(result.status, "registered");
  assert.equal(result.sessionEpoch, 1);
  assert.equal(result.activeDeviceId, "device-a");

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("session.epoch"), 1);
  assert.equal(snap.get("session.activeDeviceId"), "device-a");
  assert.equal(snap.get("notifications.activeFcmToken"), "tok-a");
});

test("integration: explicit sign-in on new device replaces active device", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 1, activeDeviceId: "device-a" },
    notifications: { activeFcmToken: "tok-a", platform: "android" },
  });
  await db()
    .collection("users")
    .doc("user_1")
    .collection("fcm_tokens")
    .doc("legacy")
    .set({
      token: "legacy",
      platform: "android",
    });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-b",
      fcmToken: "tok-b",
      platform: "ios",
      registrationMode: "explicit_sign_in",
      appVersion: "2.0.0",
    },
  });

  assert.equal(result.status, "registered");
  assert.equal(result.sessionEpoch, 2);
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

test("integration: passive sync from active device updates token only", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 3, activeDeviceId: "device-b" },
    notifications: { activeFcmToken: "tok-old", platform: "android" },
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-b",
      fcmToken: "tok-new",
      platform: "android",
      registrationMode: "passive_sync",
    },
  });

  assert.equal(result.status, "updated_same_device");
  assert.equal(result.sessionEpoch, 3);

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("session.epoch"), 3);
  assert.equal(snap.get("session.activeDeviceId"), "device-b");
  assert.equal(snap.get("notifications.activeFcmToken"), "tok-new");
});

test("integration: passive sync from stale device is rejected/no-op", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 4, activeDeviceId: "device-b" },
    notifications: { activeFcmToken: "tok-b", platform: "ios" },
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-a",
      fcmToken: "tok-a",
      platform: "android",
      registrationMode: "passive_sync",
    },
  });

  assert.equal(result.status, "stale_device_rejected");
  assert.equal(result.sessionEpoch, 4);
  assert.equal(result.activeDeviceId, "device-b");

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("session.activeDeviceId"), "device-b");
  assert.equal(snap.get("notifications.activeFcmToken"), "tok-b");
});

test("integration: active device sign-out clears only active session", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 2, activeDeviceId: "device-a" },
    notifications: { activeFcmToken: "tok-a", platform: "android" },
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-a",
      fcmToken: "",
      platform: "android",
      registrationMode: "passive_sync",
      signOut: true,
    },
  });

  assert.equal(result.status, "updated_same_device");

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("session.epoch"), 2);
  assert.equal(snap.get("session.activeDeviceId"), undefined);
  assert.equal(snap.get("notifications.activeFcmToken"), undefined);
});

test("integration: stale device sign-out does not clear active token", async () => {
  await db().collection("users").doc("user_1").set({
    session: { epoch: 3, activeDeviceId: "device-b" },
    notifications: { activeFcmToken: "tok-b", platform: "ios" },
  });

  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-a",
      fcmToken: "",
      platform: "android",
      registrationMode: "passive_sync",
      signOut: true,
    },
  });

  assert.equal(result.status, "stale_device_rejected");
  assert.equal(result.sessionEpoch, 3);
  assert.equal(result.activeDeviceId, "device-b");

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("notifications.activeFcmToken"), "tok-b");
  assert.equal(snap.get("session.activeDeviceId"), "device-b");
});

test("integration: invalid registration mode is rejected", async () => {
  await assert.rejects(
    () =>
      callable.run({
        auth: { uid: "user_1" },
        data: {
          deviceId: "device-a",
          fcmToken: "tok-a",
          platform: "android",
          registrationMode: "startup",
        },
      }),
    (error: { code?: string }) => error.code === "invalid-argument",
  );
});

test("integration: safe device info fields are stored", async () => {
  const result = await callable.run({
    auth: { uid: "user_1" },
    data: {
      deviceId: "device-a",
      fcmToken: "tok-a",
      platform: "android",
      registrationMode: "explicit_sign_in",
      deviceInfo: {
        manufacturer: "OPPO",
        model: "A98 5G",
        os: "Android",
        osVersion: "15",
        appBuildNumber: "63",
        appVersion: "2.0.16",
        ignoredField: "ignored",
      },
    },
  });

  assert.equal(result.status, "registered");

  const snap = await db().collection("users").doc("user_1").get();
  assert.equal(snap.get("session.deviceInfo.manufacturer"), "OPPO");
  assert.equal(snap.get("session.deviceInfo.model"), "A98 5G");
  assert.equal(snap.get("session.deviceInfo.ignoredField"), undefined);
});

test("integration: unsafe device info fields are rejected", async () => {
  await assert.rejects(
    () =>
      callable.run({
        auth: { uid: "user_1" },
        data: {
          deviceId: "device-a",
          fcmToken: "tok-a",
          platform: "android",
          registrationMode: "explicit_sign_in",
          deviceInfo: {
            serialNumber: "sensitive",
          },
        },
      }),
    (error: { code?: string }) => error.code === "invalid-argument",
  );
});
