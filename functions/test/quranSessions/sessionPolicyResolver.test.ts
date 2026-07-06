import test from "node:test";
import assert from "node:assert/strict";

import {
  assertBookingPolicyConfigured,
  validateMarketConfigForBooking,
  validatePlatformConfig,
} from "../../src/quranSessions/sessionPolicyResolver";

test("validatePlatformConfig rejects missing required fields", () => {
  const result = validatePlatformConfig({});
  assert.equal(result.valid, false);
  assert.ok(result.missingFields.includes("quranSessionsEnabled"));
  assert.ok(result.missingFields.includes("bookingEnabled"));
  assert.ok(result.missingFields.includes("bookingMode"));
  assert.ok(result.missingFields.includes("sessionMode"));
  assert.ok(result.missingFields.includes("childAgeThreshold"));
});

test("validatePlatformConfig accepts production-shaped doc", () => {
  const result = validatePlatformConfig({
    quranSessionsEnabled: true,
    bookingEnabled: true,
    bookingMode: "autoConfirm",
    sessionMode: "videoOnly",
    childAgeThreshold: 14,
  });
  assert.equal(result.valid, true);
});

test("validatePlatformConfig accepts legacy booking mode alias", () => {
  const result = validatePlatformConfig({
    quranSessionsEnabled: true,
    bookingEnabled: true,
    quranTutorBookingMode: "autoConfirm",
    sessionMode: "videoOnly",
    childAgeThreshold: 14,
  });
  assert.equal(result.valid, true);
});

test("validateMarketConfigForBooking rejects missing fee fields", () => {
  const result = validateMarketConfigForBooking({}, null, "cairo");
  assert.equal(result.valid, false);
  assert.ok(result.missingFields.includes("minSessionPrice"));
});

test("assertBookingPolicyConfigured fails closed when market doc missing", () => {
  assert.throws(
    () =>
      assertBookingPolicyConfigured({
        platformConfig: {
          quranSessionsEnabled: true,
          bookingEnabled: true,
          bookingMode: "autoConfirm",
          sessionMode: "freeBeta",
          childAgeThreshold: 14,
        },
        countryCode: "EG",
        cityId: "cairo",
        marketDocExists: false,
      }),
    (error: unknown) =>
      (error as { details?: { code?: string } }).details?.code ===
      "policy_not_configured",
  );
});
