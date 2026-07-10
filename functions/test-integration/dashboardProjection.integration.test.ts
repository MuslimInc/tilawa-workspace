import test from "node:test";
import assert from "node:assert/strict";

import { Timestamp } from "firebase-admin/firestore";

import {
  pruneStaleDashboardSummaries,
  rebuildSummarySections,
  summaryRef,
} from "../src/quranSessions/dashboardProjection/projectTeacherDashboard";
import {
  DASHBOARD_SUMMARY_DOC_TYPE,
  MAX_DASHBOARD_SESSION_ENTRIES,
} from "../src/quranSessions/dashboardProjection/dashboardSummaryService";
import { clearFirestore, db } from "./support/emulator";

const TEACHER = "teacher_profile_1";
const NOW = new Date("2026-07-04T12:00:00.000Z");

async function seedTeacher(firestore: FirebaseFirestore.Firestore) {
  await firestore.collection("quran_teacher_profiles").doc(TEACHER).set({
    userId: "uid_1",
    displayName: "Ustadh Test",
  });
  await firestore.collection("users").doc("uid_1").set({
    quranSessionsProfile: { countryCode: "EG" },
  });
  await firestore
    .collection("quran_session_market_configs")
    .doc("EG")
    .set({ scheduling: { bookingHorizonDays: 7, weekStartDay: "sat" } });
  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER)
    .collection("availability_config")
    .doc("schedule")
    .set({ teacherId: TEACHER, timezone: "Africa/Cairo", weeklyRules: [] });
}

test("integration: full rebuild materializes every summary section", async () => {
  await clearFirestore();
  const firestore = db();
  await seedTeacher(firestore);

  await firestore.collection("quran_sessions").doc("s1").set({
    teacherId: TEACHER,
    studentId: "student_1",
    startsAt: Timestamp.fromDate(new Date("2026-07-05T10:00:00.000Z")),
    endsAt: Timestamp.fromDate(new Date("2026-07-05T10:30:00.000Z")),
    status: "scheduled",
    lifecycleStatus: "scheduled",
    joinToken: "secret",
  });
  // Ended session — excluded by the endsAt >= now window.
  await firestore.collection("quran_sessions").doc("s0").set({
    teacherId: TEACHER,
    studentId: "student_1",
    startsAt: Timestamp.fromDate(new Date("2026-07-01T10:00:00.000Z")),
    endsAt: Timestamp.fromDate(new Date("2026-07-01T10:30:00.000Z")),
    status: "completed",
  });
  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER)
    .collection("availability_overrides")
    .doc("2026-07-06")
    .set({ date: "2026-07-06", type: "unavailable" });
  // Outside the 7-day horizon window — must not be embedded.
  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER)
    .collection("availability_overrides")
    .doc("2026-08-01")
    .set({ date: "2026-08-01", type: "unavailable" });

  const existed = await rebuildSummarySections(
    firestore,
    TEACHER,
    new Set(["teacherAndConfig", "sessions", "weeklySchedule", "overrides"]),
    NOW,
  );
  assert.equal(existed, true);

  const summary = (await summaryRef(firestore, TEACHER).get()).data()!;
  assert.equal(summary.docType, DASHBOARD_SUMMARY_DOC_TYPE);
  assert.equal(summary.teacherProfileId, TEACHER);
  assert.equal(summary.revision, 1);
  assert.deepEqual(summary.teacher, {
    userId: "uid_1",
    displayName: "Ustadh Test",
    countryCode: "EG",
  });
  assert.equal(summary.schedulingConfigSource, "market");
  assert.equal(summary.schedulingConfig.bookingHorizonDays, 7);
  assert.equal(summary.horizonDays, 7);
  assert.equal(summary.weeklySchedule.timezone, "Africa/Cairo");
  assert.equal(summary.sessions.length, 1);
  assert.equal(summary.sessions[0].id, "s1");
  assert.equal("joinToken" in summary.sessions[0], false);
  assert.equal(summary.sessionsTruncated, false);
  assert.deepEqual(
    summary.overrides.map((o: { date: string }) => o.date),
    ["2026-07-06"],
  );
});

test("integration: repeated rebuilds converge (same content, bumped revision)", async () => {
  const firestore = db();

  await rebuildSummarySections(firestore, TEACHER, new Set(["sessions"]), NOW);
  const first = (await summaryRef(firestore, TEACHER).get()).data()!;
  await rebuildSummarySections(firestore, TEACHER, new Set(["sessions"]), NOW);
  const second = (await summaryRef(firestore, TEACHER).get()).data()!;

  assert.deepEqual(second.sessions, first.sessions);
  assert.equal(second.revision, first.revision + 1);
});

test("integration: section rebuild leaves other sections untouched", async () => {
  const firestore = db();

  await firestore
    .collection("quran_teacher_profiles")
    .doc(TEACHER)
    .collection("availability_overrides")
    .doc("2026-07-07")
    .set({ date: "2026-07-07", type: "unavailable", reason: "trip" });

  await rebuildSummarySections(firestore, TEACHER, new Set(["overrides"]), NOW);

  const summary = (await summaryRef(firestore, TEACHER).get()).data()!;
  // Overrides window used the stored horizonDays (7), not the default 14.
  assert.deepEqual(
    summary.overrides.map((o: { date: string }) => o.date).sort(),
    ["2026-07-06", "2026-07-07"],
  );
  assert.equal(summary.sessions.length, 1);
  assert.equal(summary.weeklySchedule.timezone, "Africa/Cairo");
});

test("integration: sessions beyond the cap set sessionsTruncated", async () => {
  await clearFirestore();
  const firestore = db();
  await seedTeacher(firestore);

  const batchLimit = 500;
  let batch = firestore.batch();
  let inBatch = 0;
  for (let i = 0; i < MAX_DASHBOARD_SESSION_ENTRIES + 1; i++) {
    const start = new Date(NOW.getTime() + (i + 1) * 60_000);
    batch.set(firestore.collection("quran_sessions").doc(`bulk_${i}`), {
      teacherId: TEACHER,
      studentId: "student_1",
      startsAt: Timestamp.fromDate(start),
      endsAt: Timestamp.fromDate(new Date(start.getTime() + 30 * 60_000)),
      status: "scheduled",
    });
    if (++inBatch === batchLimit) {
      await batch.commit();
      batch = firestore.batch();
      inBatch = 0;
    }
  }
  if (inBatch > 0) await batch.commit();

  await rebuildSummarySections(firestore, TEACHER, new Set(["sessions"]), NOW);

  const summary = (await summaryRef(firestore, TEACHER).get()).data()!;
  assert.equal(summary.sessions.length, MAX_DASHBOARD_SESSION_ENTRIES);
  assert.equal(summary.sessionsTruncated, true);
});

test("integration: rebuild for a missing teacher profile deletes the summary", async () => {
  await clearFirestore();
  const firestore = db();
  await summaryRef(firestore, "ghost_teacher").set({
    docType: DASHBOARD_SUMMARY_DOC_TYPE,
    teacherProfileId: "ghost_teacher",
  });

  const existed = await rebuildSummarySections(
    firestore,
    "ghost_teacher",
    new Set(["teacherAndConfig"]),
    NOW,
  );

  assert.equal(existed, false);
  assert.equal((await summaryRef(firestore, "ghost_teacher").get()).exists, false);
});

test("integration: prune refreshes only stale summaries", async () => {
  await clearFirestore();
  const firestore = db();
  await seedTeacher(firestore);

  await summaryRef(firestore, TEACHER).set({
    docType: DASHBOARD_SUMMARY_DOC_TYPE,
    teacherProfileId: TEACHER,
    horizonDays: 7,
    revision: 5,
    // Two days stale — eligible for prune.
    updatedAt: Timestamp.fromDate(new Date(NOW.getTime() - 48 * 3600_000)),
  });

  const refreshed = await pruneStaleDashboardSummaries(firestore, NOW);
  assert.equal(refreshed, 1);

  const summary = (await summaryRef(firestore, TEACHER).get()).data()!;
  assert.equal(summary.revision, 6);
  assert.ok(Array.isArray(summary.sessions));
  assert.ok(Array.isArray(summary.overrides));

  // Freshly written summary is no longer stale — second prune is a no-op.
  const second = await pruneStaleDashboardSummaries(firestore, NOW);
  assert.equal(second, 0);
});
