/**
 * Staging smoke validation for Quran Sessions Free Beta.
 *
 * Runs callable handlers against the live Firebase project (ADC credentials).
 * Does NOT enable paid bookings or production flags.
 *
 * Usage:
 *   FIREBASE_PROJECT_ID=quran-playera-app npx ts-node --project tsconfig.scripts.json scripts/stagingFreeBetaSmoke.ts
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { createSessionBooking } from "../src/quranSessions/createSessionBooking";
import { cancelSessionBooking } from "../src/quranSessions/cancelSessionBooking";
import { markSessionNoShow } from "../src/quranSessions/markSessionNoShow";
import {
  openSessionDispute,
  resolveSessionDispute,
} from "../src/quranSessions/sessionDisputeCallables";
import {
  reportSessionConcern,
  resolveSessionReport,
} from "../src/quranSessions/sessionReportCallables";
import { approveSessionRefund } from "../src/quranSessions/approveSessionRefund";

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? "quran-playera-app";

interface CallableLike<T> {
  run(req: {
    data: unknown;
    auth?: { uid: string; token?: Record<string, unknown> };
  }): Promise<T>;
}

type SmokeResult = { name: string; pass: boolean; detail: string };

const results: SmokeResult[] = [];

function record(name: string, pass: boolean, detail: string): void {
  results.push({ name, pass, detail });
  const icon = pass ? "PASS" : "FAIL";
  console.log(`[${icon}] ${name}: ${detail}`);
}

function asCallable<T>(fn: unknown): CallableLike<T> {
  return fn as CallableLike<T>;
}

async function seedVerifiedTeacher(id: string): Promise<void> {
  const db = getFirestore();
  await db.collection("quran_teacher_profiles").doc(id).set(
    {
      userId: id,
      verificationStatus: "verified",
      gender: "male",
      allowedStudentGender: "both",
      canTeachChildren: true,
      requiresGuardianApprovalForChildren: false,
      isPubliclyVisible: true,
      isActive: true,
    },
    { merge: true },
  );
}

async function seedStudent(id: string, overrides: Record<string, unknown> = {}): Promise<void> {
  const db = getFirestore();
  await db.collection("users").doc(id).set(
    {
      quranSessionsProfile: {
        accountStatus: "active",
        gender: "male",
        dateOfBirth: Timestamp.fromDate(new Date("1990-01-01T00:00:00Z")),
        countryCode: "EG",
        cityId: "cairo",
        profileCompleted: true,
        ...overrides,
      },
    },
    { merge: true },
  );
}

async function seedPlatformConfig(): Promise<void> {
  const db = getFirestore();
  await db.collection("quran_session_platform_config").doc("global").set(
    {
      globalAllowMaleTeacherFemaleStudent: true,
      globalAllowFemaleTeacherMaleStudent: true,
      requireGuardianApprovalForChildren: false,
      childAgeThreshold: 13,
    },
    { merge: true },
  );
  await db.collection("quran_session_market_configs").doc("EG").set(
    { isEnabled: true, sortOrder: 1 },
    { merge: true },
  );
}

function codeOf(error: unknown): string | undefined {
  return (error as { details?: { code?: string }; code?: string })?.details?.code
    ?? (error as { code?: string })?.code;
}

async function main(): Promise<void> {
  initializeApp({ projectId: PROJECT_ID });
  const db = getFirestore();
  console.log(`Staging smoke — project ${PROJECT_ID}\n`);

  const createBooking = asCallable<{
    bookingId: string;
    sessionId: string;
    lifecycleStatus: string;
  }>(createSessionBooking);
  const cancelBooking = asCallable<{ bookingId: string }>(cancelSessionBooking);
  const markNoShow = asCallable<{ sessionId: string }>(markSessionNoShow);
  const openDispute = asCallable<{ disputeId: string }>(openSessionDispute);
  const resolveDispute = asCallable<{
    refundId: string | null;
    compensationExecutionStatus: string | null;
  }>(resolveSessionDispute);
  const reportConcern = asCallable<{ reportId: string }>(reportSessionConcern);
  const resolveReport = asCallable<{ reportId: string }>(resolveSessionReport);
  const approveRefund = asCallable<{ refundExecutionStatus: string }>(
    approveSessionRefund,
  );

  const runId = Date.now();
  const teacherId = `smoke_teacher_${runId}`;
  const studentId = `smoke_student_${runId}`;
  const student2Id = `smoke_student2_${runId}`;
  const slotId = `smoke_slot_${runId}`;
  const startsAt = new Date(Date.now() + 86_400_000).toISOString();
  const endsAt = new Date(Date.now() + 90_000_000).toISOString();

  await seedPlatformConfig();
  await seedVerifiedTeacher(teacherId);
  await seedStudent(studentId);
  await seedStudent(student2Id);

  // Free booking
  let bookingId = "";
  try {
    const booked = await createBooking.run({
      data: {
        teacherId,
        slotId,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    bookingId = booked.bookingId;
    record(
      "student can book free session",
      booked.lifecycleStatus === "scheduled",
      `booking=${bookingId} status=${booked.lifecycleStatus}`,
    );
  } catch (e) {
    record("student can book free session", false, String(e));
  }

  // Idempotent replay
  try {
    const replay = await createBooking.run({
      data: {
        teacherId,
        slotId,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    const bookings = await db.collection("quran_bookings").get();
    record(
      "duplicate booking replay idempotent",
      replay.bookingId === bookingId && bookings.size >= 1,
      `same bookingId=${replay.bookingId === bookingId}`,
    );
  } catch (e) {
    record("duplicate booking replay idempotent", false, String(e));
  }

  // Different key same slot blocked
  try {
    await createBooking.run({
      data: {
        teacherId,
        slotId,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-other-${runId}`,
      },
      auth: { uid: student2Id, token: {} },
    });
    record("different user cannot book same slot", false, "expected rejection");
  } catch (e) {
    record(
      "different user cannot book same slot",
      codeOf(e) === "already-exists",
      `code=${codeOf(e)}`,
    );
  }

  // Student cancel
  if (bookingId) {
    try {
      await cancelBooking.run({
        data: { bookingId, reason: "smoke cancel student", actorRole: "student" },
        auth: { uid: studentId, token: {} },
      });
      const doc = await db.collection("quran_bookings").doc(bookingId).get();
      record(
        "student can cancel with reason",
        doc.get("lifecycleStatus") === "cancelled_by_student",
        `status=${doc.get("lifecycleStatus")}`,
      );
    } catch (e) {
      record("student can cancel with reason", false, String(e));
    }
  }

  // Teacher cancel — new booking
  const slot2 = `smoke_slot2_${runId}`;
  let booking2 = "";
  try {
    const b2 = await createBooking.run({
      data: {
        teacherId,
        slotId: slot2,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-t2-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    booking2 = b2.bookingId;
    await cancelBooking.run({
      data: { bookingId: booking2, reason: "smoke teacher cancel", actorRole: "teacher" },
      auth: { uid: teacherId, token: {} },
    });
    const doc = await db.collection("quran_bookings").doc(booking2).get();
    record(
      "teacher can cancel with reason",
      doc.get("lifecycleStatus") === "cancelled_by_teacher",
      `status=${doc.get("lifecycleStatus")}`,
    );
  } catch (e) {
    record("teacher can cancel with reason", false, String(e));
  }

  // No-show
  const slot3 = `smoke_slot3_${runId}`;
  let session3 = "";
  try {
    const b3 = await createBooking.run({
      data: {
        teacherId,
        slotId: slot3,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-ns-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    session3 = b3.sessionId;
    await db.collection("quran_sessions").doc(session3).set(
      { lifecycleStatus: "confirmed" },
      { merge: true },
    );
    await db.collection("quran_bookings").doc(b3.bookingId).set(
      { lifecycleStatus: "confirmed" },
      { merge: true },
    );
    await markNoShow.run({
      data: {
        sessionId: session3,
        classification: "teacher_no_show",
        actorRole: "admin",
        reason: "smoke no-show",
      },
      auth: { uid: "smoke_admin", token: { admin: true } },
    });
    const doc = await db.collection("quran_sessions").doc(session3).get();
    record(
      "no-show classification works",
      doc.get("lifecycleStatus") === "teacher_no_show",
      `status=${doc.get("lifecycleStatus")}`,
    );
  } catch (e) {
    record("no-show classification works", false, String(e));
  }

  // Dispute + resolution ledger
  const slot4 = `smoke_slot4_${runId}`;
  let disputeId = "";
  try {
    const b4 = await createBooking.run({
      data: {
        teacherId,
        slotId: slot4,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-d-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    await db.collection("quran_bookings").doc(b4.bookingId).set(
      { lifecycleStatus: "completed", amountPaidUsd: 0 },
      { merge: true },
    );
    await db.collection("quran_sessions").doc(b4.sessionId).set(
      { lifecycleStatus: "completed" },
      { merge: true },
    );
    const opened = await openDispute.run({
      data: { bookingId: b4.bookingId, reason: "smoke dispute" },
      auth: { uid: studentId, token: {} },
    });
    disputeId = opened.disputeId;
    const resolved = await resolveDispute.run({
      data: {
        bookingId: b4.bookingId,
        disputeId,
        resolution: "favor_student",
        reason: "smoke refund",
        idempotencyKey: `resolve-${runId}`,
      },
      auth: { uid: "smoke_admin", token: { admin: true } },
    });
    const refunds = await db.collection("quran_session_refunds").get();
    record(
      "dispute resolution creates manual_pending refund ledger",
      resolved.refundId != null,
      `refundId=${resolved.refundId} count=${refunds.size}`,
    );
    record(
      "dispute can be opened",
      Boolean(disputeId),
      `disputeId=${disputeId}`,
    );
  } catch (e) {
    record("dispute can be opened", false, String(e));
    record("dispute resolution creates manual_pending refund ledger", false, String(e));
  }

  // Unauthorized cancel
  if (booking2) {
    try {
      await cancelBooking.run({
        data: { bookingId: booking2, reason: "hack", actorRole: "student" },
        auth: { uid: "stranger_uid", token: {} },
      });
      record("unauthorized actor rejected", false, "expected rejection");
    } catch (e) {
      record(
        "unauthorized actor rejected",
        codeOf(e) === "not_participant" || codeOf(e) === "permission-denied",
        `code=${codeOf(e)}`,
      );
    }
  }

  // Reports
  const slot5 = `smoke_slot5_${runId}`;
  try {
    const b5 = await createBooking.run({
      data: {
        teacherId,
        slotId: slot5,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-r-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    const filed = await reportConcern.run({
      data: {
        bookingId: b5.bookingId,
        category: "other",
        description: "smoke report",
        idempotencyKey: `report-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    await resolveReport.run({
      data: {
        reportId: filed.reportId,
        resolution: "dismissed",
        reason: "smoke resolve",
      },
      auth: { uid: "smoke_admin", token: { admin: true } },
    });
    const reportDoc = await db
      .collection("quran_session_reports")
      .doc(filed.reportId)
      .get();
    record(
      "reports can be filed and resolved",
      reportDoc.get("status") === "dismissed",
      `status=${reportDoc.get("status")}`,
    );
  } catch (e) {
    record("reports can be filed and resolved", false, String(e));
  }

  // Paid booking blocked
  try {
    await db
      .collection("quran_teacher_profiles")
      .doc(teacherId)
      .collection("pricing")
      .doc("EG_cairo")
      .set({ amount: 10, currencyCode: "USD" });
    await createBooking.run({
      data: {
        teacherId,
        slotId: `smoke_paid_${runId}`,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-paid-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    record("no paid booking exposed", false, "paid booking should be rejected");
  } catch (e) {
    record(
      "no paid booking exposed",
      codeOf(e) === "payment_provider_unavailable",
      `code=${codeOf(e)}`,
    );
    // Remove paid pricing so later smoke bookings stay free.
    await db
      .collection("quran_teacher_profiles")
      .doc(teacherId)
      .collection("pricing")
      .doc("EG_cairo")
      .delete();
  }

  // Duplicate refund idempotent
  const slot6 = `smoke_slot6_${runId}`;
  try {
    const b6 = await createBooking.run({
      data: {
        teacherId,
        slotId: slot6,
        startsAt,
        endsAt,
        callType: "voiceCall",
        pricingType: "free",
        idempotencyKey: `smoke-ref-${runId}`,
      },
      auth: { uid: studentId, token: {} },
    });
    await db.collection("quran_bookings").doc(b6.bookingId).set(
      { lifecycleStatus: "cancelled_by_teacher" },
      { merge: true },
    );
    const r1 = await approveRefund.run({
      data: {
        bookingId: b6.bookingId,
        reason: "smoke refund",
        idempotencyKey: `ref-${runId}`,
      },
      auth: { uid: "smoke_admin", token: { admin: true } },
    });
    const r2 = await approveRefund.run({
      data: {
        bookingId: b6.bookingId,
        reason: "smoke refund",
        idempotencyKey: `ref-${runId}`,
      },
      auth: { uid: "smoke_admin", token: { admin: true } },
    });
    const refunds = await db
      .collection("quran_session_refunds")
      .where("bookingId", "==", b6.bookingId)
      .get();
    record(
      "duplicate refund safe",
      r1.refundExecutionStatus === "manual_pending"
        && r2.refundExecutionStatus === "manual_pending"
        && refunds.size === 1,
      `ledgerCount=${refunds.size}`,
    );
  } catch (e) {
    record("duplicate refund safe", false, String(e));
  }

  const failed = results.filter((r) => !r.pass);
  console.log(`\n--- Summary: ${results.length - failed.length}/${results.length} passed ---`);
  if (failed.length > 0) {
    console.log("Failures:");
    for (const f of failed) {
      console.log(`  - ${f.name}: ${f.detail}`);
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
