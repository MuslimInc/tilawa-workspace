import test from "node:test";
import assert from "node:assert/strict";

import { resolveUserIds } from "../src/notifications/resolveUserIds";

function createPaginatedUsersDb(userIds: string[]) {
  const sortedIds = [...userIds].sort();

  const db = {
    collection(name: string) {
      assert.equal(name, "users");
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

  return db;
}

test("resolveUserIds returns explicit targetUserIds for selected", async () => {
  const db = {} as FirebaseFirestore.Firestore;

  const userIds = await resolveUserIds(db, {
    targetType: "selected",
    targetUserIds: ["u1", "u2"],
  });

  assert.deepEqual(userIds, ["u1", "u2"]);
});

test("resolveUserIds paginates all users for broadcast", async () => {
  const db = createPaginatedUsersDb(["u1", "u2", "u3"]);

  const userIds = await resolveUserIds(db, {
    targetType: "all",
    targetUserIds: [],
  });

  assert.deepEqual(userIds, ["u1", "u2", "u3"]);
});
