import test from "node:test";
import assert from "node:assert/strict";
import {
  buildNotificationCopy,
  buildSessionNotificationDoc,
  computeRetryBackoffMs,
  MAX_NOTIFICATION_RETRIES,
} from "../../src/quranSessions/notificationOutboxService";

test("buildSessionNotificationDoc maps outbox fields", () => {
  const doc = buildSessionNotificationDoc("notif-1", {
    sessionId: "session-1",
    aggregateId: "booking-1",
    kind: "bookingConfirmed",
    recipientUserIds: ["teacher-1", "student-1"],
    payload: { source: "cf" },
  });

  assert.equal(doc.notificationId, "notif-1");
  assert.equal(doc.sessionId, "session-1");
  assert.equal(doc.aggregateId, "booking-1");
  assert.equal(doc.kind, "bookingConfirmed");
  assert.deepEqual(doc.recipientUserIds, ["teacher-1", "student-1"]);
  assert.deepEqual(doc.deliveryStatus, { push: "pending", email: "pending" });
  assert.equal(doc.retryCount, 0);
  assert.deepEqual(doc.channels, ["push", "email"]);
});

test("buildNotificationCopy includes cancellation reason", () => {
  const copy = buildNotificationCopy("cancellation", {
    reason: "Teacher unavailable",
  });
  assert.match(copy.body, /Teacher unavailable/);
  assert.equal(copy.actionType, "quran_session_cancelled");
});

test("buildNotificationCopy formats reminder hours", () => {
  const copy = buildNotificationCopy("reminder", { hoursBefore: 1 });
  assert.match(copy.body, /1 hour\./);
});

test("computeRetryBackoffMs uses exponential backoff", () => {
  assert.equal(computeRetryBackoffMs(1), 60_000);
  assert.equal(computeRetryBackoffMs(2), 120_000);
  assert.equal(computeRetryBackoffMs(3), 240_000);
});

test("MAX_NOTIFICATION_RETRIES is 3", () => {
  assert.equal(MAX_NOTIFICATION_RETRIES, 3);
});
