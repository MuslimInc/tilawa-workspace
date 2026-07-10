import test from "node:test";
import assert from "node:assert/strict";

import {
  MAESTRO_STUDENT_UID,
  MAESTRO_TEACHER_UID,
} from "../../src/quranSessions/maestroStagingAccounts";
import {
  isQaJoinWindowBypassEligible,
  isStagingEnvironmentForQaJoinWindowBypass,
  STAGING_QA_JOIN_WINDOW_BYPASS_UIDS,
} from "../../src/quranSessions/stagingQaJoinWindowBypass";
import {
  isWithinJoinWindow,
  isWithinJoinWindowOrQaBypass,
} from "../../src/quranSessions/sessionJoinWindowPolicy";

function withEnv(
  values: Record<string, string | undefined>,
  fn: () => void,
): void {
  const previous: Record<string, string | undefined> = {};
  for (const key of Object.keys(values)) {
    previous[key] = process.env[key];
    const next = values[key];
    if (next == null) {
      delete process.env[key];
    } else {
      process.env[key] = next;
    }
  }
  try {
    fn();
  } finally {
    for (const key of Object.keys(values)) {
      const prev = previous[key];
      if (prev == null) {
        delete process.env[key];
      } else {
        process.env[key] = prev;
      }
    }
  }
}

test("STAGING_QA_JOIN_WINDOW_BYPASS_UIDS contains Maestro teacher and student", () => {
  assert.ok(STAGING_QA_JOIN_WINDOW_BYPASS_UIDS.has(MAESTRO_TEACHER_UID));
  assert.ok(STAGING_QA_JOIN_WINDOW_BYPASS_UIDS.has(MAESTRO_STUDENT_UID));
  assert.equal(STAGING_QA_JOIN_WINDOW_BYPASS_UIDS.size, 2);
});

test("isStagingEnvironmentForQaJoinWindowBypass is true for staging distribution", () => {
  withEnv({ TILAWA_DISTRIBUTION: "staging" }, () => {
    assert.equal(isStagingEnvironmentForQaJoinWindowBypass(), true);
  });
});

test("isStagingEnvironmentForQaJoinWindowBypass rejects play_production", () => {
  withEnv({ TILAWA_DISTRIBUTION: "play_production" }, () => {
    assert.equal(isStagingEnvironmentForQaJoinWindowBypass(), false);
  });
});

test("isQaJoinWindowBypassEligible allows Maestro uids on staging", () => {
  withEnv({ TILAWA_DISTRIBUTION: "staging" }, () => {
    assert.equal(isQaJoinWindowBypassEligible(MAESTRO_TEACHER_UID), true);
    assert.equal(isQaJoinWindowBypassEligible(MAESTRO_STUDENT_UID), true);
  });
});

test("isQaJoinWindowBypassEligible rejects non-QA uid on staging", () => {
  withEnv({ TILAWA_DISTRIBUTION: "staging" }, () => {
    assert.equal(isQaJoinWindowBypassEligible("random_user_1"), false);
  });
});

test("isQaJoinWindowBypassEligible rejects QA uid on play_production", () => {
  withEnv({ TILAWA_DISTRIBUTION: "play_production" }, () => {
    assert.equal(isQaJoinWindowBypassEligible(MAESTRO_STUDENT_UID), false);
  });
});

test("isWithinJoinWindowOrQaBypass skips window for QA uid on staging", () => {
  const startsAt = new Date("2099-06-01T12:00:00.000Z");
  const endsAt = new Date("2099-06-01T13:00:00.000Z");
  const now = new Date("2099-06-01T10:00:00.000Z");

  withEnv({ TILAWA_DISTRIBUTION: "staging" }, () => {
    assert.equal(
      isWithinJoinWindow({
        startsAt,
        endsAt,
        now,
      }),
      false,
    );
    assert.equal(
      isWithinJoinWindowOrQaBypass({
        startsAt,
        endsAt,
        now,
        uid: MAESTRO_STUDENT_UID,
      }),
      true,
    );
  });
});

test("isWithinJoinWindowOrQaBypass keeps window for non-QA uid", () => {
  const startsAt = new Date("2099-06-01T12:00:00.000Z");
  const endsAt = new Date("2099-06-01T13:00:00.000Z");
  const now = new Date("2099-06-01T10:00:00.000Z");

  withEnv({ TILAWA_DISTRIBUTION: "staging" }, () => {
    assert.equal(
      isWithinJoinWindowOrQaBypass({
        startsAt,
        endsAt,
        now,
        uid: "student_not_on_allowlist",
      }),
      false,
    );
  });
});
