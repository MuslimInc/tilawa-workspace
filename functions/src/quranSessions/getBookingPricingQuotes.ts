import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

import {
  loadSharedBookingContext,
  buildTeacherBookingContext,
  type BookingEligibilityContext,
} from "./bookingEligibilityService";
import {
  buildPricingQuotesForTeachers,
  blockedQuoteForLifecycleError,
  type BookingPricingQuote,
} from "./getBookingPricingQuote";
import { isPaymentProviderEnabled } from "./payment/envGate";
import {
  requireAuthenticatedUid,
  requireValidSessionEpochUnlessAdmin,
} from "./sessionAuth";
import { sessionPricingQuoteHttpsOptions } from "./sessionCallableOptions";

/**
 * Batch pricing preview for the teacher discovery list.
 *
 * The list previously priced N teachers with N `getBookingPricingQuote` calls,
 * each re-loading the identical student + market + platform context (an N+1 that
 * scales badly for large markets). This callable resolves that shared context
 * **once** via `loadSharedBookingContext`, then varies only the per-teacher
 * lookup (teacher doc, price override, whitelist), returning a `teacherId → quote`
 * map. Each quote is byte-for-byte the same `BookingPricingQuote` the single
 * callable returns, so `BookingBlockReason` semantics are identical.
 *
 * Config-level blocks (market/policy not configured, sessions/bookings disabled)
 * are student-market-level, not teacher-level: when the shared load throws one,
 * the same typed blocked quote is applied to every requested teacher — matching
 * what the single callable returns per teacher.
 */

/** Guardrail: a single discovery page is small; cap the batch defensively. */
const MAX_TEACHER_IDS = 200;

interface GetBookingPricingQuotesRequest {
  teacherIds: string[];
}

interface GetBookingPricingQuotesResponse {
  quotes: Record<string, BookingPricingQuote>;
}

export const getBookingPricingQuotes = onCall(
  sessionPricingQuoteHttpsOptions,
  async (request): Promise<GetBookingPricingQuotesResponse> => {
    const uid = requireAuthenticatedUid(request);
    await requireValidSessionEpochUnlessAdmin(request, uid);

    const data = request.data as GetBookingPricingQuotesRequest;
    if (!Array.isArray(data.teacherIds)) {
      throw new HttpsError("invalid-argument", "teacherIds array required.");
    }
    // De-duplicate and drop empties: a page may repeat an id, and we never want
    // to read the same teacher doc twice.
    const teacherIds = [
      ...new Set(
        data.teacherIds.filter(
          (id): id is string => typeof id === "string" && id.length > 0,
        ),
      ),
    ];
    if (teacherIds.length === 0) {
      throw new HttpsError("invalid-argument", "teacherIds required.");
    }
    if (teacherIds.length > MAX_TEACHER_IDS) {
      throw new HttpsError(
        "invalid-argument",
        `teacherIds exceeds the maximum of ${MAX_TEACHER_IDS}.`,
      );
    }

    const db = getFirestore();

    // Best-effort preview (mirrors getBookingPricingQuote): config-level
    // lifecycle errors from the shared load become one typed blocked quote,
    // applied to every requested teacher. Auth/epoch/transport errors throw.
    try {
      const shared = await loadSharedBookingContext(db, uid);
      const teacherRefs = teacherIds.map((id) =>
        db.collection("quran_teacher_profiles").doc(id),
      );
      const teacherSnaps = await db.getAll(...teacherRefs);

      const contexts: Record<string, BookingEligibilityContext> = {};
      teacherSnaps.forEach((snap, index) => {
        contexts[teacherIds[index]] = buildTeacherBookingContext(shared, snap);
      });

      return {
        quotes: buildPricingQuotesForTeachers(contexts, isPaymentProviderEnabled()),
      };
    } catch (e) {
      const blocked = blockedQuoteForLifecycleError(e);
      if (blocked == null) throw e;
      const quotes: Record<string, BookingPricingQuote> = {};
      for (const teacherId of teacherIds) quotes[teacherId] = blocked;
      return { quotes };
    }
  },
);
