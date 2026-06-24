import test from "node:test";
import assert from "node:assert/strict";
import {
  computeReminderWindow,
  DEFAULT_REMINDER_HOURS,
  reminderFieldKey,
  REMINDER_WINDOW_MINUTES,
} from "../../src/quranSessions/sessionReminders";
import { teacherUserIdFromDenormalizedSessionData } from "../../src/quranSessions/teacherProfileUserId";

test("DEFAULT_REMINDER_HOURS includes 24h and 1h", () => {
  assert.deepEqual(DEFAULT_REMINDER_HOURS, [24, 1]);
});

test("computeReminderWindow centers on target start time", () => {
  const now = new Date("2026-06-22T10:00:00.000Z");
  const window = computeReminderWindow(24, now, REMINDER_WINDOW_MINUTES);

  assert.equal(window.hoursBefore, 24);
  assert.equal(
    window.windowStart.toISOString(),
    "2026-06-23T09:30:00.000Z",
  );
  assert.equal(
    window.windowEnd.toISOString(),
    "2026-06-23T10:30:00.000Z",
  );
});

test("reminderFieldKey encodes hours", () => {
  assert.equal(reminderFieldKey(24), "reminder24hEnqueued");
  assert.equal(reminderFieldKey(1), "reminder1hEnqueued");
});

test("teacherUserIdFromDenormalizedSessionData reads denormalized field", () => {
  assert.equal(
    teacherUserIdFromDenormalizedSessionData({ teacherUserId: "uid_teacher" }),
    "uid_teacher",
  );
  assert.equal(
    teacherUserIdFromDenormalizedSessionData({ teacherId: "profile_1" }),
    undefined,
  );
  assert.equal(
    teacherUserIdFromDenormalizedSessionData({ teacherUserId: "  " }),
    undefined,
  );
});
