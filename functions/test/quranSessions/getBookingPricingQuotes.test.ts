import test from "node:test";
import assert from "node:assert/strict";

import type { DocumentSnapshot } from "firebase-admin/firestore";

import { buildPricingQuotesForTeachers } from "../../src/quranSessions/getBookingPricingQuote";
import {
  buildTeacherBookingContext,
  type BookingEligibilityContext,
  type SharedBookingContext,
} from "../../src/quranSessions/bookingEligibilityService";

function context(overrides: {
  sessionFeeAmount?: number;
  currencyCode?: string;
  marketEnabled?: boolean;
  teacherVerified?: boolean;
  teacherWhitelist?: readonly string[] | null;
  platform?: Partial<BookingEligibilityContext["platform"]>;
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
    pricing: { isPaid: fee > 0, amount: fee, currencyCode: currency },
    pricingSource: overrides.pricingSource ?? "market",
  };
}

test("batch builder prices every teacher and keys the map by teacher id", () => {
  const quotes = buildPricingQuotesForTeachers(
    {
      t1: context({ sessionFeeAmount: 0 }),
      t2: context({ sessionFeeAmount: 50, currencyCode: "EGP" }),
    },
    true,
  );

  assert.deepEqual(Object.keys(quotes).sort(), ["t1", "t2"]);
  assert.equal(quotes.t1.isFree, true);
  assert.equal(quotes.t1.blockReason, "none");
  assert.equal(quotes.t2.amount, 50);
  assert.equal(quotes.t2.currencyCode, "EGP");
  assert.equal(quotes.t2.blockReason, "none");
});

test("batch builder varies the block reason per teacher within one call", () => {
  const quotes = buildPricingQuotesForTeachers(
    {
      // Bookable paid teacher.
      bookable: context({ sessionFeeAmount: 50 }),
      // Same market, but this teacher is unverified.
      unverified: context({ sessionFeeAmount: 50, teacherVerified: false }),
      // Same market, but this teacher is not whitelisted.
      offWhitelist: context({
        sessionFeeAmount: 50,
        teacherWhitelist: ["someone_else"],
      }),
    },
    true,
  );

  assert.equal(quotes.bookable.blockReason, "none");
  assert.equal(quotes.unverified.blockReason, "teacherNotBookable");
  assert.equal(quotes.offWhitelist.blockReason, "teacherNotBookable");
});

test("batch builder applies the shared payment-provider flag uniformly", () => {
  const contexts = {
    t1: context({ sessionFeeAmount: 50 }),
    t2: context({ sessionFeeAmount: 75, currencyCode: "SAR" }),
  };

  const enabled = buildPricingQuotesForTeachers(contexts, true);
  assert.equal(enabled.t1.blockReason, "none");
  assert.equal(enabled.t2.blockReason, "none");

  const disabled = buildPricingQuotesForTeachers(contexts, false);
  // Paid teachers are unbookable while the provider is disabled — the same
  // block the single callable reports, applied to each row.
  assert.equal(disabled.t1.blockReason, "paymentProviderUnavailable");
  assert.equal(disabled.t2.blockReason, "paymentProviderUnavailable");
});

test("batch builder allows paid manual market without PSP", () => {
  const quotes = buildPricingQuotesForTeachers(
    {
      t1: context({ sessionFeeAmount: 50, manualPaymentEnabled: true }),
    },
    false,
  );

  assert.equal(quotes.t1.paymentProviderAvailable, true);
  assert.equal(quotes.t1.paymentMode, "manual_off_app");
  assert.equal(quotes.t1.blockReason, "none");
});

test("batch builder keeps free manual-market teachers bookable", () => {
  const quotes = buildPricingQuotesForTeachers(
    {
      t1: context({ sessionFeeAmount: 0, manualPaymentEnabled: true }),
      t2: context({ sessionFeeAmount: 0, manualPaymentEnabled: true }),
    },
    false,
  );

  assert.equal(quotes.t1.isFree, true);
  assert.equal(quotes.t1.blockReason, "none");
  assert.equal(quotes.t2.isFree, true);
  assert.equal(quotes.t2.blockReason, "none");
});

test("empty contexts produce an empty quote map", () => {
  assert.deepEqual(buildPricingQuotesForTeachers({}, true), {});
});

// ── buildTeacherBookingContext: shared context + per-teacher overlay ─────────

function teacherSnap(data: Record<string, unknown> | null): DocumentSnapshot {
  return {
    exists: data != null,
    data: () => data ?? undefined,
  } as unknown as DocumentSnapshot;
}

function sharedPaidMarket(): SharedBookingContext {
  const base = context({ sessionFeeAmount: 100, currencyCode: "EGP" });
  return {
    platform: base.platform,
    student: base.student,
    policy: base.policy,
    market: base.market,
    marketEnabled: base.marketEnabled,
    marketPricing: { isPaid: true, amount: 100, currencyCode: "EGP" },
  };
}

test("teacher free override wins over the shared paid market", () => {
  const shared = sharedPaidMarket();
  const ctx = buildTeacherBookingContext(
    shared,
    teacherSnap({
      verificationStatus: "verified",
      sessionPriceOverride: { enabled: true, amount: 0 },
    }),
  );

  assert.equal(ctx.pricing.isPaid, false);
  assert.equal(ctx.pricing.amount, 0);
  assert.equal(ctx.pricingSource, "teacher_override");
  // Override currency falls back to the shared market currency.
  assert.equal(ctx.pricing.currencyCode, "EGP");
});

test("teacher without an override inherits the shared market price", () => {
  const shared = sharedPaidMarket();
  const ctx = buildTeacherBookingContext(
    shared,
    teacherSnap({ verificationStatus: "verified" }),
  );

  assert.equal(ctx.pricing.isPaid, true);
  assert.equal(ctx.pricing.amount, 100);
  assert.equal(ctx.pricingSource, "market");
  // Shared slices are reused verbatim — one read, many teachers.
  assert.equal(ctx.student, shared.student);
  assert.equal(ctx.market, shared.market);
});

test("a missing teacher doc overlays as a non-existent, unverified teacher", () => {
  const shared = sharedPaidMarket();
  const ctx = buildTeacherBookingContext(shared, teacherSnap(null));

  assert.equal(ctx.teacher.exists, false);
  assert.equal(ctx.teacher.verificationStatus, "pending");
});
