import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import {
  loadBookingEligibilityContext,
  type BookingEligibilityContext,
} from "./bookingEligibilityService";
import { isMarketEnabled } from "./marketGate";
import { isPaymentProviderEnabled } from "./payment/envGate";
import {
  requireAuthenticatedUid,
  requireValidSessionEpochUnlessAdmin,
} from "./sessionAuth";
import { sessionCallableHttpsOptions } from "./sessionCallableOptions";

/**
 * Authoritative pricing preview for the booking screen.
 *
 * Resolves price from the exact same source as `createSessionBooking`
 * (`loadBookingEligibilityContext` → admin market config + teacher override +
 * policy version overlay), so the quote the student sees is the price the
 * booking records. The quote is **best-effort**: config-level blocks (admin
 * disabled bookings, pricing config missing, market disabled, teacher not
 * bookable) and the paid+payment-provider-disabled case are returned as a
 * typed `blockReason` in a *successful* response so the client can render a
 * precise, distinct message instead of inferring from loose booleans.
 *
 * `slot_unavailable` is intentionally NOT a quote reason — a slot is selected
 * after the quote, and is enforced at `createSessionBooking` time.
 *
 * `createSessionBooking` still throws typed lifecycle errors for real
 * enforcement; only the *preview* is lenient here.
 */

/** Where the effective price was resolved from (stamped on the fee snapshot). */
export type EffectivePricingSource =
  | "teacherOverride"
  | "marketConfig"
  | "platformFallback";

/** Typed reason the booking screen must block submission. */
export type BookingBlockReason =
  | "none"
  | "paymentProviderUnavailable"
  | "bookingDisabledByAdmin"
  | "pricingConfigMissing"
  | "teacherNotBookable"
  | "marketDisabled";

export interface BookingPricingQuote {
  pricingType: "free" | "fixedPerSession";
  isFree: boolean;
  amount: number;
  currencyCode: string;
  /** True when the student must pay to confirm this booking. */
  paymentRequired: boolean;
  /** False while the Paid-v1 gate keeps the payment provider disabled. */
  paymentProviderAvailable: boolean;
  manualPaymentEnabled: boolean;
  paymentMode: "none" | "manual_off_app" | "sandbox";
  /** Amount the student pays now (v1: equals `amount`; 0 when free). */
  payableAmount: number;
  countryCode: string | null;
  cityId: string | null;
  policyVersion: string | null;
  /** Platform + market feature flags (from the resolved context). */
  bookingEnabled: boolean;
  quranSessionsEnabled: boolean;
  /** Provenance of `amount` — matches the `feeSnapshot.pricingSource`. */
  effectivePricingSource: EffectivePricingSource;
  /** Typed booking-block reason; `none` when the session is bookable. */
  blockReason: BookingBlockReason;
}

function mapPricingSource(
  source: BookingEligibilityContext["pricingSource"],
): EffectivePricingSource {
  return source === "teacher_override"
    ? "teacherOverride"
    : source === "market"
      ? "marketConfig"
      : "platformFallback";
}

/** Pure quote assembly — unit-tested; shares `ctx.pricing` with booking. */
export function buildPricingQuote(
  ctx: BookingEligibilityContext,
  paymentProviderEnabled: boolean,
  options?: { teacherId?: string },
): BookingPricingQuote {
  const { pricing } = ctx;
  const isFree = !pricing.isPaid;
  const paymentProviderAvailable =
    paymentProviderEnabled || ctx.market.manualPaymentEnabled;
  const blockReason = resolveBlockReasonWithTeacher(
    ctx,
    paymentProviderAvailable,
    options?.teacherId,
  );
  return {
    pricingType: isFree ? "free" : "fixedPerSession",
    isFree,
    amount: pricing.amount,
    currencyCode: pricing.currencyCode,
    paymentRequired: !isFree,
    paymentProviderAvailable,
    manualPaymentEnabled: ctx.market.manualPaymentEnabled,
    paymentMode: isFree
      ? "none"
      : ctx.market.manualPaymentEnabled && !paymentProviderEnabled
        ? "manual_off_app"
        : "sandbox",
    payableAmount: isFree ? 0 : pricing.amount,
    countryCode: ctx.student.countryCode,
    cityId: ctx.student.cityId,
    policyVersion: ctx.market.policyVersion,
    bookingEnabled: ctx.platform.bookingEnabled,
    quranSessionsEnabled: ctx.platform.quranSessionsEnabled,
    effectivePricingSource: mapPricingSource(ctx.pricingSource),
    blockReason,
  };
}

/** Quote for the config-missing path: pricing cannot be resolved. */
export function buildBlockedPricingQuote(
  blockReason: Exclude<BookingBlockReason, "none" | "paymentProviderUnavailable">,
  platform: {
    bookingEnabled: boolean;
    quranSessionsEnabled: boolean;
  },
  countryCode: string | null = null,
  cityId: string | null = null,
): BookingPricingQuote {
  return {
    pricingType: "free",
    isFree: true,
    amount: 0,
    currencyCode: "USD",
    paymentRequired: false,
    paymentProviderAvailable: false,
    manualPaymentEnabled: false,
    paymentMode: "none",
    payableAmount: 0,
    countryCode,
    cityId,
    policyVersion: null,
    bookingEnabled: platform.bookingEnabled,
    quranSessionsEnabled: platform.quranSessionsEnabled,
    // Pricing could not be resolved; report the fallback rather than guessing.
    effectivePricingSource: "platformFallback",
    blockReason,
  };
}

function resolveBlockReasonWithTeacher(
  ctx: BookingEligibilityContext,
  paymentProviderEnabled: boolean,
  teacherId?: string,
): BookingBlockReason {
  if (!ctx.platform.quranSessionsEnabled || !ctx.platform.bookingEnabled) {
    return "bookingDisabledByAdmin";
  }
  if (!ctx.marketEnabled || !ctx.market.marketEnabled) {
    return "marketDisabled";
  }
  if (!isMarketEnabled(ctx.platform.marketGate, ctx.student.countryCode)) {
    return "marketDisabled";
  }
  if (
    !ctx.teacher.exists ||
    ctx.teacher.verificationStatus !== "verified"
  ) {
    return "teacherNotBookable";
  }
  if (
    teacherId != null &&
    ctx.market.teacherWhitelist != null &&
    !ctx.market.teacherWhitelist.includes(teacherId)
  ) {
    return "teacherNotBookable";
  }
  if (ctx.pricing.isPaid && !paymentProviderEnabled) {
    return "paymentProviderUnavailable";
  }
  // Manual payment mode only affects paid bookings. Free sessions stay
  // bookable and should remain visible in discovery.
  return "none";
}

/**
 * Pure batch assembly: prices every teacher against its own resolved context
 * while sharing one `paymentProviderEnabled` flag. Unit-tested — the callable
 * only wires the shared-context load + per-teacher reads around this.
 */
export function buildPricingQuotesForTeachers(
  contexts: Record<string, BookingEligibilityContext>,
  paymentProviderEnabled: boolean,
): Record<string, BookingPricingQuote> {
  const quotes: Record<string, BookingPricingQuote> = {};
  for (const [teacherId, ctx] of Object.entries(contexts)) {
    quotes[teacherId] = buildPricingQuote(ctx, paymentProviderEnabled, {
      teacherId,
    });
  }
  return quotes;
}

interface GetBookingPricingQuoteRequest {
  teacherId: string;
}

function lifecycleErrorCode(e: unknown): string | null {
  if (e instanceof HttpsError) {
    const details = e.details as { code?: unknown } | undefined;
    return typeof details?.code === "string" ? details.code : null;
  }
  return null;
}

function readPlatformFlags(e: unknown): {
  bookingEnabled: boolean;
  quranSessionsEnabled: boolean;
} {
  // Best-effort: config-missing throws carry no platform flags, so fail open to
  // `true` — the blockReason itself signals the block, not these flags.
  return { bookingEnabled: true, quranSessionsEnabled: true };
}

/**
 * Maps a config-level lifecycle error to the typed blocked quote the client
 * should render, or null when the error is not a config-level block and must
 * propagate (auth/epoch/transport). Shared by the single and batch callables so
 * both surface identical `BookingBlockReason` semantics.
 */
export function blockedQuoteForLifecycleError(
  e: unknown,
): BookingPricingQuote | null {
  const code = lifecycleErrorCode(e);
  if (code === "policy_not_configured") {
    return buildBlockedPricingQuote("pricingConfigMissing", readPlatformFlags(e));
  }
  if (code === "feature_disabled") {
    // Platform disabled sessions or bookings — report as admin block.
    const platform = readPlatformFlags(e);
    return buildBlockedPricingQuote("bookingDisabledByAdmin", {
      bookingEnabled: false,
      quranSessionsEnabled: platform.quranSessionsEnabled,
    });
  }
  if (code === "market_not_enabled" || code === "market_not_supported") {
    return buildBlockedPricingQuote("marketDisabled", readPlatformFlags(e));
  }
  if (code === "teacher_not_whitelisted" || code === "teacher_not_verified") {
    return buildBlockedPricingQuote("teacherNotBookable", readPlatformFlags(e));
  }
  return null;
}

export const getBookingPricingQuote = onCall(
  sessionCallableHttpsOptions,
  async (request) => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);
    const data = request.data as GetBookingPricingQuoteRequest;
    if (!data.teacherId) {
      throw new HttpsError("invalid-argument", "teacherId required.");
    }

    const db = getFirestore();
    const teacherId = data.teacherId;

    // Best-effort preview: convert config-level lifecycle errors into a typed
    // blockReason inside a successful response. Auth/epoch/transport errors
    // still throw (handled by the client failure mapper).
    const startedAt = Date.now();
    try {
      const ctx = await loadBookingEligibilityContext(db, uid, teacherId);
      const contextLoadedAt = Date.now();
      const quote = buildPricingQuote(ctx, isPaymentProviderEnabled(), {
        teacherId,
      });
      logger.info("getBookingPricingQuote timing", {
        teacherId,
        contextLoadMs: contextLoadedAt - startedAt,
        totalMs: Date.now() - startedAt,
        blockReason: quote.blockReason,
      });
      return quote;
    } catch (e) {
      const blocked = blockedQuoteForLifecycleError(e);
      logger.info("getBookingPricingQuote timing", {
        teacherId,
        totalMs: Date.now() - startedAt,
        outcome: blocked != null ? "blocked" : "error",
        blockReason: blocked?.blockReason,
      });
      if (blocked != null) return blocked;
      throw e;
    }
  },
);