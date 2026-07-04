import test from "node:test";
import assert from "node:assert/strict";

import {
  teacherProfileUserIdFromData,
  teacherUserIdForSessionAuth,
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

test("teacherUserIdForSessionAuth ignores legacy denormalized profile id", () => {
  assert.equal(
    teacherUserIdForSessionAuth(
      {
        teacherId: "ILAY73dMn4hZDuAWzzJ7",
        teacherUserId: "ILAY73dMn4hZDuAWzzJ7",
      },
      "WV0m6tenTJPDLZE4EdWXBzjADF12",
    ),
    "WV0m6tenTJPDLZE4EdWXBzjADF12",
  );
});

test("teacherUserIdForSessionAuth prefers valid denormalized auth uid", () => {
  assert.equal(
    teacherUserIdForSessionAuth(
      {
        teacherId: "profile_doc",
        teacherUserId: "auth_uid",
      },
      "auth_uid",
    ),
    "auth_uid",
  );
});
