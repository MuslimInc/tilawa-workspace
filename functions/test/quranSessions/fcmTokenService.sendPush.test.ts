import test from "node:test";
import assert from "node:assert/strict";
import { mock } from "node:test";

import {
  collectFcmTokens,
  cleanupInvalidFcmTokens,
  sendPushToUsers,
} from "../../src/quranSessions/fcmTokenService";
import * as adminMessaging from "firebase-admin/messaging";

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

test("sendPushToUsers throws when no active tokens exist", async () => {
  const db = createDb({ "users/u1": {} });

  await assert.rejects(
    () => sendPushToUsers(db, ["u1"], "Title", "Body", "action"),
    /No FCM tokens found/,
  );
});

test("sendPushToUsers delivers multicast and clears invalid tokens", async () => {
  const sent: Array<Record<string, unknown>> = [];
  mock.method(adminMessaging, "getMessaging", () => ({
    sendEachForMulticast: async (message: Record<string, unknown>) => {
      sent.push(message);
      return {
        successCount: 0,
        failureCount: 1,
        responses: [
          {
            success: false,
            error: { code: "messaging/registration-token-not-registered" },
          },
        ],
      };
    },
  }));

  const writes: Array<{ path: string; data: Record<string, unknown> }> = [];
  const deletes: string[] = [];
  const db = {
    collection(name: string) {
      return {
        doc(id: string) {
          const path = `${name}/${id}`;
          return {
            path,
            async get() {
              return {
                data: () => ({
                  notifications: { activeFcmToken: "tok-1" },
                }),
              };
            },
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
  } as unknown as FirebaseFirestore.Firestore;

  const result = await sendPushToUsers(
    db,
    ["u1"],
    "Title",
    "Body",
    "teacher_application_reviewed",
    { status: "approved" },
  );

  assert.equal(result.successCount, 0);
  assert.equal(result.failureCount, 1);
  assert.equal(sent.length, 1);
  assert.equal(writes.length, 1);
  assert.equal(deletes[0], "users/u1/fcm_tokens/tok-1");

  mock.restoreAll();
});

test("collectFcmTokens returns token strings from embedded field", async () => {
  const db = createDb({
    "users/u1": { notifications: { activeFcmToken: "tok-1" } },
    "users/u2": {},
  });

  const tokens = await collectFcmTokens(db, ["u1", "u2"]);
  assert.deepEqual(tokens, ["tok-1"]);
});

test("cleanupInvalidFcmTokens delegates to clearInvalidActiveFcmTokens", async () => {
  const writes: string[] = [];
  const db = {
    batch() {
      const ops: Array<() => void> = [];
      return {
        set(ref: { path: string }) {
          ops.push(() => writes.push(ref.path));
        },
        delete() {
          ops.push(() => {});
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

  await cleanupInvalidFcmTokens(
    db,
    ["bad-token"],
    {
      responses: [
        {
          success: false,
          error: { code: "messaging/invalid-registration-token" },
        },
      ],
    },
    ["u1"],
  );

  assert.deepEqual(writes, ["users/u1"]);
});
