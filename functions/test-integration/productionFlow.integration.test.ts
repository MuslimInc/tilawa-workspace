import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

import { cancelSessionBooking } from "../src/quranSessions/cancelSessionBooking";
import { createSessionBooking } from "../src/quranSessions/createSessionBooking";
import { issueSessionRtcTokenForRequest } from "../src/quranSessions/issueSessionRtcTokenService";
import {
  db,
  patchPlatformConfig,
  prepareIntegrationFirestore,
  seedUserSession,
  withSessionEpoch,
} from "./support/emulator";

interface BookingResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
}

interface CallableLike<T> {
  run(req: {
    data: unknown;
    auth?: { uid: string; token?: Record<string, unknown> };
  }): Promise<T>;
}

const booking = createSessionBooking as unknown as CallableLike<BookingResult>;
const cancelBooking =
  cancelSessionBooking as unknown as CallableLike<{ lifecycleStatus: string }>;

async function seedVerifiedTeacher(
  id: string,
  overrides: Record<string, unknown> = {},
): Promise<void> {
  await db()
    .collection("quran_teacher_profiles")
    .doc(id)
    .set({
      userId: `uid_${id}`,
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
    callType: "videoCall",
    pricingType: "free",
    ...overrides,
  });
}

function codeOf(error: unknown): string | undefined {
  return (error as { details?: { code?: string } })?.details?.code;
}

test("integration: tutor approval booking stays pending and exposes allowed actions", async () => {
  await prepareIntegrationFirestore();
  await patchPlatformConfig({ quranTutorBookingMode: "requiresTutorApproval" });
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData(),
    auth: { uid: "student1", token: {} },
  });

  assert.equal(res.lifecycleStatus, "pending_tutor_approval");
  const bookingDoc = await db().collection("quran_bookings").doc(res.bookingId).get();
  const studentActions = bookingDoc.get("allowedActionsStudent") as string[];
  assert.ok(studentActions.includes("cancel"));
  assert.equal(studentActions.includes("join"), false);
});

test("integration: student cancel from pending releases slot and clears join", async () => {
  await prepareIntegrationFirestore();
  await patchPlatformConfig({ quranTutorBookingMode: "requiresTutorApproval" });
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ slotId: "slot-pending-cancel" }),
    auth: { uid: "student1", token: {} },
  });

  await cancelBooking.run({
    data: withSessionEpoch({
      bookingId: res.bookingId,
      reason: "Changed plans",
      actorRole: "student",
    }),
    auth: { uid: "student1", token: {} },
  });

  const bookingDoc = await db().collection("quran_bookings").doc(res.bookingId).get();
  assert.equal(bookingDoc.get("lifecycleStatus"), "cancelled_by_student");
  const studentActions = bookingDoc.get("allowedActionsStudent") as string[];
  assert.equal(studentActions.includes("cancel"), false);
  assert.equal(studentActions.includes("join"), false);

  const lock = await db().collection("quran_slot_locks").doc("slot-pending-cancel").get();
  assert.equal(lock.exists, false);
});

test("integration: join token rejected before join window", async () => {
  await prepareIntegrationFirestore();
  await patchPlatformConfig({
    enabledCallProviders: ["external", "mock", "agora"],
  });
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ callType: "videoCall", callProvider: "agora" }),
    auth: { uid: "student1", token: {} },
  });

  await assert.rejects(
    issueSessionRtcTokenForRequest(
      {
        data: withSessionEpoch({ sessionId: res.sessionId }),
        auth: { uid: "student1", token: {} },
      } as never,
      { db: db() },
    ),
    (error: unknown) => codeOf(error) === "join_window_closed",
  );
});

test("integration: join token rejected after cancellation", async () => {
  await prepareIntegrationFirestore();
  await patchPlatformConfig({
    enabledCallProviders: ["external", "mock", "agora"],
  });
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({
      callType: "videoCall",
      callProvider: "agora",
    }),
    auth: { uid: "student1", token: {} },
  });

  await cancelBooking.run({
    data: withSessionEpoch({
      bookingId: res.bookingId,
      reason: "No longer available",
      actorRole: "student",
    }),
    auth: { uid: "student1", token: {} },
  });

  const sessionAfterCancel = await db()
    .collection("quran_sessions")
    .doc(res.sessionId)
    .get();
  assert.equal(sessionAfterCancel.get("lifecycleStatus"), "cancelled_by_student");

  await assert.rejects(
    issueSessionRtcTokenForRequest(
      {
        data: withSessionEpoch({ sessionId: res.sessionId }),
        auth: { uid: "student1", token: {} },
      } as never,
      { db: db() },
    ),
    (error: unknown) => codeOf(error) === "invalid_transition",
  );
});

test("integration: fee snapshot persists and ignores later market price changes", async () => {
  await prepareIntegrationFirestore();
  await db()
    .collection("quran_session_market_configs")
    .doc("EG")
    .set({
      isEnabled: true,
      minSessionPrice: 0,
      currencyCode: "EGP",
      activePolicyVersion: "v1",
      cities: [{ cityId: "cairo", isEnabled: true, minSessionPrice: 0 }],
    });
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ pricingType: "free" }),
    auth: { uid: "student1", token: {} },
  });

  const before = await db().collection("quran_bookings").doc(res.bookingId).get();
  const snapshotBefore = before.get("feeSnapshot") as {
    amount: number;
    currencyCode: string;
    policyVersion: string | null;
  };
  assert.equal(snapshotBefore.amount, 0);
  assert.equal(snapshotBefore.currencyCode, "EGP");

  await db()
    .collection("quran_session_market_configs")
    .doc("EG")
    .set({
      isEnabled: true,
      minSessionPrice: 99,
      currencyCode: "EGP",
      activePolicyVersion: "v2",
      cities: [{ cityId: "cairo", isEnabled: true, minSessionPrice: 99 }],
    });

  const after = await db().collection("quran_bookings").doc(res.bookingId).get();
  const snapshotAfter = after.get("feeSnapshot") as { amount: number; policyVersion: string | null };
  assert.deepEqual(snapshotAfter, snapshotBefore);
});

test("integration: teacher not on whitelist is rejected", async () => {
  await prepareIntegrationFirestore();
  await db()
    .collection("quran_session_market_configs")
    .doc("EG")
    .set({
      isEnabled: true,
      minSessionPrice: 0,
      currencyCode: "EGP",
      teacherWhitelist: ["other_teacher"],
      cities: [{ cityId: "cairo", isEnabled: true }],
    });
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  await assert.rejects(
    booking.run({ data: bookingData(), auth: { uid: "student1", token: {} } }),
    (error: unknown) => codeOf(error) === "teacher_not_whitelisted",
  );
});

test("integration: child booking without guardian is rejected server-side", async () => {
  await prepareIntegrationFirestore();
  await seedVerifiedTeacher("teacher1", { canTeachChildren: true });
  await seedCompleteStudent("child1", {
    dateOfBirth: Timestamp.fromDate(new Date("2018-01-01T00:00:00Z")),
    guardianId: null,
  });
  await seedUserSession("child1");

  await assert.rejects(
    booking.run({
      data: bookingData(),
      auth: { uid: "child1", token: {} },
    }),
    (error: unknown) => codeOf(error) === "guardian_approval_required",
  );
});

test("integration: canceled booking is not in student upcoming query set", async () => {
  await prepareIntegrationFirestore();
  await seedVerifiedTeacher("teacher1");
  await seedCompleteStudent("student1");
  await seedUserSession("student1");

  const res = await booking.run({
    data: bookingData({ slotId: "slot-upcoming-filter" }),
    auth: { uid: "student1", token: {} },
  });

  await cancelBooking.run({
    data: withSessionEpoch({
      bookingId: res.bookingId,
      reason: "Schedule conflict",
      actorRole: "student",
    }),
    auth: { uid: "student1", token: {} },
  });

  const upcoming = await db()
    .collection("quran_bookings")
    .where("studentId", "==", "student1")
    .where("lifecycleStatus", "in", [
      "scheduled",
      "confirmed",
      "in_progress",
      "pending_tutor_approval",
      "pending_payment",
      "rescheduled",
    ])
    .get();

  assert.equal(upcoming.docs.some((doc) => doc.id === res.bookingId), false);
});
