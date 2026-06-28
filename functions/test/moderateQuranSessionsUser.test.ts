import test from "node:test";
import assert from "node:assert/strict";

import {
  buildModerateQuranSessionsUserPatch,
  validateModerateQuranSessionsUserRequest,
} from "../src/moderateQuranSessionsUserLogic";

test("validateModerateQuranSessionsUserRequest rejects missing userId", () => {
  assert.throws(
    () => validateModerateQuranSessionsUserRequest({ action: "suspend" }),
    /userId/,
  );
});

test("validateModerateQuranSessionsUserRequest rejects invalid action", () => {
  assert.throws(
    () =>
      validateModerateQuranSessionsUserRequest({
        userId: "user-1",
        action: "block",
      }),
    /Invalid action/,
  );
});

test("buildModerateQuranSessionsUserPatch sets suspended + adminDecision", () => {
  const patch = buildModerateQuranSessionsUserPatch({
    existingProfile: { role: "student", accountStatus: "active" },
    action: "suspend",
    reason: "Testing",
  });

  assert.equal(patch.accountStatus, "suspended");
  assert.equal(patch.restrictionReason, "adminDecision");
  assert.equal(patch.role, "student");
});

test("buildModerateQuranSessionsUserPatch reactivate clears restrictionReason", () => {
  const patch = buildModerateQuranSessionsUserPatch({
    existingProfile: {
      role: "student",
      accountStatus: "suspended",
      restrictionReason: "adminDecision",
    },
    action: "reactivate",
  });

  assert.equal(patch.accountStatus, "active");
  assert.equal(patch.restrictionReason, null);
});
