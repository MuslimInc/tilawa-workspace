import test from "node:test";
import assert from "node:assert/strict";

import {
  BroadcastAllUsersDisabledError,
  isFullUserCollectionScanAllowed,
  resolveUserIds,
} from "../src/notifications/resolveUserIds";

function createPaginatedUsersDb(userIds: string[]) {
  const sortedIds = [...userIds].sort();
  let emulator = process.env.FUNCTIONS_EMULATOR;
  process.env.FUNCTIONS_EMULATOR = "true";

  const db = {
    collection(name: string) {
      return {
        orderBy() {
          return {
            limit(pageSize: number) {
              return {
                startAfter(lastDoc?: { id: string }) {
                  const startIndex = lastDoc
                    ? sortedIds.indexOf(lastDoc.id) + 1
                    : 0;
                  const page = sortedIds.slice(startIndex, startIndex + pageSize);

                  return {
                    async get() {
                      return {
                        empty: page.length === 0,
                        docs: page.map((id) => ({
                          id,
                          data: () => ({}),
                        })),
                      };
                    },
                  };
                },
                async get() {
                  const page = sortedIds.slice(0, pageSize);
                  return {
                    empty: page.length === 0,
                    docs: page.map((id) => ({
                      id,
                      data: () => ({}),
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

  return {
    db,
    restore() {
      if (emulator === undefined) {
        delete process.env.FUNCTIONS_EMULATOR;
      } else {
        process.env.FUNCTIONS_EMULATOR = emulator;
      }
    },
  };
}

test("resolveUserIds returns explicit targetUserIds for selected", async () => {
  const db = {} as FirebaseFirestore.Firestore;

  const userIds = await resolveUserIds(db, {
    targetType: "selected",
    targetUserIds: ["u1", "u2"],
  });

  assert.deepEqual(userIds, ["u1", "u2"]);
});

test("resolveUserIds rejects broadcast-all outside emulator", async () => {
  const emulator = process.env.FUNCTIONS_EMULATOR;
  delete process.env.FUNCTIONS_EMULATOR;

  try {
    const db = {} as FirebaseFirestore.Firestore;
    await assert.rejects(
      () =>
        resolveUserIds(db, {
          targetType: "all",
          targetUserIds: [],
        }),
      BroadcastAllUsersDisabledError
    );
  } finally {
    if (emulator === undefined) {
      delete process.env.FUNCTIONS_EMULATOR;
    } else {
      process.env.FUNCTIONS_EMULATOR = emulator;
    }
  }
});

test("resolveUserIds paginates all users in emulator", async () => {
  const { db, restore } = createPaginatedUsersDb(["u1", "u2", "u3"]);

  try {
    const userIds = await resolveUserIds(db, {
      targetType: "all",
      targetUserIds: [],
    });

    assert.deepEqual(userIds, ["u1", "u2", "u3"]);
  } finally {
    restore();
  }
});

test("isFullUserCollectionScanAllowed is true only in emulator", () => {
  const emulator = process.env.FUNCTIONS_EMULATOR;
  delete process.env.FUNCTIONS_EMULATOR;
  assert.equal(isFullUserCollectionScanAllowed(), false);

  process.env.FUNCTIONS_EMULATOR = "true";
  assert.equal(isFullUserCollectionScanAllowed(), true);

  if (emulator === undefined) {
    delete process.env.FUNCTIONS_EMULATOR;
  } else {
    process.env.FUNCTIONS_EMULATOR = emulator;
  }
});
