import test from "node:test";
import assert from "node:assert/strict";

import {
  collectActiveFcmTokens,
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
