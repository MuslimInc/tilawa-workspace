import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

import { createSessionBooking } from "../src/quranSessions/createSessionBooking";
import {
  clearFirestore,
  db,
  seedUserSession,
  withSessionEpoch,
} from "./support/emulator";

interface BookingResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
}

interface CallableLike {
  run(req: {
    data: unknown;
    auth?: { uid: string; token?: Record<string, unknown> };
  }): Promise<BookingResult>;
}

const booking = createSessionBooking as unknown as CallableLike;

async function seedVerifiedTeacher(
  id: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  await db()
    .collection("quran_teacher_profiles")
    .doc(id)
    .set({
      userId: "uid_teacher1",
      verificationStatus: "verified",
      gender: "male",
      allowedStudentGender: "both",
      canTeachChildren: true,
      requiresGuardianApprovalForChildren: false,
      externalMeetingUrl: "https://meet.example.com/teacher-room",
      ...overrides,
    });
}

async function seedCompleteStudent(
  id: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  await db()
    .collection("users")
    .doc(id)
    .set({
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "male",
        dateOfBirth: Timestamp.fromDate(new Date("1990-01-01T00:00:00Z")),
        countryCode: "EG",
        cityId: "cairo",
        profileCompleted: true,
        ...overrides,
      },
    });
}

function bookingData(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return withSessionEpoch({
    teacherId: "teacher1",
    slotId: "slot1",
    startsAt: new Date(Date.now() + 86_400_000).toISOString(),
    endsAt: new Date(Date.now() + 90_000_000).toISOString(),
    callType: "externalMeeting",
    pricingType: "free",
    ...overrides,
  });
}

function codeOf(error: unknown): string | undefined {
  return (error as { details?: { code?: string } })?.details?.code;
}

test("integration: free booking with a verified teacher is scheduled", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  assert.equal(res.lifecycleStatus, "scheduled");
  const bookingDoc = await db().collection("quran_bookings").doc(res.bookingId).get();
  assert.equal(bookingDoc.get("lifecycleStatus"), "scheduled");
  assert.equal(bookingDoc.get("pricingType"), "free");
  assert.equal(bookingDoc.get("studentId"), "student1");
  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(
    sessionDoc.get("meetingLink"),
    "https://meet.example.com/teacher-room",
  );
  assert.equal(sessionDoc.get("teacherUserId"), "uid_teacher1");
  assert.equal(bookingDoc.get("teacherUserId"), "uid_teacher1");
  const lock = await db().collection("quran_slot_locks").doc("slot1").get();
  assert.equal(lock.exists, true);
});

test("integration: booking notification targets teacher auth uid not profile id", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  const notifications = await db()
    .collection("quran_session_notifications")
    .where("aggregateId", "==", res.bookingId)
    .get();
  assert.equal(notifications.size, 1);
  const recipients = notifications.docs[0].get("recipientUserIds") as string[];
  assert.deepEqual(recipients.sort(), ["student1", "uid_teacher1"].sort());
});

test("integration: an unverified teacher is rejected server-side", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", { verificationStatus: "pending" });
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } }),
    (e) => codeOf(e) === "teacher_not_verified",
  );
});

test("integration: a disallowed gender combination is rejected server-side", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", { allowedStudentGender: "maleOnly" });
  await seedCompleteStudent("student1", { gender: "female" });
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } }),
    (e) => codeOf(e) === "gender_not_allowed",
  );
});

test("integration: a paid teacher cannot be booked 'free' while payments are disabled", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  // A pricing doc for the student's market makes the teacher server-side "paid",
  // regardless of the client-sent pricingType.
  await db()
    .collection("quran_teacher_profiles")
    .doc("teacher1")
    .collection("pricing")
    .doc("EG_cairo")
    .set({ amount: 10, currencyCode: "USD" });

  await assert.rejects(
    booking.run({
      data: bookingData({ pricingType: "free" }),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "payment_provider_unavailable",
  );
});

test("integration: double-booking the same slot is rejected", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedCompleteStudent("student2");
  await seedUserSession("student1");
  await seedUserSession("student2");

  await booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } });

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student2", token: {} } }),
    (e) => (e as { code?: string })?.code === "already-exists",
  );
});

test("integration: replay with same idempotency key returns same booking", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const data = bookingData({ idempotencyKey: "idem-booking-1" });
  const auth = { uid: "student1", token: {} };

  const first = await booking.run({ data, auth });
  const second = await booking.run({ data, auth });

  assert.equal(first.bookingId, second.bookingId);
  assert.equal(first.sessionId, second.sessionId);

  const bookings = await db().collection("quran_bookings").get();
  const sessions = await db().collection("quran_sessions").get();
  const events = await db().collection("quran_session_events").get();
  const notifications = await db().collection("quran_session_notifications").get();

  assert.equal(bookings.size, 1);
  assert.equal(sessions.size, 1);
  assert.equal(events.size, 1);
  assert.equal(notifications.size, 1);
});

test("integration: voice booking stores mock call provider metadata", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ callType: "voiceCall" }),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(sessionDoc.get("callProvider"), "mock");
  assert.equal(sessionDoc.get("providerSessionId"), res.sessionId);
  assert.equal(sessionDoc.get("callType"), "voiceCall");
});

test("integration: group booking is rejected", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({
      data: bookingData({ bookingType: "group" }),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "group_booking_not_supported",
  );
});

test("integration: client agora provider hint is rejected when agora disabled", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({
      data: bookingData({ callType: "voiceCall", callProvider: "agora" }),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "unsupported_call_provider",
  );
});

test("integration: client agora provider hint is honored when platform enables agora", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  await db()
    .collection("quran_session_platform_config")
    .doc("global")
    .set({ enabledCallProviders: ["external", "mock", "agora"] });

  const res = await booking.run({
    data: bookingData({ callType: "videoCall", callProvider: "agora" }),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(sessionDoc.get("callProvider"), "agora");
});

test("integration: different idempotency key on same slot is blocked by lock", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedCompleteStudent("student2");
  await seedUserSession("student1");
  await seedUserSession("student2");

  await booking.run({
    data: bookingData({ idempotencyKey: "idem-a" }),
    auth: { uid: "student1", token: {} },
  });

  await assert.rejects(
    booking.run({
      data: bookingData({ idempotencyKey: "idem-b" }),
      auth: { uid: "student2", token: {} },
    }),
    (e) => (e as { code?: string })?.code === "already-exists",
  );
});

test("integration: stale session epoch rejects booking", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await db().collection("users").doc("student1").set({
    session: { epoch: 2, activeDeviceId: "device-b" },
  });

  await assert.rejects(
    booking.run({
      data: withSessionEpoch(bookingData(), 1),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "session_epoch_stale",
  );
});

test("integration: external booking without meeting URL is rejected", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", { externalMeetingUrl: "" });
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } }),
    (e) => codeOf(e) === "meeting_link_required",
  );
});

test("integration: external booking uses platform default meeting URL", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", { externalMeetingUrl: "" });
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  await db()
    .collection("quran_session_platform_config")
    .doc("global")
    .set({
      defaultExternalMeetingUrl: "https://meet.example.com/platform-default",
    });

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(
    sessionDoc.get("meetingLink"),
    "https://meet.example.com/platform-default",
  );
  assert.equal(sessionDoc.get("callProvider"), "external");
});

test("integration: external booking reads legacy teacher meeting_link field", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", {
    externalMeetingUrl: "",
    meeting_link: "https://meet.example.com/legacy-teacher-room",
  });
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(
    sessionDoc.get("meetingLink"),
    "https://meet.example.com/legacy-teacher-room",
  );
});

test("integration: voice booking rejects malformed enabledCallProviders safely", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  await db()
    .collection("quran_session_platform_config")
    .doc("global")
    .set({ enabledCallProviders: "external,mock" });

  await assert.rejects(
    booking.run({
      data: bookingData({ callType: "voiceCall" }),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "unsupported_call_provider",
  );
});

test("integration: production-shaped teacher profile external booking", async () => {
  await clearFirestore();
  const teacherId = "a1sYAAaBHg5aq1uwya0o";
  await db()
    .collection("quran_teacher_profiles")
    .doc(teacherId)
    .set({
      userId: "uid_teacher_owner",
      displayName: "Teacher Beta",
      publicBio: "Teaching tajweed",
      verificationStatus: "verified",
      gender: "male",
      allowedStudentGender: "both",
      canTeachChildren: true,
      requiresGuardianApprovalForChildren: false,
      externalMeetingUrl: "https://meet.google.com/fiy-jjux-mab",
      teachingLanguages: ["ar"],
      specializations: ["tajweed"],
      averageRating: 0,
      reviewCount: 0,
      isActive: true,
      profileCompleteness: "complete",
      isPubliclyVisible: true,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ teacherId }),
    auth: { uid: "student1", token: {} },
  });

  assert.equal(res.lifecycleStatus, "scheduled");
  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(sessionDoc.get("callProvider"), "external");
  assert.equal(
    sessionDoc.get("meetingLink"),
    "https://meet.google.com/fiy-jjux-mab",
  );
});

test("integration: video booking stores mock call provider metadata", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ callType: "videoCall" }),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(sessionDoc.get("callProvider"), "mock");
  assert.equal(sessionDoc.get("providerSessionId"), res.sessionId);
  assert.equal(sessionDoc.get("callType"), "videoCall");
  assert.equal(sessionDoc.get("joinToken"), null);
});

test("integration: video booking stores agora when platform config enables it", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  await db()
    .collection("quran_session_platform_config")
    .doc("global")
    .set({ enabledCallProviders: ["external", "mock", "agora"] });

  const res = await booking.run({
    data: bookingData({ callType: "videoCall" }),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  assert.equal(sessionDoc.get("callProvider"), "agora");
  assert.equal(sessionDoc.get("providerSessionId"), res.sessionId);
  assert.equal(sessionDoc.get("callType"), "videoCall");
});

test("integration: client webrtc provider hint is rejected when webrtc disabled", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({
      data: bookingData({ callType: "videoCall", callProvider: "webrtc" }),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "unsupported_call_provider",
  );
});

test("integration: unsupported call type is rejected", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({
      data: bookingData({ callType: "hologramCall" }),
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "unsupported_session_mode",
  );
});

test("integration: booking persists participants and audit event", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  const sessionDoc = await db().collection("quran_sessions").doc(res.sessionId).get();
  const participants = sessionDoc.get("participants") as Array<{
    userId: string;
    role: string;
  }>;
  assert.equal(participants.length, 2);
  assert.deepEqual(
    participants.map((p) => p.role).sort(),
    ["student", "teacher"],
  );
  assert.equal(
    participants.find((p) => p.role === "student")?.userId,
    "student1",
  );
  assert.equal(
    participants.find((p) => p.role === "teacher")?.userId,
    "teacher1",
  );

  const events = await db()
    .collection("quran_session_events")
    .where("sessionId", "==", res.sessionId)
    .get();
  assert.equal(events.size, 1);
  assert.equal(events.docs[0].get("action"), "create_booking");
  assert.equal(events.docs[0].get("actorId"), "student1");
});
