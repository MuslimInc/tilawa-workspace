import test from "node:test";
import assert from "node:assert/strict";

import {
  assertClientSessionEpoch,
  planDeviceRegistration,
  readServerSessionEpoch,
} from "../src/quranSessions/sessionRegistration";
import {
  deleteLegacyFcmTokens,
  parseDevicePlatform,
  registerActiveDevice,
} from "../src/registerActiveDevice";

test("planDeviceRegistration bumps epoch on new device", () => {
  const plan = planDeviceRegistration(
    { epoch: 2, activeDeviceId: "device-a" },
    {
      deviceId: "device-b",
      fcmToken: "token-b",
      platform: "android",
      registrationMode: "explicit_sign_in",
    },
  );

  assert.equal(plan.deviceChanged, true);
  assert.equal(plan.nextEpoch, 3);
  assert.equal(plan.nextActiveDeviceId, "device-b");
  assert.equal(plan.clearActiveSession, false);
  assert.equal(plan.writeActiveDevice, true);
  assert.equal(plan.noOp, false);
});

test("planDeviceRegistration keeps epoch on same device token refresh", () => {
  const plan = planDeviceRegistration(
    { epoch: 4, activeDeviceId: "device-a" },
    {
      deviceId: "device-a",
      fcmToken: "token-new",
      platform: "ios",
      registrationMode: "passive_sync",
    },
  );

  assert.equal(plan.deviceChanged, false);
  assert.equal(plan.nextEpoch, 4);
  assert.equal(plan.writeActiveDevice, true);
  assert.equal(plan.clearActiveSession, false);
  assert.equal(plan.noOp, false);
});

test("planDeviceRegistration signOut clears active session for active device", () => {
  const plan = planDeviceRegistration(
    { epoch: 1, activeDeviceId: "device-a" },
    {
      deviceId: "device-a",
      fcmToken: "",
      platform: "android",
      registrationMode: "explicit_sign_in",
      signOut: true,
    },
  );

  assert.equal(plan.clearActiveSession, true);
  assert.equal(plan.writeActiveDevice, false);
  assert.equal(plan.noOp, false);
  assert.equal(plan.nextEpoch, 1);
});

test("planDeviceRegistration signOut is no-op for stale device", () => {
  const plan = planDeviceRegistration(
    { epoch: 2, activeDeviceId: "device-b" },
    {
      deviceId: "device-a",
      fcmToken: "",
      platform: "android",
      registrationMode: "explicit_sign_in",
      signOut: true,
    },
  );

  assert.equal(plan.noOp, true);
  assert.equal(plan.clearActiveSession, false);
  assert.equal(plan.writeActiveDevice, false);
  assert.equal(plan.nextEpoch, 2);
  assert.equal(plan.nextActiveDeviceId, "device-b");
});

test("planDeviceRegistration signOut is no-op when deviceId missing", () => {
  const plan = planDeviceRegistration(
    { epoch: 1, activeDeviceId: "device-a" },
    {
      deviceId: "",
      fcmToken: "",
      platform: "android",
      registrationMode: "explicit_sign_in",
      signOut: true,
    },
  );

  assert.equal(plan.noOp, true);
  assert.equal(plan.clearActiveSession, false);
  assert.equal(plan.writeActiveDevice, false);
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

test("parseDevicePlatform accepts known platforms", () => {
  assert.equal(parseDevicePlatform("android"), "android");
  assert.equal(parseDevicePlatform("ios"), "ios");
  assert.equal(parseDevicePlatform("web"), "web");
  assert.equal(parseDevicePlatform("desktop"), null);
});

test("deleteLegacyFcmTokens removes all legacy docs", async () => {
  const deletes: string[] = [];
  const userRef = {
    firestore: {
      batch() {
        const ops: Array<() => void> = [];
        return {
          delete(ref: { path: string }) {
            ops.push(() => deletes.push(ref.path));
          },
          async commit() {
            for (const op of ops) {
              op();
            }
          },
        };
      },
    },
    collection(name: string) {
      return {
        async get() {
          return {
            empty: false,
            docs: [
              { ref: { path: `users/u1/${name}/tok-a` } },
              { ref: { path: `users/u1/${name}/tok-b` } },
            ],
          };
        },
      };
    },
  } as unknown as FirebaseFirestore.DocumentReference;

  await deleteLegacyFcmTokens(userRef);

  assert.deepEqual(deletes, [
    "users/u1/fcm_tokens/tok-a",
    "users/u1/fcm_tokens/tok-b",
  ]);
});

test("deleteLegacyFcmTokens is no-op when subcollection empty", async () => {
  let committed = false;
  const userRef = {
    firestore: {
      batch() {
        return {
          delete() {},
          async commit() {
            committed = true;
          },
        };
      },
    },
    collection() {
      return {
        async get() {
          return { empty: true, docs: [] };
        },
      };
    },
  } as unknown as FirebaseFirestore.DocumentReference;

  await deleteLegacyFcmTokens(userRef);

  assert.equal(committed, false);
});

interface CallableLike {
  run(req: {
    data: unknown;
    auth?: { uid: string };
  }): Promise<{ epoch: number; activeDeviceId: string }>;
}

const callable = registerActiveDevice as unknown as CallableLike;

test("registerActiveDevice rejects unauthenticated callers", async () => {
  await assert.rejects(
    () =>
      callable.run({
        data: {
          deviceId: "device-a",
          fcmToken: "tok-a",
          platform: "android",
        },
      }),
    (error: { code?: string }) => error.code === "unauthenticated",
  );
});

test("registerActiveDevice rejects missing deviceId", async () => {
  await assert.rejects(
    () =>
      callable.run({
        auth: { uid: "user_1" },
        data: {
          deviceId: "",
          fcmToken: "tok-a",
          platform: "android",
        },
      }),
    (error: { code?: string }) => error.code === "invalid-argument",
  );
});

test("registerActiveDevice rejects missing fcmToken", async () => {
  await assert.rejects(
    () =>
      callable.run({
        auth: { uid: "user_1" },
        data: {
          deviceId: "device-a",
          fcmToken: "",
          platform: "android",
        },
      }),
    (error: { code?: string }) => error.code === "invalid-argument",
  );
});

test("registerActiveDevice rejects invalid platform", async () => {
  await assert.rejects(
    () =>
      callable.run({
        auth: { uid: "user_1" },
        data: {
          deviceId: "device-a",
          fcmToken: "tok-a",
          platform: "desktop",
        },
      }),
    (error: { code?: string }) => error.code === "invalid-argument",
  );
});
