import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import assert from "node:assert/strict";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { collection, doc, getDoc, getDocs, query, setDoc, where, orderBy } from "firebase/firestore";

const PROJECT_ID = "demo-tilawa-rules";
let testEnv: RulesTestEnvironment;

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
});

test.after(async () => {
  await testEnv.cleanup();
});

async function seedSlotLock(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_teacher_profiles/teacher1"), {
      userId: "uid_teacher",
      verificationStatus: "verified",
      isPubliclyVisible: true,
    });
    await setDoc(doc(adminDb, "quran_slot_locks/lock1"), {
      slotId: "teacher1_20260110T0700Z",
      teacherId: "teacher1",
      lockType: "hard",
      aggregateId: "booking1",
      lockedAt: new Date(),
      expiresAt: new Date("2099-01-01T00:00:00.000Z"),
    });
    await setDoc(doc(adminDb, "quran_bookings/booking1"), {
      bookingId: "booking1",
      aggregateId: "booking1",
      sessionId: "session1",
      teacherId: "teacher1",
      studentId: "student2",
      startsAt: new Date("2026-01-10T07:00:00.000Z"),
      endsAt: new Date("2026-01-10T07:30:00.000Z"),
      lifecycleStatus: "scheduled",
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await setDoc(doc(adminDb, "quran_sessions/session1"), {
      sessionId: "session1",
      bookingId: "booking1",
      aggregateId: "booking1",
      teacherId: "teacher1",
      studentId: "student2",
      startsAt: new Date("2026-01-10T07:00:00.000Z"),
      endsAt: new Date("2026-01-10T07:30:00.000Z"),
      lifecycleStatus: "scheduled",
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await setDoc(doc(adminDb, "quran_session_events/event1"), {
      bookingId: "booking1",
      aggregateId: "booking1",
      sessionId: "session1",
      actorId: "student2",
      actorRole: "student",
      action: "create_booking",
      previousStatus: null,
      newStatus: "scheduled",
      timestamp: new Date(),
    });
  });
}

test("rules: signed-in student can read quran_slot_locks for availability", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student1").firestore();
  await assertSucceeds(getDoc(doc(studentDb, "quran_slot_locks/lock1")));
  await assertSucceeds(
    getDocs(
      query(
        collection(studentDb, "quran_slot_locks"),
        where("teacherId", "==", "teacher1"),
      ),
    ),
  );
});

test("rules: signed-in student cannot read another student's quran_sessions", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(getDoc(doc(studentDb, "quran_sessions/session1")));
});

test("rules: session participant can read quran_sessions and audit events", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertSucceeds(getDoc(doc(studentDb, "quran_sessions/session1")));
  await assertSucceeds(getDoc(doc(studentDb, "quran_bookings/booking1")));
  await assertSucceeds(getDoc(doc(studentDb, "quran_session_events/event1")));
  await assertSucceeds(
    getDocs(
      query(
        collection(studentDb, "quran_session_events"),
        where("bookingId", "==", "booking1"),
        orderBy("timestamp"),
      ),
    ),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(studentDb, "quran_session_events"),
        where("sessionId", "==", "session1"),
        orderBy("timestamp"),
      ),
    ),
  );
});

test("rules: teacher profile owner can read session booking and audit events", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const teacherDb = testEnv.authenticatedContext("uid_teacher").firestore();
  await assertSucceeds(getDoc(doc(teacherDb, "quran_sessions/session1")));
  await assertSucceeds(getDoc(doc(teacherDb, "quran_bookings/booking1")));
  await assertSucceeds(getDoc(doc(teacherDb, "quran_session_events/event1")));
  await assertSucceeds(
    getDocs(
      query(
        collection(teacherDb, "quran_session_events"),
        where("sessionId", "==", "session1"),
        orderBy("timestamp"),
      ),
    ),
  );
});

test("rules: non-participant cannot read quran_session_events", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const outsiderDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(getDoc(doc(outsiderDb, "quran_session_events/event1")));
  await assertFails(
    getDocs(
      query(
        collection(outsiderDb, "quran_session_events"),
        where("bookingId", "==", "booking1"),
        orderBy("timestamp"),
      ),
    ),
  );
});

test("rules: unauthenticated user cannot read quran_slot_locks", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const guestDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(guestDb, "quran_slot_locks/lock1")));
});

test("rules: verified teacher owner can update externalMeetingUrl", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_teacher_profiles/teacher1"), {
      userId: "uid_teacher",
      displayName: "Teacher",
      publicBio: "Bio",
      verificationStatus: "verified",
      teachingLanguages: ["ar"],
      specializations: ["tajweed"],
      averageRating: 0,
      reviewCount: 0,
      isActive: true,
      profileCompleteness: "complete",
      isPubliclyVisible: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });

  const teacherDb = testEnv.authenticatedContext("uid_teacher").firestore();
  await assertSucceeds(
    setDoc(
      doc(teacherDb, "quran_teacher_profiles/teacher1"),
      {
        externalMeetingUrl: "https://meet.google.com/teacher-room",
        updatedAt: new Date(),
      },
      { merge: true },
    ),
  );

  const snap = await getDoc(doc(teacherDb, "quran_teacher_profiles/teacher1"));
  assert.equal(snap.data()?.externalMeetingUrl, "https://meet.google.com/teacher-room");
});
