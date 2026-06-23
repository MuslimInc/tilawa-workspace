import test from "node:test";
import assert from "node:assert/strict";

import {
  initialReportRecord,
  isValidReportCategory,
  isValidReportResolution,
  severityForCategory,
} from "../../src/quranSessions/reportTypes";

test("isValidReportCategory accepts known categories and rejects others", () => {
  assert.equal(isValidReportCategory("child_safety"), true);
  assert.equal(isValidReportCategory("other"), true);
  assert.equal(isValidReportCategory("nonsense"), false);
  assert.equal(isValidReportCategory(undefined), false);
});

test("severityForCategory escalates child-safety / abuse / safety", () => {
  assert.equal(severityForCategory("child_safety"), "high");
  assert.equal(severityForCategory("abuse_or_harassment"), "high");
  assert.equal(severityForCategory("safety_concern"), "high");
  assert.equal(severityForCategory("fraud_or_scam"), "normal");
  assert.equal(severityForCategory("other"), "normal");
});

test("isValidReportResolution accepts the three transitions only", () => {
  assert.equal(isValidReportResolution("under_review"), true);
  assert.equal(isValidReportResolution("resolved"), true);
  assert.equal(isValidReportResolution("dismissed"), true);
  assert.equal(isValidReportResolution("open"), false);
});

test("initialReportRecord opens the report and stamps severity", () => {
  const record = initialReportRecord({
    reportId: "r1",
    bookingId: "b1",
    sessionId: "s1",
    aggregateId: "b1",
    reportedUserId: "teacher1",
    reporterUserId: "student1",
    reporterRole: "student",
    category: "child_safety",
    description: "concern",
  });
  assert.equal(record.status, "open");
  assert.equal(record.severity, "high");
  assert.equal(record.reporterRole, "student");
  assert.equal(record.reportedUserId, "teacher1");
});
