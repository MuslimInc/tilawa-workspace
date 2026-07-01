import test from "node:test";
import assert from "node:assert/strict";

import { executeLookupUserAdminClaims } from "../src/userDeletion/lookupUserAdminClaims";

test("executeLookupUserAdminClaims returns empty for no ids", async () => {
  const result = await executeLookupUserAdminClaims({ userIds: [] });
  assert.deepEqual(result, { adminUserIds: [], authBackedUserIds: [] });
});

test("executeLookupUserAdminClaims rejects too many ids", async () => {
  const userIds = Array.from({ length: 101 }, (_, index) => `uid-${index}`);

  await assert.rejects(
    () => executeLookupUserAdminClaims({ userIds }),
    /too-many-user-ids/,
  );
});

