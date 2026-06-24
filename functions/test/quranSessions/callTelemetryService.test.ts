import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

import {
  applyCallTelemetryEvent,
  CALL_TRACKING_LATE_GRACE_MINUTES,
  CALL_TRACKING_NO_SHOW_WINDOW_MINUTES,
  loadMutableTrackingState,
  toCallTrackingAggregate,
  type RecordCallTelemetryEventInput,
} from "../../src/quranSessions/callTelemetryService";

function scheduledAt(hour: number): Timestamp {
  return Timestamp.fromDate(new Date(`2026-06-24T${hour.toString().padStart(2, "0")}:00:00.000Z`));
}

test("teacher first join marks student on-time when within grace", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const onTimeMs = scheduledAt(12).toMillis() + 2 * 60 * 1000;

  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "e1",
      eventType: "joinSucceeded",
      actorId: "teacher",
      actorRole: "teacher",
      clientTimestampMs: onTimeMs,
    },
    onTimeMs,
  );

  assert.equal(state.firstJoinRole, "teacher");
  assert.equal(state.teacherLate, false);
});

test("student join after grace is late", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const lateMs =
    scheduledAt(12).toMillis() +
    (CALL_TRACKING_LATE_GRACE_MINUTES + 1) * 60 * 1000;

  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "e1",
      eventType: "joinSucceeded",
      actorId: "student",
      actorRole: "student",
      clientTimestampMs: lateMs,
    },
    lateMs,
  );

  assert.equal(state.studentLate, true);
});

test("actual call starts when both participants connected", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const teacherJoin = scheduledAt(12).toMillis();
  const studentJoin = teacherJoin + 30_000;

  const teacherEvent: RecordCallTelemetryEventInput = {
    sessionId: "s1",
    eventId: "teacher",
    eventType: "joinSucceeded",
    actorId: "teacher",
    actorRole: "teacher",
    clientTimestampMs: teacherJoin,
  };
  const studentEvent: RecordCallTelemetryEventInput = {
    sessionId: "s1",
    eventId: "student",
    eventType: "joinSucceeded",
    actorId: "student",
    actorRole: "student",
    clientTimestampMs: studentJoin,
  };

  applyCallTelemetryEvent(state, teacherEvent, teacherJoin);
  applyCallTelemetryEvent(state, studentEvent, studentJoin);

  assert.equal(state.firstJoinRole, "teacher");
  assert.equal(state.secondJoinRole, "student");
  assert.ok(state.actualCallStartedAt);
});

test("duration excludes wait before both connected", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const t0 = scheduledAt(12).toMillis();

  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "teacher",
      eventType: "joinSucceeded",
      actorId: "teacher",
      actorRole: "teacher",
      clientTimestampMs: t0,
    },
    t0,
  );

  const bothAt = t0 + 60_000;
  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "student",
      eventType: "joinSucceeded",
      actorId: "student",
      actorRole: "student",
      clientTimestampMs: bothAt,
    },
    bothAt,
  );

  const endedAt = bothAt + 120_000;
  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "leave",
      eventType: "leave",
      actorId: "teacher",
      actorRole: "teacher",
      clientTimestampMs: endedAt,
    },
    endedAt,
  );

  assert.equal(state.bothParticipantsConnectedSeconds, 120);
});

test("reconnect increments counter", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const now = scheduledAt(12).toMillis();

  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "r1",
      eventType: "reconnect",
      actorId: "student",
      actorRole: "student",
      clientTimestampMs: now,
    },
    now,
  );
  applyCallTelemetryEvent(
    state,
    {
      sessionId: "s1",
      eventId: "r2",
      eventType: "reconnect",
      actorId: "student",
      actorRole: "student",
      clientTimestampMs: now + 1000,
    },
    now + 1000,
  );

  assert.equal(state.reconnectCount, 2);
});

test("reconnect before the call starts is not an interruption", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const now = scheduledAt(12).toMillis();

  // Teacher alone, then reconnects before the student ever joins.
  applyCallTelemetryEvent(state, {
    sessionId: "s1", eventId: "j", eventType: "joinSucceeded",
    actorId: "teacher", actorRole: "teacher", clientTimestampMs: now,
  }, now);
  applyCallTelemetryEvent(state, {
    sessionId: "s1", eventId: "r", eventType: "reconnect",
    actorId: "teacher", actorRole: "teacher", clientTimestampMs: now + 1000,
  }, now + 1000);

  assert.equal(state.reconnectCount, 1);
  assert.equal(state.interruptionCount, 0);
});

test("reconnect after both connected counts as an interruption", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const t0 = scheduledAt(12).toMillis();

  applyCallTelemetryEvent(state, {
    sessionId: "s1", eventId: "t", eventType: "joinSucceeded",
    actorId: "teacher", actorRole: "teacher", clientTimestampMs: t0,
  }, t0);
  applyCallTelemetryEvent(state, {
    sessionId: "s1", eventId: "s", eventType: "joinSucceeded",
    actorId: "student", actorRole: "student", clientTimestampMs: t0,
  }, t0);
  applyCallTelemetryEvent(state, {
    sessionId: "s1", eventId: "r", eventType: "reconnect",
    actorId: "teacher", actorRole: "teacher", clientTimestampMs: t0 + 5000,
  }, t0 + 5000);

  assert.equal(state.interruptionCount, 1);
});

test("aggregate flags a never-joined participant as no-show after the window", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const t0 = scheduledAt(12).toMillis();

  // Only the teacher joins.
  applyCallTelemetryEvent(state, {
    sessionId: "s1", eventId: "t", eventType: "joinSucceeded",
    actorId: "teacher", actorRole: "teacher", clientTimestampMs: t0,
  }, t0);

  const afterWindowMs =
    t0 + (CALL_TRACKING_NO_SHOW_WINDOW_MINUTES + 1) * 60 * 1000;
  const aggregate = toCallTrackingAggregate("s1", state, afterWindowMs);

  assert.equal(aggregate.studentNoShow, true);
  assert.equal(aggregate.teacherNoShow, false);
  assert.equal(aggregate.noShowWindowMinutes, CALL_TRACKING_NO_SHOW_WINDOW_MINUTES);
});

test("no-show is pending (false) before the window expires", () => {
  const state = loadMutableTrackingState(undefined, scheduledAt(12));
  const t0 = scheduledAt(12).toMillis();
  const beforeWindowMs = t0 + 60 * 1000;

  const aggregate = toCallTrackingAggregate("s1", state, beforeWindowMs);

  assert.equal(aggregate.teacherNoShow, false);
  assert.equal(aggregate.studentNoShow, false);
});

test("interruptionCount survives a reload of persisted state", () => {
  const t0 = scheduledAt(12).toMillis();
  const persisted = {
    scheduledStartsAt: scheduledAt(12),
    firstJoinRole: "teacher",
    secondJoinRole: "student",
    interruptionCount: 2,
    reconnectCount: 3,
  } as Record<string, unknown>;

  const state = loadMutableTrackingState(persisted, scheduledAt(12));

  assert.equal(state.interruptionCount, 2);
  assert.equal(state.teacherEverConnected, true);
  assert.equal(state.studentEverConnected, true);
  // A reload must not re-flag a participant who already connected as no-show.
  const aggregate = toCallTrackingAggregate(
    "s1",
    state,
    t0 + 60 * 60 * 1000,
  );
  assert.equal(aggregate.teacherNoShow, false);
  assert.equal(aggregate.studentNoShow, false);
});
