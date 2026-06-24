import test from "node:test";
import assert from "node:assert/strict";

import { isSessionAppCheckEnforced } from "../../src/quranSessions/sessionCallableOptions";

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
