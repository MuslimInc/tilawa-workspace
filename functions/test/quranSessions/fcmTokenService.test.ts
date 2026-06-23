import test from "node:test";
import assert from "node:assert/strict";

import {
  collectActiveFcmTokens,
  clearInvalidActiveFcmTokens,
  getActiveFcmToken,
} from "../../src/quranSessions/fcmTokenService";

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
