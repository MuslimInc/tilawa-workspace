import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

import { createSessionBooking } from "../src/quranSessions/createSessionBooking";
import { clearFirestore, db } from "./support/emulator";

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
      verificationStatus: "verified",
      gender: "male",
      allowedStudentGender: "both",
      canTeachChildren: true,
      requiresGuardianApprovalForChildren: false,
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
  return {
    teacherId: "teacher1",
    slotId: "slot1",
    startsAt: new Date(Date.now() + 86_400_000).toISOString(),
    endsAt: new Date(Date.now() + 90_000_000).toISOString(),
    callType: "externalMeeting",
    pricingType: "free",
    ...overrides,
  };
}

function codeOf(error: unknown): string | undefined {
  return (error as { details?: { code?: string } })?.details?.code;
}

test("integration: free booking with a verified teacher is scheduled", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  assert.equal(res.lifecycleStatus, "scheduled");
  const bookingDoc = await db().collection("quran_bookings").doc(res.bookingId).get();
  assert.equal(bookingDoc.get("lifecycleStatus"), "scheduled");
  assert.equal(bookingDoc.get("pricingType"), "free");
  assert.equal(bookingDoc.get("studentId"), "student1");
  const lock = await db().collection("quran_slot_locks").doc("slot1").get();
  assert.equal(lock.exists, true);
});

test("integration: an unverified teacher is rejected server-side", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", { verificationStatus: "pending" });
  await seedCompleteStudent("student1");

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } }),
    (e) => codeOf(e) === "teacher_not_verified",
  );
});

test("integration: a disallowed gender combination is rejected server-side", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1", { allowedStudentGender: "maleOnly" });
  await seedCompleteStudent("student1", { gender: "female" });

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } }),
    (e) => codeOf(e) === "gender_not_allowed",
  );
});

test("integration: a paid teacher cannot be booked 'free' while payments are disabled", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
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

test("integration: different idempotency key on same slot is blocked by lock", async () => {
  await clearFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedCompleteStudent("student2");

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
