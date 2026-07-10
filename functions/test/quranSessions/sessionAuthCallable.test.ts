import test from "node:test";
import assert from "node:assert/strict";
import { mock } from "node:test";

import { requireValidSessionEpoch } from "../../src/quranSessions/sessionAuth";
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

test("requireValidSessionEpoch rejects stale client epoch", async () => {
  const db = createDb({
    "users/student1": { session: { epoch: 3 } },
  });

  await assert.rejects(
    () =>
      requireValidSessionEpoch(
        { data: { sessionEpoch: 1 } } as never,
        "student1",
        db,
      ),
    (error: { code?: string; message?: string }) =>
      error.code === "failed-precondition" &&
      error.message?.includes("revoked") === true,
  );
});

test("requireValidSessionEpoch accepts matching epoch", async () => {
  const db = createDb({
    "users/student1": { session: { epoch: 2 } },
  });

  await assert.doesNotReject(() =>
    requireValidSessionEpoch(
      { data: { sessionEpoch: 2 } } as never,
      "student1",
      db,
    ),
  );
});

test("requireValidSessionEpoch rejects missing client epoch", async () => {
  const db = createDb({
    "users/student1": { session: { epoch: 1 } },
  });

  await assert.rejects(
    () =>
      requireValidSessionEpoch({ data: {} } as never, "student1", db),
    (error: { code?: string; message?: string }) =>
      error.code === "failed-precondition" &&
      error.message?.includes("required") === true,
  );
});

test("requireValidSessionEpoch tolerates stale client epoch when multi-device login is enabled", async () => {
  mock.method(multiDeviceLogin, "isMultiDeviceLoginEnabled", () => true);
  const db = createDb({
    "users/student1": { session: { epoch: 3 } },
  });

  try {
    await assert.doesNotReject(() =>
      requireValidSessionEpoch(
        { data: { sessionEpoch: 1 } } as never,
        "student1",
        db,
      ),
    );
  } finally {
    mock.restoreAll();
  }
});
