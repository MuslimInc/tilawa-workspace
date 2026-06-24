import test from "node:test";
import assert from "node:assert/strict";

import {
  isAdmin,
  requireAdmin,
  requireAdminOrSystemActor,
  requireAuthenticatedUid,
  requireParticipantOrAdmin,
  requireValidSessionEpochUnlessAdmin,
  resolveActorRole,
} from "../../src/quranSessions/sessionAuth";

function authRequest(
  uid: string,
  options: {
    admin?: boolean;
    data?: Record<string, unknown>;
  } = {},
) {
  return {
    auth: {
      uid,
      token: options.admin ? { admin: true } : {},
    },
    data: options.data ?? {},
  } as never;
}

test("requireAuthenticatedUid returns uid when signed in", () => {
  assert.equal(requireAuthenticatedUid(authRequest("user_1")), "user_1");
});

test("requireAuthenticatedUid rejects anonymous callers", () => {
  assert.throws(
    () => requireAuthenticatedUid({ data: {} } as never),
    (error: { code?: string }) => error.code === "unauthenticated",
  );
});

test("isAdmin reflects custom claim", () => {
  assert.equal(isAdmin(authRequest("admin_1", { admin: true })), true);
  assert.equal(isAdmin(authRequest("user_1")), false);
});

test("requireAdmin rejects non-admin callers", () => {
  assert.throws(
    () => requireAdmin(authRequest("user_1")),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});

test("requireAdmin returns uid for admin callers", () => {
  assert.equal(requireAdmin(authRequest("admin_1", { admin: true })), "admin_1");
});

test("requireValidSessionEpochUnlessAdmin skips epoch check for admin", async () => {
  await assert.doesNotReject(() =>
    requireValidSessionEpochUnlessAdmin(
      authRequest("admin_1", { admin: true, data: {} }),
      "admin_1",
    ),
  );
});

test("resolveActorRole returns student for booking student", () => {
  assert.equal(
    resolveActorRole(authRequest("student_1"), "student", {
      studentId: "student_1",
      teacherId: "teacher_1",
    }),
    "student",
  );
});

test("resolveActorRole returns teacher when teacherUserId differs from profile id", () => {
  assert.equal(
    resolveActorRole(authRequest("auth_teacher_uid"), "teacher", {
      studentId: "student_1",
      teacherId: "profile_doc_id",
    }, "auth_teacher_uid"),
    "teacher",
  );
});

test("resolveActorRole rejects teacher when profile id used instead of auth uid", () => {
  assert.throws(
    () =>
      resolveActorRole(authRequest("auth_teacher_uid"), "teacher", {
        studentId: "student_1",
        teacherId: "profile_doc_id",
      }),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});

test("requireParticipantOrAdmin returns teacher actor with teacherUserId", () => {
  const result = requireParticipantOrAdmin(
    authRequest("auth_teacher_uid"),
    {
      studentId: "student_1",
      teacherId: "profile_doc_id",
    },
    "auth_teacher_uid",
  );

  assert.deepEqual(result, { uid: "auth_teacher_uid", actor: "teacher" });
});

test("resolveActorRole returns teacher for booking teacher", () => {
  assert.equal(
    resolveActorRole(authRequest("teacher_1"), "teacher", {
      studentId: "student_1",
      teacherId: "teacher_1",
    }),
    "teacher",
  );
});

test("resolveActorRole returns admin for admin callers", () => {
  assert.equal(
    resolveActorRole(authRequest("admin_1", { admin: true }), "admin", {
      studentId: "student_1",
      teacherId: "teacher_1",
    }),
    "admin",
  );
});

test("resolveActorRole rejects role spoofing", () => {
  assert.throws(
    () =>
      resolveActorRole(authRequest("student_1"), "teacher", {
        studentId: "student_1",
        teacherId: "teacher_1",
      }),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});

test("requireParticipantOrAdmin returns actor for student", () => {
  const result = requireParticipantOrAdmin(authRequest("student_1"), {
    studentId: "student_1",
    teacherId: "teacher_1",
  });

  assert.deepEqual(result, { uid: "student_1", actor: "student" });
});

test("requireParticipantOrAdmin rejects outsiders", () => {
  assert.throws(
    () =>
      requireParticipantOrAdmin(authRequest("outsider"), {
        studentId: "student_1",
        teacherId: "teacher_1",
      }),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});

test("resolveActorRole returns system when admin claims system", () => {
  assert.equal(
    resolveActorRole(authRequest("admin_1", { admin: true }), "system", {
      studentId: "student_1",
      teacherId: "teacher_1",
    }),
    "system",
  );
});

test("resolveActorRole rejects non-participants", () => {
  assert.throws(
    () =>
      resolveActorRole(authRequest("outsider"), undefined, {
        studentId: "student_1",
        teacherId: "teacher_1",
      }),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});

test("requireParticipantOrAdmin returns teacher actor", () => {
  const result = requireParticipantOrAdmin(authRequest("teacher_1"), {
    studentId: "student_1",
    teacherId: "teacher_1",
  });

  assert.deepEqual(result, { uid: "teacher_1", actor: "teacher" });
});

test("requireParticipantOrAdmin returns admin actor", () => {
  const result = requireParticipantOrAdmin(
    authRequest("admin_1", { admin: true }),
    {
      studentId: "student_1",
      teacherId: "teacher_1",
    },
  );

  assert.deepEqual(result, { uid: "admin_1", actor: "admin" });
});

test("requireAdminOrSystemActor rejects claimed system actor", () => {
  assert.throws(
    () => requireAdminOrSystemActor(authRequest("admin_1", { admin: true }), "system"),
    (error: { code?: string }) => error.code === "permission-denied",
  );
});

test("requireAdminOrSystemActor returns admin actor", () => {
  const result = requireAdminOrSystemActor(
    authRequest("admin_1", { admin: true }),
    "admin",
  );

  assert.deepEqual(result, { uid: "admin_1", actor: "admin" });
});
