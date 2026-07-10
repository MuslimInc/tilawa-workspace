import test from "node:test";
import assert from "node:assert/strict";

import {
  reportSessionConcern,
  resolveSessionReport,
} from "../src/quranSessions/sessionReportCallables";
import {
  clearFirestore,
  db,
  seedUserSession,
  withSessionEpoch,
} from "./support/emulator";

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
  await seedUserSession("student1");
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
    data: withSessionEpoch({
      bookingId: "booking1",
      category: "child_safety",
      description: "Inappropriate behaviour during the session.",
    }),
    auth: { uid: "student1", token: {} },
  });

  assert.equal(res.status, "open");
  const doc = await db()
    .collection("quran_session_reports")
    .doc(res.reportId)
    .get();
  assert.equal(doc.get("reporterRole"), "student");
  assert.equal(doc.get("reportedUserId"), "teacher1"); // counterparty
  assert.equal(doc.get("severity"), "high");
  assert.equal(doc.get("status"), "open");
});

test("integration: a non-participant cannot file a report on someone else's booking", async () => {
  await clearFirestore();
  await seedBooking();
  await seedUserSession("stranger");

  await assert.rejects(
    report.run({
      data: withSessionEpoch({
        bookingId: "booking1",
        category: "other",
        description: "not my booking",
      }),
      auth: { uid: "stranger", token: {} },
    }),
    (e) => codeOf(e) === "not_participant",
  );
});

test("integration: duplicate identical reports dedupe to a single record", async () => {
  await clearFirestore();
  await seedBooking();
  const payload = {
    data: withSessionEpoch({
      bookingId: "booking1",
      category: "abuse_or_harassment",
      description: "same text twice",
    }),
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
    data: withSessionEpoch({
      bookingId: "booking1",
      category: "fraud_or_scam",
      description: "suspicious payment request",
    }),
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
  const doc = await db()
    .collection("quran_session_reports")
    .doc(filed.reportId)
    .get();
  assert.equal(doc.get("status"), "resolved");
  assert.equal(doc.get("resolvedByUserId"), "admin1");
});

test("integration: terminal report resolutions require a reason", async () => {
  await clearFirestore();
  await seedBooking();
  const filed = await report.run({
    data: withSessionEpoch({
      bookingId: "booking1",
      category: "other",
      description: "Requires review.",
    }),
    auth: { uid: "student1", token: {} },
  });

  await assert.rejects(
    resolveReport.run({
      data: { reportId: filed.reportId, resolution: "dismissed" },
      auth: { uid: "admin1", token: { admin: true } },
    }),
    (error) =>
      error instanceof Error &&
      error.message === "reason is required to resolve or dismiss a report.",
  );

  const doc = await db()
    .collection("quran_session_reports")
    .doc(filed.reportId)
    .get();
  assert.equal(doc.get("status"), "open");
});

test("integration: duplicate terminal resolution with one idempotency key writes one audit event", async () => {
  await clearFirestore();
  await seedBooking();
  const filed = await report.run({
    data: withSessionEpoch({
      bookingId: "booking1",
      category: "other",
      description: "Requires review.",
    }),
    auth: { uid: "student1", token: {} },
  });

  const payload = {
    data: {
      reportId: filed.reportId,
      resolution: "resolved",
      reason: "Handled by trust & safety.",
      idempotencyKey: "resolve-report-1",
    },
    auth: { uid: "admin1", token: { admin: true } },
  };

  const first = await resolveReport.run(payload);
  const second = await resolveReport.run(payload);

  assert.equal(first.status, "resolved");
  assert.equal(second.status, "resolved");
  const audit = await db()
    .collection("quran_session_events")
    .where("reportId", "==", filed.reportId)
    .where("action", "==", "resolve_report")
    .get();
  assert.equal(audit.size, 1);
});

test("integration: admin can triage then close a report with audit metadata", async () => {
  await clearFirestore();
  await seedBooking();
  const filed = await report.run({
    data: withSessionEpoch({
      bookingId: "booking1",
      category: "other",
      description: "Requires review.",
    }),
    auth: { uid: "student1", token: {} },
  });

  await resolveReport.run({
    data: { reportId: filed.reportId, resolution: "under_review" },
    auth: { uid: "admin1", token: { admin: true } },
  });
  const closed = await resolveReport.run({
    data: {
      reportId: filed.reportId,
      resolution: "dismissed",
      reason: "Insufficient evidence.",
    },
    auth: { uid: "admin1", token: { admin: true } },
  });

  assert.equal(closed.status, "dismissed");
  const doc = await db()
    .collection("quran_session_reports")
    .doc(filed.reportId)
    .get();
  assert.equal(doc.get("resolutionReason"), "Insufficient evidence.");
  assert.equal(doc.get("resolvedByUserId"), "admin1");
  assert.ok(doc.get("resolvedAt"));

  const audit = await db()
    .collection("quran_session_events")
    .where("reportId", "==", filed.reportId)
    .where("resolution", "==", "dismissed")
    .get();
  assert.equal(audit.size, 1);
});
