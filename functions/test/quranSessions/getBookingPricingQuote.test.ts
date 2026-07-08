import test from "node:test";
import assert from "node:assert/strict";

import {
  buildPricingQuote,
  buildBlockedPricingQuote,
} from "../../src/quranSessions/getBookingPricingQuote";
import {
  assertBookingEligible,
  resolvePricingWithOverride,
  type BookingEligibilityContext,
} from "../../src/quranSessions/bookingEligibilityService";

const NOW = new Date("2024-06-01T00:00:00.000Z");

function context(overrides: {
  sessionFeeAmount?: number;
  currencyCode?: string;
  platform?: Partial<BookingEligibilityContext["platform"]>;
  marketEnabled?: boolean;
  teacherVerified?: boolean;
  teacherWhitelist?: readonly string[] | null;
  manualPaymentEnabled?: boolean;
  pricingSource?: BookingEligibilityContext["pricingSource"];
}): BookingEligibilityContext {
  const fee = overrides.sessionFeeAmount ?? 0;
  const currency = overrides.currencyCode ?? "USD";
  const verified = overrides.teacherVerified ?? true;
  return {
    platform: {
      quranSessionsEnabled: overrides.platform?.quranSessionsEnabled ?? true,
      studentEntryEnabled: overrides.platform?.studentEntryEnabled ?? true,
      bookingEnabled: overrides.platform?.bookingEnabled ?? true,
      marketGate: overrides.platform?.marketGate ?? {
        enableForAllMarkets: false,
        enabledMarketCodes: ["EG"],
      },
    },
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
      verificationStatus: verified ? "verified" : "pending",
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
      marketEnabled: overrides.marketEnabled ?? true,
      cityEnabled: true,
      sessionFeeAmount: fee,
      currencyCode: currency,
      bookingMode: "autoConfirm",
      genderMatchingEnabled: true,
      teacherWhitelist: overrides.teacherWhitelist ?? null,
      paymentProviderEnabled: true,
      manualPaymentEnabled: overrides.manualPaymentEnabled ?? false,
      tutorApprovalSlaMs: 24 * 60 * 60 * 1000,
      minBookingNoticeMs: 60 * 60 * 1000,
      maxConcurrentUpcomingPerStudent: 3,
      joinWindowLeadMs: 15 * 60 * 1000,
      sessionMode: "videoOnly",
      policyVersion: fee > 0 ? "v2" : null,
      effectiveFrom: null,
    },
    marketEnabled: overrides.marketEnabled ?? true,
    pricing: {
      isPaid: fee > 0,
      amount: fee,
      currencyCode: currency,
    },
    pricingSource: overrides.pricingSource ?? "market",
  };
}

test("free market quotes a free session with no payment required and no block", () => {
  const quote = buildPricingQuote(context({ sessionFeeAmount: 0 }), false);
  assert.equal(quote.pricingType, "free");
  assert.equal(quote.isFree, true);
  assert.equal(quote.paymentRequired, false);
  assert.equal(quote.payableAmount, 0);
  assert.equal(quote.blockReason, "none");
  assert.equal(quote.effectivePricingSource, "marketConfig");
  assert.equal(quote.bookingEnabled, true);
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
  assert.equal(quote.manualPaymentEnabled, false);
  assert.equal(quote.paymentMode, "sandbox");
  assert.equal(quote.payableAmount, 50);
  assert.equal(quote.policyVersion, "v2");
  assert.equal(quote.blockReason, "none");
});

test("paid market with provider disabled returns paymentProviderUnavailable block reason", () => {
  const quote = buildPricingQuote(
    context({ sessionFeeAmount: 50, currencyCode: "EGP" }),
    false,
  );
  assert.equal(quote.paymentRequired, true);
  assert.equal(quote.paymentProviderAvailable, false);
  assert.equal(quote.blockReason, "paymentProviderUnavailable");
});

test("paid manual market is available without PSP and reports manual mode", () => {
  const quote = buildPricingQuote(
    context({
      sessionFeeAmount: 50,
      currencyCode: "EGP",
      manualPaymentEnabled: true,
    }),
    false,
  );
  assert.equal(quote.paymentRequired, true);
  assert.equal(quote.paymentProviderAvailable, true);
  assert.equal(quote.manualPaymentEnabled, true);
  assert.equal(quote.paymentMode, "manual_off_app");
  assert.equal(quote.blockReason, "none");
});

test("free teacher with provider disabled is still bookable (blockReason none)", () => {
  const ctx = context({ sessionFeeAmount: 0 });
  const quote = buildPricingQuote(ctx, false);
  assert.equal(quote.isFree, true);
  assert.equal(quote.paymentRequired, false);
  assert.equal(quote.blockReason, "none");
});

test("quote and booking resolve the identical price from one context", () => {
  const ctx = context({ sessionFeeAmount: 75, currencyCode: "SAR" });
  const quote = buildPricingQuote(ctx, true);
  const bookingPricing = assertBookingEligible(ctx, NOW);
  assert.equal(quote.amount, bookingPricing.amount);
  assert.equal(quote.currencyCode, bookingPricing.currencyCode);
  assert.equal(quote.isFree, !bookingPricing.isPaid);
});

test("a teacher override of 0 produces a free quote even in a paid market", () => {
  // Market prices 100 EGP, but the admin set this teacher free: resolution
  // (resolvePricingWithOverride) runs before buildPricingQuote, so the quote
  // the student sees is free — matching what the booking will record.
  const ctx = context({
    sessionFeeAmount: 100,
    currencyCode: "EGP",
    pricingSource: "teacher_override",
  });
  const resolved = resolvePricingWithOverride(ctx.pricing, {
    amount: 0,
    currencyCode: null,
  });
  const overriddenCtx = {
    ...ctx,
    pricing: resolved.pricing,
    pricingSource: resolved.source,
  };
  const quote = buildPricingQuote(overriddenCtx, false, { teacherId: "t1" });
  assert.equal(quote.isFree, true);
  assert.equal(quote.pricingType, "free");
  assert.equal(quote.paymentRequired, false);
  // A free session is bookable regardless of payment provider availability.
  assert.equal(quote.payableAmount, 0);
  assert.equal(quote.blockReason, "none");
  assert.equal(quote.effectivePricingSource, "teacherOverride");
});

test("teacher free override wins over a paid market (resolution order)", () => {
  const base = context({ sessionFeeAmount: 100, currencyCode: "EGP" });
  const withOverride = resolvePricingWithOverride(base.pricing, {
    amount: 0,
    currencyCode: "EGP",
  });
  assert.equal(withOverride.source, "teacher_override");
  assert.equal(withOverride.pricing.isPaid, false);
  assert.equal(withOverride.pricing.amount, 0);

  const quote = buildPricingQuote(
    { ...base, pricing: withOverride.pricing, pricingSource: withOverride.source },
    false,
    { teacherId: "t1" },
  );
  assert.equal(quote.isFree, true);
  assert.equal(quote.blockReason, "none");
  assert.equal(quote.effectivePricingSource, "teacherOverride");
});

test("market price applies when no teacher override exists", () => {
  const ctx = context({ sessionFeeAmount: 11, currencyCode: "EGP" });
  const quote = buildPricingQuote(ctx, true, { teacherId: "t1" });
  assert.equal(quote.amount, 11);
  assert.equal(quote.currencyCode, "EGP");
  assert.equal(quote.effectivePricingSource, "marketConfig");
  assert.equal(quote.blockReason, "none");
});

test("admin disables booking → blockReason bookingDisabledByAdmin", () => {
  const ctx = context({
    sessionFeeAmount: 50,
    platform: { bookingEnabled: false },
  });
  const quote = buildPricingQuote(ctx, true, { teacherId: "t1" });
  assert.equal(quote.blockReason, "bookingDisabledByAdmin");
  assert.equal(quote.bookingEnabled, false);
  assert.equal(quote.quranSessionsEnabled, true);
});

test("quran sessions feature off → blockReason bookingDisabledByAdmin", () => {
  const ctx = context({
    platform: { quranSessionsEnabled: false, bookingEnabled: true },
  });
  const quote = buildPricingQuote(ctx, true, { teacherId: "t1" });
  assert.equal(quote.blockReason, "bookingDisabledByAdmin");
  assert.equal(quote.quranSessionsEnabled, false);
});

test("market disabled → blockReason marketDisabled", () => {
  const ctx = context({ marketEnabled: false, sessionFeeAmount: 50 });
  const quote = buildPricingQuote(ctx, true, { teacherId: "t1" });
  assert.equal(quote.blockReason, "marketDisabled");
});

test("teacher not verified → blockReason teacherNotBookable", () => {
  const ctx = context({ teacherVerified: false, sessionFeeAmount: 50 });
  const quote = buildPricingQuote(ctx, true, { teacherId: "t1" });
  assert.equal(quote.blockReason, "teacherNotBookable");
});

test("teacher not in market whitelist → blockReason teacherNotBookable", () => {
  const ctx = context({
    sessionFeeAmount: 50,
    teacherWhitelist: ["other_teacher"],
  });
  const quote = buildPricingQuote(ctx, true, { teacherId: "t1" });
  assert.equal(quote.blockReason, "teacherNotBookable");
});

test("buildBlockedPricingQuote surfaces pricingConfigMissing with zeroed price", () => {
  const quote = buildBlockedPricingQuote(
    "pricingConfigMissing",
    { bookingEnabled: true, quranSessionsEnabled: true },
    "EG",
    "cairo",
  );
  assert.equal(quote.blockReason, "pricingConfigMissing");
  assert.equal(quote.amount, 0);
  assert.equal(quote.isFree, true);
  assert.equal(quote.paymentRequired, false);
  assert.equal(quote.effectivePricingSource, "platformFallback");
  assert.equal(quote.countryCode, "EG");
  assert.equal(quote.cityId, "cairo");
});

test("buildBlockedPricingQuote surfaces bookingDisabledByAdmin from feature_disabled", () => {
  const quote = buildBlockedPricingQuote(
    "bookingDisabledByAdmin",
    { bookingEnabled: false, quranSessionsEnabled: true },
  );
  assert.equal(quote.blockReason, "bookingDisabledByAdmin");
  assert.equal(quote.bookingEnabled, false);
  assert.equal(quote.quranSessionsEnabled, true);
});