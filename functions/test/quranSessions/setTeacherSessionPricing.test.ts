import test from "node:test";
import assert from "node:assert/strict";

import { buildSessionPriceOverrideWrite } from "../../src/quranSessions/setTeacherSessionPricing";

const ADMIN = "admin_1";

test("clearing the override writes enabled:false (falls back to market)", () => {
  const patch = buildSessionPriceOverrideWrite(
    { teacherId: "t1", enabled: false },
    ADMIN,
  );
  const override = patch.sessionPriceOverride as Record<string, unknown>;
  assert.equal(override.enabled, false);
  assert.equal(override.updatedBy, ADMIN);
});

test("enabling with amount 0 marks the teacher free", () => {
  const patch = buildSessionPriceOverrideWrite(
    { teacherId: "t1", enabled: true, amount: 0 },
    ADMIN,
  );
  const override = patch.sessionPriceOverride as Record<string, unknown>;
  assert.equal(override.enabled, true);
  assert.equal(override.amount, 0);
  assert.equal(override.currencyCode, null);
});

test("enabling with a positive amount normalizes the currency code", () => {
  const patch = buildSessionPriceOverrideWrite(
    { teacherId: "t1", enabled: true, amount: 40, currencyCode: "egp" },
    ADMIN,
  );
  const override = patch.sessionPriceOverride as Record<string, unknown>;
  assert.equal(override.amount, 40);
  assert.equal(override.currencyCode, "EGP");
});

test("rejects a missing teacherId", () => {
  assert.throws(
    () =>
      buildSessionPriceOverrideWrite(
        { teacherId: "", enabled: true, amount: 0 },
        ADMIN,
      ),
    /teacherId required/,
  );
});

test("rejects a negative amount when enabled", () => {
  assert.throws(
    () =>
      buildSessionPriceOverrideWrite(
        { teacherId: "t1", enabled: true, amount: -1 },
        ADMIN,
      ),
    /amount must be a finite number/,
  );
});

test("rejects an enabled override without an amount", () => {
  assert.throws(
    () =>
      buildSessionPriceOverrideWrite(
        { teacherId: "t1", enabled: true },
        ADMIN,
      ),
    /amount must be a finite number/,
  );
});
