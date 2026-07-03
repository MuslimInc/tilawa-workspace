import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

import { createSessionBooking } from "../src/quranSessions/createSessionBooking";
import { respondToBookingRequest } from "../src/quranSessions/respondToBookingRequest";
import {
  db,
  prepareIntegrationFirestore,
  seedUserSession,
  withSessionEpoch,
} from "./support/emulator";

interface BookingResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
}

interface RespondResult {
  bookingId: string;
  lifecycleStatus: string;
}

interface CallableLike<T> {
  run(req: {
    data: unknown;
    auth?: { uid: string; token?: Record<string, unknown> };
  }): Promise<T>;
}

const booking = createSessionBooking as unknown as CallableLike<BookingResult>;
const respond =
  respondToBookingRequest as unknown as CallableLike<RespondResult>;

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
    slotId: "slot-respond-1",
    startsAt: new Date(Date.now() + 86_400_000).toISOString(),
    endsAt: new Date(Date.now() + 90_000_000).toISOString(),
    callType: "externalMeeting",
    pricingType: "free",
    ...overrides,
  });
}

test("integration: teacher accept moves booking to scheduled", async () => {
  await prepareIntegrationFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  await seedUserSession("uid_teacher1");

  const created = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });
  assert.equal(created.lifecycleStatus, "pending_tutor_approval");

  const accepted = await respond.run({
    data: withSessionEpoch({ bookingId: created.bookingId, response: "accept" }),
    auth: { uid: "uid_teacher1", token: {} },
  });
  assert.equal(accepted.lifecycleStatus, "scheduled");

  const bookingDoc = await db()
    .collection("quran_bookings")
    .doc(created.bookingId)
    .get();
  assert.equal(bookingDoc.get("lifecycleStatus"), "scheduled");
  const teacherActions = bookingDoc.get("allowedActionsTeacher") as string[];
  assert.equal(teacherActions.includes("respondToBookingRequest"), false);
});

test("integration: teacher reject releases slot", async () => {
  await prepareIntegrationFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");
  await seedUserSession("uid_teacher1");

  const created = await booking.run({
    data: bookingData({ slotId: "slot-reject-1" }),
    auth: { uid: "student1", token: {} },
  });

  const rejected = await respond.run({
    data: withSessionEpoch({
      bookingId: created.bookingId,
      response: "reject",
      reason: "Unavailable",
    }),
    auth: { uid: "uid_teacher1", token: {} },
  });
  assert.equal(rejected.lifecycleStatus, "rejected_by_tutor");

  const lock = await db().collection("quran_slot_locks").doc("slot-reject-1").get();
  assert.equal(lock.exists, false);
});

test("integration: student cannot respond to booking request", async () => {
  await prepareIntegrationFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const created = await booking.run({
    data: bookingData({ slotId: "slot-student-blocked" }),
    auth: { uid: "student1", token: {} },
  });

  await assert.rejects(
    respond.run({
      data: withSessionEpoch({
        bookingId: created.bookingId,
        response: "accept",
      }),
      auth: { uid: "student1", token: {} },
    }),
    (error: unknown) => (error as { code?: string })?.code === "permission-denied",
  );
});

test("integration: non-participant cannot respond to booking request", async () => {
  await prepareIntegrationFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("child1", {
    dateOfBirth: Timestamp.fromDate(new Date("2018-01-01T00:00:00Z")),
  });
  await seedCompleteStudent("other1");
  await seedUserSession("child1");
  await seedUserSession("other1");

  const created = await booking.run({
    data: bookingData({ slotId: "slot-non-participant-blocked" }),
    auth: { uid: "child1", token: {} },
  });

  await assert.rejects(
    respond.run({
      data: withSessionEpoch({
        bookingId: created.bookingId,
        response: "accept",
      }),
      auth: { uid: "other1", token: {} },
    }),
    (error: unknown) => (error as { code?: string })?.code === "permission-denied",
  );
});
