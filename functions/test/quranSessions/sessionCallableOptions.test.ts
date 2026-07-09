import test from "node:test";
import assert from "node:assert/strict";

import {
  isSessionAppCheckEnforced,
  sessionMinInstances,
} from "../../src/quranSessions/sessionCallableOptions";

function withMinInstancesEnv(value: string | undefined, run: () => void): void {
  const previous = process.env.QURAN_SESSIONS_MIN_INSTANCES;
  if (value === undefined) {
    delete process.env.QURAN_SESSIONS_MIN_INSTANCES;
  } else {
    process.env.QURAN_SESSIONS_MIN_INSTANCES = value;
  }
  try {
    run();
  } finally {
    if (previous === undefined) {
      delete process.env.QURAN_SESSIONS_MIN_INSTANCES;
    } else {
      process.env.QURAN_SESSIONS_MIN_INSTANCES = previous;
    }
  }
}

test("sessionMinInstances defaults to 0 when env unset (no cost change)", () => {
  withMinInstancesEnv(undefined, () => {
    assert.equal(sessionMinInstances(), 0);
  });
});

test("sessionMinInstances reads a positive warm-instance floor", () => {
  withMinInstancesEnv("1", () => assert.equal(sessionMinInstances(), 1));
  withMinInstancesEnv("3", () => assert.equal(sessionMinInstances(), 3));
});

test("sessionMinInstances rejects non-positive and non-numeric values", () => {
  for (const value of ["0", "-2", "abc", "", " "]) {
    withMinInstancesEnv(value, () =>
      assert.equal(
        sessionMinInstances(),
        0,
        `expected 0 for ${JSON.stringify(value)}`,
      ),
    );
  }
});

test("isSessionAppCheckEnforced defaults to false when env unset", () => {
  const previous = process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
  delete process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
  try {
    assert.equal(isSessionAppCheckEnforced(), false);
  } finally {
    if (previous === undefined) {
      delete process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
    } else {
      process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK = previous;
    }
  }
});

test("isSessionAppCheckEnforced is true only for exact true string", () => {
  const previous = process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
  process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK = "true";
  try {
    assert.equal(isSessionAppCheckEnforced(), true);
  } finally {
    if (previous === undefined) {
      delete process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
    } else {
      process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK = previous;
    }
  }
});

test("isSessionAppCheckEnforced rejects non-true values", () => {
  const previous = process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
  for (const value of ["false", "1", "TRUE", ""]) {
    process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK = value;
    assert.equal(
      isSessionAppCheckEnforced(),
      false,
      `expected false for ${JSON.stringify(value)}`,
    );
  }
  if (previous === undefined) {
    delete process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK;
  } else {
    process.env.QURAN_SESSIONS_ENFORCE_APP_CHECK = previous;
  }
});
