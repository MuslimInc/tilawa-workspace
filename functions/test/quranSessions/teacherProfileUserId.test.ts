import test from "node:test";
import assert from "node:assert/strict";

import {
  teacherProfileUserIdFromData,
} from "../../src/quranSessions/teacherProfileUserId";

test("teacherProfileUserIdFromData returns profile userId when present", () => {
  assert.equal(
    teacherProfileUserIdFromData("profile_doc", { userId: "auth_uid" }),
    "auth_uid",
  );
});

test("teacherProfileUserIdFromData falls back to profile doc id", () => {
  assert.equal(
    teacherProfileUserIdFromData("legacy_uid_profile", {}),
    "legacy_uid_profile",
  );
});
