import assert from "node:assert/strict";
import test from "node:test";

import {
  DEFAULT_DASHBOARD_HORIZON_DAYS,
  MAX_DASHBOARD_SESSION_ENTRIES,
  buildOverridesSection,
  buildSessionsSection,
  buildTeacherSection,
  overrideDateKey,
  overrideWindow,
  projectSessionEntry,
  resolveHorizonDays,
  resolveSchedulingConfigSection,
} from "../../src/quranSessions/dashboardProjection/dashboardSummaryService";

function sessionDoc(id: string, overrides: Record<string, unknown> = {}) {
  return {
    id,
    data: {
      teacherId: "teacher_1",
      studentId: "student_1",
      startsAt: "2026-07-10T10:00:00.000Z",
      endsAt: "2026-07-10T10:30:00.000Z",
      status: "scheduled",
      lifecycleStatus: "scheduled",
      bookingId: `booking_${id}`,
      joinToken: "secret-token",
      ...overrides,
    },
  };
}

test("projectSessionEntry copies dashboard fields and never joinToken", () => {
  const entry = projectSessionEntry(
    sessionDoc("s1", { meetingLink: "https://meet", participants: ["a"] }),
  );

  assert.equal(entry.id, "s1");
  assert.equal(entry.bookingId, "booking_s1");
  assert.equal(entry.teacherId, "teacher_1");
  assert.equal(entry.lifecycleStatus, "scheduled");
  assert.equal(entry.meetingLink, "https://meet");
  assert.deepEqual(entry.participants, ["a"]);
  assert.equal("joinToken" in entry, false);
});

test("projectSessionEntry omits absent optional fields instead of writing undefined", () => {
  const entry = projectSessionEntry(sessionDoc("s1"));

  assert.equal("meetingLink" in entry, false);
  assert.equal("notes" in entry, false);
});

test("buildSessionsSection under the cap is not truncated", () => {
  const section = buildSessionsSection([sessionDoc("a"), sessionDoc("b")]);

  assert.equal(section.sessions.length, 2);
  assert.equal(section.sessionsTruncated, false);
});

test("buildSessionsSection detects truncation via the +1 probe row", () => {
  const docs = Array.from({ length: MAX_DASHBOARD_SESSION_ENTRIES + 1 }, (_, i) =>
    sessionDoc(`s${i}`),
  );

  const section = buildSessionsSection(docs);

  assert.equal(section.sessions.length, MAX_DASHBOARD_SESSION_ENTRIES);
  assert.equal(section.sessionsTruncated, true);
});

test("buildOverridesSection mirrors the app's override decode defaults", () => {
  const section = buildOverridesSection([
    { id: "2026-07-11", data: { type: "custom_hours", intervals: [{ s: 1 }], date: "2026-07-11", reason: "eid" } },
    { id: "2026-07-12", data: {} },
  ]);

  assert.deepEqual(section[0], {
    date: "2026-07-11",
    type: "custom_hours",
    intervals: [{ s: 1 }],
    reason: "eid",
  });
  // Missing fields fall back exactly like getOverrides: doc id, unavailable, [].
  assert.deepEqual(section[1], {
    date: "2026-07-12",
    type: "unavailable",
    intervals: [],
  });
});

test("resolveSchedulingConfigSection prefers market over global over defaults", () => {
  const market = resolveSchedulingConfigSection(
    { bookingHorizonDays: 7 },
    { bookingHorizonDays: 21 },
  );
  assert.equal(market.source, "market");
  assert.equal(market.config.bookingHorizonDays, 7);
  // Unset keys are backfilled with the Dart DTO defaults.
  assert.equal(market.config.schedulingMode, "recurring");

  const global = resolveSchedulingConfigSection(null, { bookingHorizonDays: 21 });
  assert.equal(global.source, "global");
  assert.equal(global.config.bookingHorizonDays, 21);

  const defaults = resolveSchedulingConfigSection(null, {});
  assert.equal(defaults.source, "defaults");
  assert.equal(defaults.config.bookingHorizonDays, 30);
});

test("resolveHorizonDays caps at the dashboard horizon and survives bad input", () => {
  assert.equal(resolveHorizonDays({ bookingHorizonDays: 30 }), DEFAULT_DASHBOARD_HORIZON_DAYS);
  assert.equal(resolveHorizonDays({ bookingHorizonDays: 7 }), 7);
  assert.equal(resolveHorizonDays({}), DEFAULT_DASHBOARD_HORIZON_DAYS);
  assert.equal(resolveHorizonDays({ bookingHorizonDays: -3 }), DEFAULT_DASHBOARD_HORIZON_DAYS);
  assert.equal(
    resolveHorizonDays({ bookingHorizonDays: "x" }),
    DEFAULT_DASHBOARD_HORIZON_DAYS,
  );
});

test("overrideWindow pads one day each side in date keys", () => {
  const now = new Date("2026-07-04T23:30:00.000Z");

  const window = overrideWindow(now, 14);

  assert.equal(window.fromKey, "2026-07-03");
  // now + (14 + 2) days, exclusive upper bound.
  assert.equal(window.toKeyExclusive, "2026-07-20");
});

test("overrideDateKey zero-pads month and day", () => {
  assert.equal(overrideDateKey(new Date("2026-01-05T00:00:00.000Z")), "2026-01-05");
});

test("buildTeacherSection tolerates missing profile fields", () => {
  const section = buildTeacherSection({}, null);

  assert.deepEqual(section, { userId: "", displayName: null, countryCode: null });
});
