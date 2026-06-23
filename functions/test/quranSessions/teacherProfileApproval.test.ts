import test from "node:test";
import assert from "node:assert/strict";
import { FieldValue } from "firebase-admin/firestore";

import {
  buildApprovedTeacherProfile,
  computeIsPubliclyVisible,
  recomputeVisibilityFields,
} from "../../src/quranSessions/teacherProfileApproval";

const NOW = FieldValue.serverTimestamp();

function baseApp() {
  return {
    userId: "user_1",
    publicDisplayName: "Ustad Ahmad",
    bio: "Experienced teacher",
    teachingLanguages: ["ar"],
    specializations: ["tajweed"],
  };
}

test("buildApprovedTeacherProfile always sets isActive true", () => {
  const profile = buildApprovedTeacherProfile({
    app: baseApp(),
    user: {},
    now: NOW,
  });

  assert.equal(profile.isActive, true);
  assert.equal(profile.verificationStatus, "verified");
  assert.equal(profile.profileCompleteness, "complete");
  assert.equal(profile.isPubliclyVisible, true);
});

test("buildApprovedTeacherProfile sets isActive true for incomplete fields", () => {
  const profile = buildApprovedTeacherProfile({
    app: { userId: "user_1", bio: "" },
    user: {},
    now: NOW,
  });

  assert.equal(profile.isActive, true);
  assert.equal(profile.profileCompleteness, "incomplete");
  assert.equal(profile.isPubliclyVisible, false);
});

test("recomputeVisibilityFields respects isActive flag", () => {
  const visible = recomputeVisibilityFields({
    profileCompleteness: "complete",
    verificationStatus: "verified",
    isActive: true,
  });
  const hidden = recomputeVisibilityFields({
    profileCompleteness: "complete",
    verificationStatus: "verified",
    isActive: false,
  });

  assert.equal(visible.isPubliclyVisible, true);
  assert.equal(hidden.isPubliclyVisible, false);
  assert.equal(
    computeIsPubliclyVisible({
      profileCompleteness: "complete",
      verificationStatus: "verified",
      isActive: false,
    }),
    false,
  );
});
