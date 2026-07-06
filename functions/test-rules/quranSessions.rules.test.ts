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
import { collection, deleteDoc, doc, getDoc, getDocs, limit, query, setDoc, where, orderBy } from "firebase/firestore";

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

test("rules: signed-in user can read missing booking and session docs", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student1").firestore();
  await assertSucceeds(getDoc(doc(studentDb, "quran_bookings/missing_booking")));
  await assertSucceeds(getDoc(doc(studentDb, "quran_sessions/missing_session")));
});

test("rules: session participant can read quran_sessions and audit events", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertSucceeds(getDoc(doc(studentDb, "quran_sessions/session1")));
  await assertSucceeds(getDoc(doc(studentDb, "quran_bookings/booking1")));
  await assertSucceeds(
    getDocs(
      query(
        collection(studentDb, "quran_bookings"),
        where("sessionId", "==", "session1"),
        limit(1),
      ),
    ),
  );
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

async function seedPublicSessionConfig(): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_session_platform_config/global"), {
      childAgeThreshold: 13,
      minimumStudentAgeYears: 5,
      requireGuardianApprovalForChildren: true,
      updatedAt: new Date(),
    });
    await setDoc(doc(adminDb, "quran_session_market_configs/EG"), {
      countryCode: "EG",
      countryName: "Egypt",
      currencyCode: "EGP",
      timezone: "Africa/Cairo",
      isEnabled: true,
      sortOrder: 0,
      updatedAt: new Date(),
    });
    await setDoc(doc(adminDb, "quran_session_market_configs/EG/cities/cairo"), {
      cityId: "cairo",
      cityName: "Cairo",
      countryCode: "EG",
      timezone: "Africa/Cairo",
      currencyCode: "EGP",
      isEnabled: true,
      sortOrder: 0,
      updatedAt: new Date(),
    });
  });
}

test("rules: unauthenticated user can read public session config", async () => {
  await testEnv.clearFirestore();
  await seedPublicSessionConfig();

  const guestDb = testEnv.unauthenticatedContext().firestore();
  await assertSucceeds(
    getDoc(doc(guestDb, "quran_session_platform_config/global")),
  );
  await assertSucceeds(getDoc(doc(guestDb, "quran_session_market_configs/EG")));
  await assertSucceeds(
    getDoc(doc(guestDb, "quran_session_market_configs/EG/cities/cairo")),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(guestDb, "quran_session_market_configs"),
        where("isEnabled", "==", true),
        orderBy("sortOrder"),
      ),
    ),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(guestDb, "quran_session_market_configs/EG/cities"),
        where("isEnabled", "==", true),
        orderBy("sortOrder"),
      ),
    ),
  );
});

test("rules: unauthenticated user cannot write public session config", async () => {
  await testEnv.clearFirestore();
  await seedPublicSessionConfig();

  const guestDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(
    setDoc(doc(guestDb, "quran_session_platform_config/global"), {
      childAgeThreshold: 99,
    }),
  );
  await assertFails(
    setDoc(doc(guestDb, "quran_session_market_configs/EG"), {
      countryCode: "EG",
      isEnabled: false,
    }),
  );
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

test("rules: verified teacher owner cannot self-set sessionPriceOverride", async () => {
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
  // Pricing is admin-controlled — a teacher must not set their own price.
  await assertFails(
    setDoc(
      doc(teacherDb, "quran_teacher_profiles/teacher1"),
      {
        sessionPriceOverride: { enabled: true, amount: 0 },
        updatedAt: new Date(),
      },
      { merge: true },
    ),
  );
});

test("rules: client cannot create or mutate quran_bookings", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertFails(
    setDoc(doc(studentDb, "quran_bookings/booking_new"), {
      bookingId: "booking_new",
      aggregateId: "booking_new",
      sessionId: "session_new",
      teacherId: "teacher1",
      studentId: "student2",
      startsAt: new Date("2026-01-11T07:00:00.000Z"),
      endsAt: new Date("2026-01-11T07:30:00.000Z"),
      lifecycleStatus: "scheduled",
      createdAt: new Date(),
      updatedAt: new Date(),
    }),
  );
  await assertFails(
    setDoc(
      doc(studentDb, "quran_bookings/booking1"),
      { lifecycleStatus: "cancelledByStudent" },
      { merge: true },
    ),
  );
});

test("rules: client cannot create or mutate quran_sessions", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertFails(
    setDoc(doc(studentDb, "quran_sessions/session_new"), {
      sessionId: "session_new",
      bookingId: "booking_new",
      aggregateId: "booking_new",
      teacherId: "teacher1",
      studentId: "student2",
      startsAt: new Date("2026-01-11T07:00:00.000Z"),
      endsAt: new Date("2026-01-11T07:30:00.000Z"),
      lifecycleStatus: "scheduled",
      callType: "externalMeeting",
      createdAt: new Date(),
      updatedAt: new Date(),
    }),
  );
  await assertFails(
    setDoc(
      doc(studentDb, "quran_sessions/session1"),
      { callProvider: "agora" },
      { merge: true },
    ),
  );
  // ADR-008 Phase 2: liveLocks is a Cloud-Functions-only field on the session
  // doc. A client must not be able to forge or overwrite a lease.
  await assertFails(
    setDoc(
      doc(studentDb, "quran_sessions/session1"),
      {
        liveLocks: {
          student2: {
            deviceId: "attacker_device",
            identity: "student2#attacker_device",
            leaseUntil: new Date("2099-01-01T00:00:00.000Z"),
            lockEpoch: 99,
            updatedAt: new Date(),
          },
        },
      },
      { merge: true },
    ),
  );
});

async function seedRescheduleRequest(): Promise<void> {
  await seedSlotLock();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_reschedule_requests/req1"), {
      bookingId: "booking1",
      requestedByUserId: "student2",
      requestedByRole: "student",
      reason: "Need a later slot.",
      newStartsAt: new Date("2026-01-11T09:00:00.000Z"),
      status: "pending",
      createdAt: new Date(),
    });
  });
}

test("rules: booking participant can read quran_reschedule_requests", async () => {
  await testEnv.clearFirestore();
  await seedRescheduleRequest();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertSucceeds(
    getDoc(doc(studentDb, "quran_reschedule_requests/req1")),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(studentDb, "quran_reschedule_requests"),
        where("bookingId", "==", "booking1"),
        where("status", "==", "pending"),
        orderBy("createdAt", "desc"),
      ),
    ),
  );

  const teacherDb = testEnv.authenticatedContext("uid_teacher").firestore();
  await assertSucceeds(
    getDoc(doc(teacherDb, "quran_reschedule_requests/req1")),
  );
});

test("rules: non-participant cannot read quran_reschedule_requests", async () => {
  await testEnv.clearFirestore();
  await seedRescheduleRequest();

  const outsiderDb = testEnv.authenticatedContext("student1").firestore();
  await assertFails(
    getDoc(doc(outsiderDb, "quran_reschedule_requests/req1")),
  );
  await assertFails(
    getDocs(
      query(
        collection(outsiderDb, "quran_reschedule_requests"),
        where("bookingId", "==", "booking1"),
        where("status", "==", "pending"),
        orderBy("createdAt", "desc"),
      ),
    ),
  );
});

test("rules: verified teacher owner can delete unbooked availability slot", async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_teacher_profiles/teacher1"), {
      userId: "uid_teacher",
      verificationStatus: "verified",
      isPubliclyVisible: true,
    });
    await setDoc(
      doc(adminDb, "quran_teacher_profiles/teacher1/availability/slot1"),
      {
        teacherId: "teacher1",
        startsAt: new Date("2026-06-24T10:00:00.000Z"),
        endsAt: new Date("2026-06-24T10:30:00.000Z"),
        isBooked: false,
      },
    );
  });

  const teacherDb = testEnv.authenticatedContext("uid_teacher").firestore();
  await assertSucceeds(
    deleteDoc(doc(teacherDb, "quran_teacher_profiles/teacher1/availability/slot1")),
  );
});

test("rules: client cannot write quran_session_events", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertFails(
    setDoc(doc(studentDb, "quran_session_events/event_new"), {
      bookingId: "booking1",
      aggregateId: "booking1",
      sessionId: "session1",
      actorId: "student2",
      actorRole: "student",
      action: "join_session",
      previousStatus: "scheduled",
      newStatus: "inProgress",
      timestamp: new Date(),
    }),
  );
});

test("rules: participant can read callTracking summary", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_sessions/session1/callTracking/summary"), {
      sessionId: "session1",
      reconnectCount: 0,
      bothParticipantsConnectedSeconds: 0,
      lateGraceMinutes: 5,
    });
  });

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertSucceeds(
    getDoc(doc(studentDb, "quran_sessions/session1/callTracking/summary")),
  );
});

test("rules: participant can create own call_events", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertSucceeds(
    setDoc(doc(studentDb, "quran_sessions/session1/call_events/event_join"), {
      eventId: "event_join",
      sessionId: "session1",
      eventType: "joinSucceeded",
      actorId: "student2",
      actorRole: "student",
      recordedAt: new Date(),
    }),
  );
});

test("rules: client cannot patch callTracking aggregate", async () => {
  await testEnv.clearFirestore();
  await seedSlotLock();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "quran_sessions/session1/callTracking/summary"), {
      sessionId: "session1",
      reconnectCount: 0,
      bothParticipantsConnectedSeconds: 0,
      lateGraceMinutes: 5,
    });
  });

  const studentDb = testEnv.authenticatedContext("student2").firestore();
  await assertFails(
    setDoc(
      doc(studentDb, "quran_sessions/session1/callTracking/summary"),
      { reconnectCount: 99 },
      { merge: true },
    ),
  );
});
