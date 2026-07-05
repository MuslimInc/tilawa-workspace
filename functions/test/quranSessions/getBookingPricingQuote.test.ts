import test from "node:test";
import assert from "node:assert/strict";

import { buildPricingQuote } from "../../src/quranSessions/getBookingPricingQuote";
import {
  assertBookingEligible,
  type BookingEligibilityContext,
} from "../../src/quranSessions/bookingEligibilityService";

const NOW = new Date("2024-06-01T00:00:00.000Z");

function context(overrides: {
  sessionFeeAmount?: number;
  currencyCode?: string;
}): BookingEligibilityContext {
  const fee = overrides.sessionFeeAmount ?? 0;
  const currency = overrides.currencyCode ?? "USD";
  return {
    student: {
      exists: true,
      accountStatus: "active",
      gender: "male",
      dateOfBirth: new Date("1990-01-01T00:00:00.000Z"),
      countryCode: "EG",
      cityId: "cairo",
      restrictionReason: null,
    },
    teacher: {
      exists: true,
      verificationStatus: "verified",
      gender: "male",
      allowedStudentGender: "both",
      canTeachChildren: true,
    },
    policy: {
      childAgeThreshold: 14,
      globalAllowMaleTeacherFemaleStudent: true,
      globalAllowFemaleTeacherMaleStudent: true,
    },
    market: {
      countryCode: "EG",
      cityId: "cairo",
      marketEnabled: true,
      cityEnabled: true,
      sessionFeeAmount: fee,
      currencyCode: currency,
      bookingMode: "autoConfirm",
      genderMatchingEnabled: true,
      teacherWhitelist: null,
      tutorApprovalSlaMs: 24 * 60 * 60 * 1000,
      minBookingNoticeMs: 60 * 60 * 1000,
      maxConcurrentUpcomingPerStudent: 3,
      joinWindowLeadMs: 15 * 60 * 1000,
      sessionMode: "videoOnly",
      policyVersion: fee > 0 ? "v2" : null,
      effectiveFrom: null,
    },
    marketEnabled: true,
    pricing: {
      isPaid: fee > 0,
      amount: fee,
      currencyCode: currency,
    },
  };
}

test("free market quotes a free session with no payment required", () => {
  const quote = buildPricingQuote(context({ sessionFeeAmount: 0 }), false);
  assert.equal(quote.pricingType, "free");
  assert.equal(quote.isFree, true);
  assert.equal(quote.paymentRequired, false);
  assert.equal(quote.payableAmount, 0);
});

test("paid market quotes amount, currency, and payment requirement", () => {
  const quote = buildPricingQuote(
    context({ sessionFeeAmount: 50, currencyCode: "EGP" }),
    true,
  );
  assert.equal(quote.pricingType, "fixedPerSession");
  assert.equal(quote.isFree, false);
  assert.equal(quote.amount, 50);
  assert.equal(quote.currencyCode, "EGP");
  assert.equal(quote.paymentRequired, true);
  assert.equal(quote.paymentProviderAvailable, true);
  assert.equal(quote.payableAmount, 50);
  assert.equal(quote.policyVersion, "v2");
});

test("paid market with provider disabled surfaces unavailability", () => {
  const quote = buildPricingQuote(
    context({ sessionFeeAmount: 50, currencyCode: "EGP" }),
    false,
  );
  assert.equal(quote.paymentRequired, true);
  assert.equal(quote.paymentProviderAvailable, false);
});

test("quote and booking resolve the identical price from one context", () => {
  const ctx = context({ sessionFeeAmount: 75, currencyCode: "SAR" });
  const quote = buildPricingQuote(ctx, true);
  const bookingPricing = assertBookingEligible(ctx, NOW);
  assert.equal(quote.amount, bookingPricing.amount);
  assert.equal(quote.currencyCode, bookingPricing.currencyCode);
  assert.equal(quote.isFree, !bookingPricing.isPaid);
});
