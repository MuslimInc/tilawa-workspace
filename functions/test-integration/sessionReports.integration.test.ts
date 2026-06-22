import test from "node:test";
import assert from "node:assert/strict";

import {
  reportSessionConcern,
  resolveSessionReport,
} from "../src/quranSessions/sessionReportCallables";
import { clearFirestore, db } from "./support/emulator";

interface CallableLike<T> {
  run(req: {
    data: unknown;
    auth?: { uid: string; token?: Record<string, unknown> };
  }): Promise<T>;
}

const report = reportSessionConcern as unknown as CallableLike<{
  reportId: string;
  status: string;
}>;
const resolveReport = resolveSessionReport as unknown as CallableLike<{
  reportId: string;
  status: string;
}>;

async function seedBooking(): Promise<void> {
  await db().collection("quran_bookings").doc("booking1").set({
    bookingId: "booking1",
    aggregateId: "booking1",
    sessionId: "session1",
    studentId: "student1",
    teacherId: "teacher1",
  });
}

function codeOf(error: unknown): string | undefined {
  return (error as { details?: { code?: string } })?.details?.code;
}

test("integration: a participant can file a booking report (escalated severity)", async () => {
  await clearFirestore();
  await seedBooking();

  const res = await report.run({
    data: {
      bookingId: "booking1",
      category: "child_safety",
      description: "Inappropriate behaviour during the session.",
    },
    auth: { uid: "student1", token: {} },
  });

  assert.equal(res.status, "open");
  const doc = await db().collection("quran_session_reports").doc(res.reportId).get();
  assert.equal(doc.get("reporterRole"), "student");
  assert.equal(doc.get("reportedUserId"), "teacher1"); // counterparty
  assert.equal(doc.get("severity"), "high");
  assert.equal(doc.get("status"), "open");
});

test("integration: a non-participant cannot file a report on someone else's booking", async () => {
  await clearFirestore();
  await seedBooking();

  await assert.rejects(
    report.run({
      data: {
        bookingId: "booking1",
        category: "other",
        description: "not my booking",
      },
      auth: { uid: "stranger", token: {} },
    }),
    (e) => codeOf(e) === "not_participant",
  );
});

test("integration: a child's guardian can file a report on the child's booking", async () => {
  await clearFirestore();
  await seedBooking();
  await db()
    .collection("users")
    .doc("student1")
    .set({ quranSessionsProfile: { guardianId: "guardian1" } });

  const res = await report.run({
    data: {
      bookingId: "booking1",
      category: "safety_concern",
      description: "My child felt unsafe.",
    },
    auth: { uid: "guardian1", token: {} },
  });

  const doc = await db().collection("quran_session_reports").doc(res.reportId).get();
  assert.equal(doc.get("reporterRole"), "guardian");
});

test("integration: duplicate identical reports dedupe to a single record", async () => {
  await clearFirestore();
  await seedBooking();
  const payload = {
    data: {
      bookingId: "booking1",
      category: "abuse_or_harassment",
      description: "same text twice",
    },
    auth: { uid: "student1", token: {} },
  };

  const first = await report.run(payload);
  const second = await report.run(payload);

  assert.equal(first.reportId, second.reportId);
  const all = await db().collection("quran_session_reports").get();
  assert.equal(all.size, 1);
});

test("integration: admin can resolve a report; non-admin cannot", async () => {
  await clearFirestore();
  await seedBooking();
  const filed = await report.run({
    data: {
      bookingId: "booking1",
      category: "fraud_or_scam",
      description: "suspicious payment request",
    },
    auth: { uid: "student1", token: {} },
  });

  await assert.rejects(
    resolveReport.run({
      data: { reportId: filed.reportId, resolution: "dismissed", reason: "x" },
      auth: { uid: "student1", token: {} },
    }),
    (e) => codeOf(e) === "unauthorized_actor",
  );

  const resolved = await resolveReport.run({
    data: {
      reportId: filed.reportId,
      resolution: "resolved",
      reason: "Handled by trust & safety.",
    },
    auth: { uid: "admin1", token: { admin: true } },
  });
  assert.equal(resolved.status, "resolved");
  const doc = await db().collection("quran_session_reports").doc(filed.reportId).get();
  assert.equal(doc.get("status"), "resolved");
  assert.equal(doc.get("resolvedByUserId"), "admin1");
});
