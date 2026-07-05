import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  loadBookingEligibilityContext,
  type BookingEligibilityContext,
} from "./bookingEligibilityService";
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
 * (`loadBookingEligibilityContext` → admin market config + policy version
 * overlay), so the quote the student sees is the price the booking records.
 * Also exposes whether the payment provider is enabled, letting the client
 * block paid bookings *before* submit instead of surfacing
 * `payment_provider_unavailable` after the fact.
 */

export interface BookingPricingQuote {
  pricingType: "free" | "fixedPerSession";
  isFree: boolean;
  amount: number;
  currencyCode: string;
  /** True when the student must pay to confirm this booking. */
  paymentRequired: boolean;
  /** False while the Paid-v1 gate keeps the payment provider disabled. */
  paymentProviderAvailable: boolean;
  /** Amount the student pays now (v1: equals `amount`; 0 when free). */
  payableAmount: number;
  countryCode: string | null;
  cityId: string | null;
  policyVersion: string | null;
}

/** Pure quote assembly — unit-tested; shares `ctx.pricing` with booking. */
export function buildPricingQuote(
  ctx: BookingEligibilityContext,
  paymentProviderEnabled: boolean,
): BookingPricingQuote {
  const { pricing } = ctx;
  const isFree = !pricing.isPaid;
  return {
    pricingType: isFree ? "free" : "fixedPerSession",
    isFree,
    amount: pricing.amount,
    currencyCode: pricing.currencyCode,
    paymentRequired: !isFree,
    paymentProviderAvailable: paymentProviderEnabled,
    payableAmount: isFree ? 0 : pricing.amount,
    countryCode: ctx.student.countryCode,
    cityId: ctx.student.cityId,
    policyVersion: ctx.market.policyVersion,
  };
}

interface GetBookingPricingQuoteRequest {
  teacherId: string;
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
    // Throws the same typed lifecycle errors as createSessionBooking when the
    // student profile or market policy is incomplete — the client already
    // maps those codes to localized copy.
    const ctx = await loadBookingEligibilityContext(db, uid, data.teacherId);
    return buildPricingQuote(ctx, isPaymentProviderEnabled());
  },
);
