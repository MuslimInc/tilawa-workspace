import test from "node:test";
import assert from "node:assert/strict";
import { mock } from "node:test";

import {
  collectActiveFcmTokens,
  clearInvalidActiveFcmTokens,
  getActiveFcmToken,
} from "../../src/quranSessions/fcmTokenService";
import * as multiDeviceLogin from "../../src/multiDeviceLogin";

function createDb(docs: Record<string, Record<string, unknown>>) {
  return {
    collection(name: string) {
      return {
        doc(id: string) {
          return {
            async get() {
              const data = docs[`${name}/${id}`];
              return {
                exists: data != null,
                data: () => data,
              };
            },
          };
        },
      };
    },
  } as unknown as FirebaseFirestore.Firestore;
}

function createRegistryDb(
  devicesByUser: Record<string, Array<Record<string, unknown> & { id: string }>>,
) {
  return {
    collection(name: string) {
      return {
        doc(id: string) {
          return {
            collection(sub: string) {
              return {
                async get() {
                  const docs = devicesByUser[`${name}/${id}/${sub}`] ?? [];
                  return {
                    docs: docs.map((data) => ({
                      id: data.id,
                      get(field: string) {
                        return data[field];
                      },
                    })),
                  };
                },
              };
            },
          };
        },
      };
    },
  } as unknown as FirebaseFirestore.Firestore;
}

test("getActiveFcmToken reads embedded notifications.activeFcmToken", async () => {
  const db = createDb({
    "users/u1": {
      notifications: { activeFcmToken: "tok-1" },
    },
  });

  assert.equal(await getActiveFcmToken(db, "u1"), "tok-1");
});

test("getActiveFcmToken returns null when token missing", async () => {
  const db = createDb({
    "users/u1": {},
  });

  assert.equal(await getActiveFcmToken(db, "u1"), null);
});

test("collectActiveFcmTokens batches user doc reads", async () => {
  const db = createDb({
    "users/u1": { notifications: { activeFcmToken: "tok-1" } },
    "users/u2": { notifications: { activeFcmToken: "" } },
    "users/u3": { notifications: { activeFcmToken: "tok-3" } },
  });

  const entries = await collectActiveFcmTokens(db, ["u1", "u2", "u3"]);
  assert.deepEqual(entries, [
    { userId: "u1", token: "tok-1" },
    { userId: "u3", token: "tok-3" },
  ]);
});

test("collectActiveFcmTokens fans out to active device registry entries when multi-device is enabled", async () => {
  mock.method(multiDeviceLogin, "isMultiDeviceLoginEnabled", () => true);
  const db = createRegistryDb({
    "users/u1/devices": [
      { id: "device-a", fcmToken: "tok-a", revokedAt: null },
      { id: "device-b", fcmToken: "tok-b", revokedAt: null },
      { id: "device-revoked", fcmToken: "tok-old", revokedAt: new Date() },
    ],
    "users/u2/devices": [
      { id: "device-c", fcmToken: "tok-c", revokedAt: null },
      { id: "device-empty", fcmToken: "", revokedAt: null },
    ],
  });

  try {
    const entries = await collectActiveFcmTokens(db, ["u1", "u2"]);
    assert.deepEqual(entries, [
      { userId: "u1", deviceId: "device-a", token: "tok-a" },
      { userId: "u1", deviceId: "device-b", token: "tok-b" },
      { userId: "u2", deviceId: "device-c", token: "tok-c" },
    ]);
    assert.equal(await getActiveFcmToken(db, "u1"), "tok-a");
  } finally {
    mock.restoreAll();
  }
});

test("clearInvalidActiveFcmTokens clears only invalid registration tokens", async () => {
  const writes: Array<{ path: string; data: Record<string, unknown> }> = [];
  const deletes: string[] = [];

  const db = {
    batch() {
      const ops: Array<() => void> = [];
      return {
        set(ref: { path: string }, data: Record<string, unknown>) {
          ops.push(() => writes.push({ path: ref.path, data }));
        },
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
    collection(name: string) {
      return {
        doc(id: string) {
          const path = `${name}/${id}`;
          return {
            path,
            collection(sub: string) {
              return {
                doc(tokenId: string) {
                  return { path: `${path}/${sub}/${tokenId}` };
                },
              };
            },
          };
        },
      };
    },
  } as unknown as FirebaseFirestore.Firestore;

  await clearInvalidActiveFcmTokens(
    db,
    [
      { userId: "u1", token: "bad-token" },
      { userId: "u2", token: "good-token" },
    ],
    {
      responses: [
        {
          success: false,
          error: { code: "messaging/invalid-registration-token" },
        },
        { success: true },
      ],
    },
  );

  assert.equal(writes.length, 1);
  assert.equal(writes[0]?.path, "users/u1");
  assert.equal(deletes.length, 1);
  assert.equal(deletes[0], "users/u1/fcm_tokens/bad-token");
});

test("clearInvalidActiveFcmTokens prunes invalid registry device tokens", async () => {
  const writes: Array<{ path: string; data: Record<string, unknown> }> = [];
  const deletes: string[] = [];

  const db = {
    batch() {
      const ops: Array<() => void> = [];
      return {
        set(ref: { path: string }, data: Record<string, unknown>) {
          ops.push(() => writes.push({ path: ref.path, data }));
        },
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
    collection(name: string) {
      return {
        doc(id: string) {
          const path = `${name}/${id}`;
          return {
            path,
            collection(sub: string) {
              return {
                doc(deviceOrTokenId: string) {
                  return { path: `${path}/${sub}/${deviceOrTokenId}` };
                },
              };
            },
          };
        },
      };
    },
  } as unknown as FirebaseFirestore.Firestore;

  await clearInvalidActiveFcmTokens(
    db,
    [{ userId: "u1", deviceId: "device-a", token: "bad-token" }],
    {
      responses: [
        {
          success: false,
          error: { code: "messaging/registration-token-not-registered" },
        },
      ],
    },
  );

  assert.equal(writes.length, 1);
  assert.equal(writes[0]?.path, "users/u1/devices/device-a");
  assert.equal(deletes[0], "users/u1/fcm_tokens/bad-token");
});
