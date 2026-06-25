import test from "node:test";
import assert from "node:assert/strict";
import { HttpsError } from "firebase-functions/v2/https";

import { assertAllowedSessionDuration } from "../../src/quranSessions/createAdminTestQuranSession";

const BASE = "2026-06-25T13:00:00.000Z";

function iso(offsetMinutes: number): string {
  return new Date(Date.parse(BASE) + offsetMinutes * 60000).toISOString();
}

test("assertAllowedSessionDuration accepts 15/30/45/60 min", () => {
  for (const mins of [15, 30, 45, 60]) {
    assert.doesNotThrow(() =>
      assertAllowedSessionDuration(iso(0), iso(mins)),
    );
  }
});

test("assertAllowedSessionDuration rejects a 12h session", () => {
  assert.throws(
    () => assertAllowedSessionDuration(iso(0), iso(720)),
    (err: unknown) => {
      assert.ok(err instanceof HttpsError, "expected HttpsError");
      assert.equal((err as HttpsError).code, "invalid-argument");
      return true;
    },
  );
});

test("assertAllowedSessionDuration rejects unsupported durations", () => {
  for (const mins of [10, 20, 90, 120]) {
    assert.throws(
      () => assertAllowedSessionDuration(iso(0), iso(mins)),
      (err: unknown) => {
        assert.ok(err instanceof HttpsError, "expected HttpsError");
        assert.equal((err as HttpsError).code, "invalid-argument");
        return true;
      },
    );
  }
});

test("assertAllowedSessionDuration rejects non-positive duration", () => {
  assert.throws(
    () => assertAllowedSessionDuration(iso(0), iso(0)),
    (err: unknown) => {
      assert.ok(err instanceof HttpsError, "expected HttpsError");
      return true;
    },
  );
  assert.throws(
    () => assertAllowedSessionDuration(iso(30), iso(0)),
    (err: unknown) => {
      assert.ok(err instanceof HttpsError, "expected HttpsError");
      return true;
    },
  );
});

test("assertAllowedSessionDuration rejects invalid timestamps", () => {
  assert.throws(
    () => assertAllowedSessionDuration("not-a-date", iso(30)),
    (err: unknown) => {
      assert.ok(err instanceof HttpsError, "expected HttpsError");
      return true;
    },
  );
});
