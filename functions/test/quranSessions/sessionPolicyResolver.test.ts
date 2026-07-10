import test from "node:test";
import assert from "node:assert/strict";

import type { DocumentSnapshot, Firestore } from "firebase-admin/firestore";

import {
  assertBookingPolicyConfigured,
  loadEffectiveMarketPolicy,
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

function fakeSnap(
  data: Record<string, unknown> | null,
  exists = true,
): DocumentSnapshot {
  return {
    exists,
    data: () => data ?? undefined,
  } as unknown as DocumentSnapshot;
}

test("loadEffectiveMarketPolicy reuses prefetched snapshots without reading the DB", async () => {
  // Any .get() means the resolver re-read a doc the caller already fetched.
  let reads = 0;
  const db = {
    collection() {
      return {
        doc() {
          return {
            get() {
              reads += 1;
              return Promise.resolve(fakeSnap(null, false));
            },
            collection() {
              return {
                doc() {
                  return {
                    get() {
                      reads += 1;
                      return Promise.resolve(fakeSnap(null, false));
                    },
                  };
                },
              };
            },
          };
        },
      };
    },
  } as unknown as Firestore;

  const marketSnap = fakeSnap({
    isEnabled: true,
    minSessionPrice: 50,
    currencyCode: "EGP",
    // No activePolicyVersion → no policy_versions read either.
  });
  const citySnap = fakeSnap({ isEnabled: true });

  const policy = await loadEffectiveMarketPolicy(
    db,
    "EG",
    "cairo",
    { quranSessionsEnabled: true, bookingEnabled: true },
    new Date(),
    { marketSnap, citySnap },
  );

  assert.equal(reads, 0, "prefetched snapshots must not trigger any DB reads");
  assert.equal(policy.sessionFeeAmount, 50);
  assert.equal(policy.currencyCode, "EGP");
  assert.equal(policy.marketEnabled, true);
});
