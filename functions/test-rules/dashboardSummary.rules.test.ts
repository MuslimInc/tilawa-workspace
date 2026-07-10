import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";

const PROJECT_ID = "demo-tilawa-rules";
let testEnv: RulesTestEnvironment;

const SUMMARY_PATH = "quran_teacher_profiles/teacher1/dashboard/summary";

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(
        resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_teacher_profiles/teacher1"), {
      userId: "uid_teacher",
      verificationStatus: "verified",
      isPubliclyVisible: true,
    });
    await setDoc(doc(adminDb, SUMMARY_PATH), {
      docType: "teacher_dashboard_summary",
      teacherProfileId: "teacher1",
      sessions: [{ id: "s1", studentId: "student2" }],
    });
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test("rules: owning teacher can read own dashboard summary", async () => {
  const teacherDb = testEnv
    .authenticatedContext("uid_teacher")
    .firestore();
  await assertSucceeds(getDoc(doc(teacherDb, SUMMARY_PATH)));
});

test("rules: other signed-in users cannot read the summary", async () => {
  const studentDb = testEnv.authenticatedContext("uid_student").firestore();
  await assertFails(getDoc(doc(studentDb, SUMMARY_PATH)));
});

test("rules: unauthenticated read is denied", async () => {
  const anonDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anonDb, SUMMARY_PATH)));
});

test("rules: admin can read the summary", async () => {
  const adminDb = testEnv
    .authenticatedContext("uid_admin", { admin: true })
    .firestore();
  await assertSucceeds(getDoc(doc(adminDb, SUMMARY_PATH)));
});

test("rules: even the owner cannot write the summary (CF-only)", async () => {
  const teacherDb = testEnv
    .authenticatedContext("uid_teacher")
    .firestore();
  await assertFails(
    setDoc(doc(teacherDb, SUMMARY_PATH), { sessions: [] }, { merge: true }),
  );
  await assertFails(deleteDoc(doc(teacherDb, SUMMARY_PATH)));
});
