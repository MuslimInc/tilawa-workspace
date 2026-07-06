import test from "node:test";
import assert from "node:assert/strict";

import { resolveSessionConfigWarnings } from "../../src/quranSessions/getResolvedSessionConfig";

test("resolveSessionConfigWarnings returns no warnings for valid context", () => {
  const context = {
    marketEnabled: true,
    pricing: { isPaid: true },
    market: { paymentProviderEnabled: true, teacherWhitelist: null },
    teacher: { id: "t1", exists: true, verificationStatus: "verified" },
    student: { exists: true, accountStatus: "active" },
  };
  const warnings = resolveSessionConfigWarnings(context);
  assert.equal(warnings.length, 0);
});

test("resolveSessionConfigWarnings returns market_disabled", () => {
  const context = {
    marketEnabled: false,
    pricing: { isPaid: true },
    market: { paymentProviderEnabled: true, teacherWhitelist: null },
    teacher: { id: "t1", exists: true, verificationStatus: "verified" },
    student: { exists: true, accountStatus: "active" },
  };
  const warnings = resolveSessionConfigWarnings(context);
  assert.ok(warnings.includes("market_disabled"));
});

test("resolveSessionConfigWarnings returns paid_but_payment_disabled", () => {
  const context = {
    marketEnabled: true,
    pricing: { isPaid: true },
    market: { paymentProviderEnabled: false, teacherWhitelist: null },
    teacher: { id: "t1", exists: true, verificationStatus: "verified" },
    student: { exists: true, accountStatus: "active" },
  };
  const warnings = resolveSessionConfigWarnings(context);
  assert.ok(warnings.includes("paid_but_payment_disabled"));
});

test("resolveSessionConfigWarnings returns teacher_not_verified", () => {
  const context = {
    marketEnabled: true,
    pricing: { isPaid: true },
    market: { paymentProviderEnabled: true, teacherWhitelist: null },
    teacher: { id: "t1", exists: true, verificationStatus: "pending" },
    student: { exists: true, accountStatus: "active" },
  };
  const warnings = resolveSessionConfigWarnings(context);
  assert.ok(warnings.includes("teacher_not_verified"));
});

test("resolveSessionConfigWarnings returns teacher_not_whitelisted", () => {
  const context = {
    marketEnabled: true,
    pricing: { isPaid: true },
    market: { paymentProviderEnabled: true, teacherWhitelist: ["t2", "t3"] },
    teacher: { id: "t1", exists: true, verificationStatus: "verified" },
    student: { exists: true, accountStatus: "active" },
  };
  const warnings = resolveSessionConfigWarnings(context);
  assert.ok(warnings.includes("teacher_not_whitelisted"));
});

test("resolveSessionConfigWarnings returns student_not_active", () => {
  const context = {
    marketEnabled: true,
    pricing: { isPaid: true },
    market: { paymentProviderEnabled: true, teacherWhitelist: null },
    teacher: { id: "t1", exists: true, verificationStatus: "verified" },
    student: { exists: true, accountStatus: "deleted" },
  };
  const warnings = resolveSessionConfigWarnings(context);
  assert.ok(warnings.includes("student_not_active"));
});
